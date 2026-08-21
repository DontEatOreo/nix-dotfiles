import AppKit
import Darwin
import Foundation
import ImageIO
import Network
import ScreenCaptureKit
import Vision

private let applicationName = "fido-phone"
private let protocolMagic = Data("FIDOPHN1".utf8)
private let maximumURIBytes = 2_048

private enum ExitCode: Int32 {
  case usage = 2
  case unavailable = 3
  case invalidQR = 4
}

private struct BridgeError: Error, CustomStringConvertible {
  let description: String
  let exitCode: ExitCode

  static func usage(_ description: String) -> BridgeError {
    BridgeError(description: description, exitCode: .usage)
  }

  static func unavailable(_ description: String) -> BridgeError {
    BridgeError(description: description, exitCode: .unavailable)
  }

  static func invalidQR(_ description: String) -> BridgeError {
    BridgeError(description: description, exitCode: .invalidQR)
  }
}

private struct Options {
  let host: NWEndpoint.Host
  let port: NWEndpoint.Port
  let tokenURL: URL
  let imageURL: URL?
  let selectInteractively: Bool
  let decodeOnly: Bool
  let notify: Bool

  static func parse(_ arguments: ArraySlice<String>) throws -> Options {
    let environment = ProcessInfo.processInfo.environment
    var host = environment["FIDO_PHONE_HOST"]
    var tokenPath = environment["FIDO_PHONE_TOKEN_FILE"]
    var port: NWEndpoint.Port = 48_124
    var imagePath: String?
    var selectInteractively = false
    var decodeOnly = false
    var notify = true
    var iterator = arguments.makeIterator()

    func nextValue(after argument: String) throws -> String {
      guard let value = iterator.next() else {
        throw BridgeError.usage("missing value after \(argument)")
      }
      return value
    }

    while let argument = iterator.next() {
      switch argument {
      case "--host":
        host = try nextValue(after: argument)
      case "--port":
        let value = try nextValue(after: argument)
        guard let numericPort = UInt16(value),
          numericPort > 0,
          let networkPort = NWEndpoint.Port(rawValue: numericPort)
        else {
          throw BridgeError.usage("invalid port: \(value)")
        }
        port = networkPort
      case "--token-file":
        tokenPath = try nextValue(after: argument)
      case "--image":
        imagePath = try nextValue(after: argument)
      case "--select":
        selectInteractively = true
      case "--decode-only":
        decodeOnly = true
      case "--no-notify":
        notify = false
      case "--help", "-h":
        printUsage()
        Darwin.exit(0)
      default:
        throw BridgeError.usage("unknown argument: \(argument)")
      }
    }

    guard let host, !host.isEmpty else {
      throw BridgeError.unavailable("FIDO_PHONE_HOST is not set")
    }
    guard let tokenPath, !tokenPath.isEmpty else {
      throw BridgeError.unavailable("FIDO_PHONE_TOKEN_FILE is not set")
    }
    return Options(
      host: NWEndpoint.Host(host),
      port: port,
      tokenURL: URL(filePath: tokenPath),
      imageURL: imagePath.map { URL(filePath: $0) },
      selectInteractively: selectInteractively,
      decodeOnly: decodeOnly,
      notify: notify
    )
  }
}

private func printUsage() {
  print(
    """
    Usage: fido-phone [OPTIONS]

    Find a FIDO hybrid-authentication QR code on screen and send it to the
    authenticated FIDO Phone receiver on Android over Tailscale.

      --host ADDRESS     Android Tailscale IPv4 address (default: FIDO_PHONE_HOST)
      --port PORT        Android receiver port (default: 48124)
      --token-file FILE  shared-token file (default: FIDO_PHONE_TOKEN_FILE)
      --image FILE       decode an existing image instead of capturing displays
      --select           select a screen area instead of capturing all displays
      --decode-only      print the decoded URI and do not contact Android
      --no-notify        do not show macOS notifications
    """)
}

private func isFIDOHybridURI(_ value: String) -> Bool {
  let prefix = "FIDO:/".utf8
  let bytes = Array(value.utf8)
  return bytes.count >= prefix.count + 32 && bytes.count <= maximumURIBytes
    && bytes.starts(with: prefix)
    && bytes.dropFirst(prefix.count).allSatisfy { (48...57).contains($0) }
}

private func loadImage(at url: URL) throws -> CGImage {
  guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
  else {
    throw BridgeError.unavailable(
      "could not read image: \(url.path(percentEncoded: false))"
    )
  }
  return image
}

private func captureSelection() throws -> CGImage {
  let directory = URL.temporaryDirectory.appending(
    path: "fido-phone-\(UUID().uuidString)",
    directoryHint: .isDirectory
  )
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
  defer { try? FileManager.default.removeItem(at: directory) }

  let imageURL = directory.appending(path: "capture.png", directoryHint: .notDirectory)
  let capture = Process()
  capture.executableURL = URL(filePath: "/usr/sbin/screencapture")
  capture.arguments = ["-i", "-x", "-t", "png", imageURL.path(percentEncoded: false)]
  try capture.run()
  capture.waitUntilExit()
  guard capture.terminationStatus == 0 else {
    throw BridgeError.unavailable("screen selection cancelled")
  }
  return try loadImage(at: imageURL)
}

private func captureDisplays() async throws -> [CGImage] {
  do {
    let content = try await SCShareableContent.excludingDesktopWindows(
      false,
      onScreenWindowsOnly: true
    )
    guard !content.displays.isEmpty else {
      throw BridgeError.unavailable("no displays are available")
    }
    var images: [CGImage] = []
    for display in content.displays {
      let configuration = SCStreamConfiguration()
      configuration.width = display.width
      configuration.height = display.height
      configuration.showsCursor = false
      images.append(
        try await SCScreenshotManager.captureImage(
          contentFilter: SCContentFilter(display: display, excludingWindows: []),
          configuration: configuration
        )
      )
    }
    return images
  } catch let error as BridgeError {
    throw error
  } catch {
    throw BridgeError.unavailable(
      "could not capture displays; allow Screen & System Audio Recording: \(error.localizedDescription)"
    )
  }
}

private func decodeFIDOQRCode(in images: [CGImage]) throws -> String {
  let request = VNDetectBarcodesRequest()
  request.symbologies = [.qr]
  var matches = Set<String>()
  for image in images {
    try VNImageRequestHandler(cgImage: image).perform([request])
    matches.formUnion(
      (request.results ?? []).compactMap(\.payloadStringValue).filter(isFIDOHybridURI)
    )
  }
  guard matches.count == 1, let value = matches.first else {
    if matches.isEmpty {
      throw BridgeError.invalidQR("capture does not contain a FIDO QR code")
    }
    throw BridgeError.invalidQR("capture contains more than one FIDO QR code")
  }
  return value
}

private func notify(title: String, message: String) {
  let process = Process()
  process.executableURL = URL(filePath: "/usr/bin/osascript")
  process.arguments = [
    "-e", "on run argv",
    "-e", "display notification (item 2 of argv) with title (item 1 of argv)",
    "-e", "end run",
    "--", title, message,
  ]
  try? process.run()
}

private func readToken(at url: URL) throws -> Data {
  let encoded: String
  do {
    encoded = try String(contentsOf: url, encoding: .utf8)
      .trimmingCharacters(in: .whitespacesAndNewlines)
  } catch {
    throw BridgeError.unavailable(
      "could not read shared token: \(url.path(percentEncoded: false))"
    )
  }
  guard let token = Data(base64Encoded: encoded), token.count == 32 else {
    throw BridgeError.unavailable("shared token must contain 32 base64-encoded bytes")
  }
  return token
}

private func makeRequest(uri: String, token: Data) throws -> Data {
  let uriData = Data(uri.utf8)
  guard uriData.count <= maximumURIBytes else {
    throw BridgeError.invalidQR("FIDO URI is too long")
  }

  var request = protocolMagic
  request.append(token)
  let uriLength = UInt16(uriData.count)
  withUnsafeBytes(of: uriLength.bigEndian) { request.append(contentsOf: $0) }
  request.append(uriData)
  return request
}

private enum ResponseStatus: UInt8 {
  case ok = 0
  case unauthorized = 1
  case invalidRequest = 2
  case permissionRequired = 3
  case noHandler = 4

  func check() throws {
    switch self {
    case .ok:
      return
    case .unauthorized:
      throw BridgeError.unavailable("Android rejected the sender or shared token")
    case .invalidRequest:
      throw BridgeError.unavailable("Android rejected the FIDO request")
    case .permissionRequired:
      throw BridgeError.unavailable("enable Display over other apps for FIDO Phone")
    case .noHandler:
      throw BridgeError.unavailable("Android could not open a handler for the FIDO URI")
    }
  }
}

private final class ExchangeState: @unchecked Sendable {
  let lock = NSLock()
  var completed = false
}

private func exchange(_ request: Data, with endpoint: NWEndpoint) async throws -> UInt8 {
  let parameters = NWParameters.tcp
  if let tcp = parameters.defaultProtocolStack.transportProtocol as? NWProtocolTCP.Options {
    tcp.noDelay = true
    tcp.connectionTimeout = 10
  }
  let connection = NWConnection(to: endpoint, using: parameters)

  return try await withCheckedThrowingContinuation { continuation in
    let state = ExchangeState()

    @Sendable func finish(_ result: Result<UInt8, Error>) {
      state.lock.lock()
      defer { state.lock.unlock() }
      guard !state.completed else { return }
      state.completed = true
      connection.cancel()
      continuation.resume(with: result)
    }

    connection.stateUpdateHandler = { state in
      switch state {
      case .ready:
        connection.send(
          content: request,
          contentContext: .finalMessage,
          isComplete: true,
          completion: .contentProcessed { error in
            if let error {
              finish(.failure(error))
              return
            }
            connection.receive(minimumIncompleteLength: 1, maximumLength: 1) {
              content, _, _, error in
              if let error {
                finish(.failure(error))
              } else if let status = content?.first {
                finish(.success(status))
              } else {
                finish(.failure(BridgeError.unavailable(
                  "Android closed the connection without a response"
                )))
              }
            }
          }
        )
      case .failed(let error):
        finish(.failure(error))
      case .cancelled:
        finish(.failure(BridgeError.unavailable("connection was cancelled")))
      default:
        break
      }
    }
    connection.start(queue: DispatchQueue(label: "dev.evy.fido-phone.network"))
  }
}

private func sendToPhone(uri: String, options: Options) async throws {
  let token = try readToken(at: options.tokenURL)
  let request = try makeRequest(uri: uri, token: token)
  let endpoint = NWEndpoint.hostPort(host: options.host, port: options.port)

  do {
    let response = try await exchange(request, with: endpoint)
    guard let status = ResponseStatus(rawValue: response) else {
      throw BridgeError.unavailable("Android returned an unknown status")
    }
    try status.check()
  } catch let error as BridgeError {
    throw error
  } catch {
    throw BridgeError.unavailable(
      "could not reach Android over Tailscale: \(error.localizedDescription)")
  }
}

private func run() async throws {
  let options = try Options.parse(CommandLine.arguments.dropFirst())
  let images: [CGImage]
  if let imageURL = options.imageURL {
    images = [try loadImage(at: imageURL)]
  } else if options.selectInteractively {
    images = [try captureSelection()]
  } else {
    images = try await captureDisplays()
  }

  let uri = try decodeFIDOQRCode(in: images)
  if options.decodeOnly {
    print(uri)
    return
  }

  try await sendToPhone(uri: uri, options: options)
  if options.notify {
    notify(title: "Passkey sent", message: "Continue in 1Password on your Android phone")
  }
}

@main
private enum FidoPhone {
  static func main() async {
    do {
      try await run()
    } catch let error as BridgeError {
      FileHandle.standardError.write(Data("\(applicationName): \(error.description)\n".utf8))
      notify(title: "Passkey failed", message: error.description)
      Darwin.exit(error.exitCode.rawValue)
    } catch {
      FileHandle.standardError.write(Data("\(applicationName): \(error)\n".utf8))
      notify(title: "Passkey failed", message: error.localizedDescription)
      Darwin.exit(1)
    }
  }
}
