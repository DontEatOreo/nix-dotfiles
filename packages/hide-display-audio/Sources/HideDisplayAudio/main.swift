import CoreFoundation
import EDIDKit
import Foundation
import IOKit
import PrivateIOKit

private let target = (
  name: "AOC 24G2W1G5",
  identity: EDID.Identity(
    manufacturerID: 0x05e3,
    productCode: 0x2402,
    serialNumber: 0x0000_347a
  ),
  backup: "24G2W1G5-factory.edid"
)

private enum Command {
  case on, off, inspect

  private static let aliases: [String: Self] = [
    "on": .on, "apply": .on,
    "off": .off, "reset": .off,
    "inspect": .inspect,
  ]

  init?(_ argument: String) {
    guard let command = Self.aliases[argument] else { return nil }
    self = command
  }
}

private struct Failure: Error, CustomStringConvertible {
  let description: String

  init(_ description: String) {
    self.description = description
  }
}

private final class AVService {
  private let handle: HDAAVServiceRef

  init?(registryService: io_service_t) {
    guard let handle = HDAAVServiceCreate(registryService) else { return nil }
    self.handle = handle
  }

  deinit {
    HDAAVServiceRelease(handle)
  }

  func copyEDID() throws -> EDID {
    var result = kIOReturnError
    guard let data = HDAAVServiceCopyEDID(handle, &result) else {
      throw Failure("copy EDID failed: \(describe(result))")
    }
    return try EDID(data: data as Data)
  }

  func setVirtualEDID(_ edid: EDID?) throws {
    let result = HDAAVServiceSetVirtualEDID(handle, edid?.data as CFData?)
    guard result == kIOReturnSuccess else {
      throw Failure("set virtual EDID failed: \(describe(result))")
    }
  }
}

private func describe(_ result: IOReturn) -> String {
  let message = String(cString: mach_error_string(result))
  return String(format: "0x%08x (%@)", UInt32(bitPattern: result), message)
}

private func targetService() throws -> (service: AVService, edid: EDID) {
  guard let matching = IOServiceMatching("DCPAVServiceProxy") else {
    throw Failure("could not create DCPAVServiceProxy match")
  }

  var iterator: io_iterator_t = 0
  let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
  guard result == KERN_SUCCESS else {
    throw Failure("DCPAVServiceProxy lookup failed: \(describe(result))")
  }
  defer { IOObjectRelease(iterator) }

  var matches: [(AVService, EDID)] = []
  while true {
    let registryService = IOIteratorNext(iterator)
    guard registryService != 0 else { break }
    defer { IOObjectRelease(registryService) }

    guard let service = AVService(registryService: registryService),
      let edid = try? service.copyEDID(),
      edid.identity == target.identity
    else {
      continue
    }
    matches.append((service, edid))
  }
  guard matches.count == 1 else {
    throw Failure("expected one connected \(target.name), found \(matches.count)")
  }
  return matches[0]
}

private func backup(_ edid: EDID) throws -> URL {
  let url = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".local/state/hide-display-audio", isDirectory: true)
    .appendingPathComponent(target.backup)
  guard !FileManager.default.fileExists(atPath: url.path) else { return url }
  try FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )
  try edid.data.write(to: url, options: .atomic)
  return url
}

private func run() throws {
  guard CommandLine.arguments.count <= 2,
    let command = Command(CommandLine.arguments.dropFirst().first ?? "on")
  else {
    throw Failure("usage: hide-display-audio [on|off|inspect]")
  }

  let (service, current) = try targetService()

  if command == .off {
    try service.setVirtualEDID(nil)
    print("Disabled the audio-free EDID override")
    return
  }

  let removal = try current.removingAudioAdvertisements()
  guard !removal.removed.isEmpty else {
    print("\(target.name) already advertises no audio")
    return
  }

  let removed = removal.removed.map(\.rawValue).sorted().joined(separator: ", ")
  print("\(target.name): \(current.data.count)-byte EDID; removing \(removed)")
  if command == .inspect {
    print("Current:  \(current.data.hexEncodedString())")
    print("Modified: \(removal.edid.data.hexEncodedString())")
    return
  }

  let backupURL = try backup(current)
  try service.setVirtualEDID(removal.edid)
  print("Applied audio-free EDID")
  print("Factory backup: \(backupURL.path)")
}

extension Data {
  fileprivate func hexEncodedString() -> String {
    map { String(format: "%02x", $0) }.joined()
  }
}

do {
  try run()
} catch {
  FileHandle.standardError.write(Data("hide-display-audio: \(error)\n".utf8))
  exit(1)
}
