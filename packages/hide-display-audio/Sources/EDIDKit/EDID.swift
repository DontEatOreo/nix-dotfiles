import Foundation

public struct EDID: Equatable, Sendable {
  public static let blockSize = 128

  public struct Identity: Equatable, Sendable {
    public let manufacturerID: UInt16
    public let productCode: UInt16
    public let serialNumber: UInt32

    public init(manufacturerID: UInt16, productCode: UInt16, serialNumber: UInt32) {
      self.manufacturerID = manufacturerID
      self.productCode = productCode
      self.serialNumber = serialNumber
    }
  }

  public enum AudioAdvertisement: String, Hashable, Sendable {
    case basicAudio = "CTA basic-audio flag"
    case audioDataBlock = "audio data block"
    case speakerAllocation = "speaker-allocation block"
    case vendorSpecificAudio = "vendor-specific audio block"
    case hdmiAudio = "HDMI audio block"
    case roomConfiguration = "room-configuration block"
    case speakerLocation = "speaker-location block"
  }

  public struct AudioRemoval: Equatable, Sendable {
    public let edid: EDID
    public let removed: Set<AudioAdvertisement>
  }

  public enum ValidationError: Error, Equatable, CustomStringConvertible {
    case invalidLength(Int)
    case invalidHeader
    case extensionCount(expected: Int, actual: Int)
    case invalidChecksum(block: Int)
    case malformedCTAExtension(String)

    public var description: String {
      switch self {
      case .invalidLength(let length):
        "length \(length) is not a positive multiple of 128"
      case .invalidHeader:
        "missing the standard EDID header"
      case .extensionCount(let expected, let actual):
        "base block declares \(expected) extension(s), found \(actual)"
      case .invalidChecksum(let block):
        "invalid checksum in block \(block)"
      case .malformedCTAExtension(let reason):
        "malformed CTA extension: \(reason)"
      }
    }
  }

  private static let header: [UInt8] = [
    0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00,
  ]

  private let blocks: [Block]

  public init(data: Data) throws {
    let bytes = [UInt8](data)
    guard !bytes.isEmpty, bytes.count.isMultiple(of: Self.blockSize) else {
      throw ValidationError.invalidLength(bytes.count)
    }
    guard bytes.starts(with: Self.header) else { throw ValidationError.invalidHeader }

    let actualExtensions = bytes.count / Self.blockSize - 1
    guard Int(bytes[126]) == actualExtensions else {
      throw ValidationError.extensionCount(expected: Int(bytes[126]), actual: actualExtensions)
    }

    blocks = try stride(from: 0, to: bytes.count, by: Self.blockSize).map { offset in
      try Block(Array(bytes[offset..<(offset + Self.blockSize)]), index: offset / Self.blockSize)
    }
  }

  private init(blocks: [Block]) {
    self.blocks = blocks
  }

  public var data: Data { Data(blocks.flatMap(\.bytes)) }

  public var identity: Identity {
    let base = blocks[0].bytes
    return Identity(
      manufacturerID: UInt16(base[8]) << 8 | UInt16(base[9]),
      productCode: UInt16(base[10]) | UInt16(base[11]) << 8,
      serialNumber: UInt32(base[12]) | UInt32(base[13]) << 8 | UInt32(base[14]) << 16 | UInt32(
        base[15]) << 24
    )
  }

  public func removingAudioAdvertisements() throws -> AudioRemoval {
    var blocks = blocks
    var removed: Set<AudioAdvertisement> = []

    for index in blocks.indices.dropFirst() where blocks[index].bytes[0] == CTAExtension.tag {
      var extensionBlock = CTAExtension(block: blocks[index])
      removed.formUnion(try extensionBlock.removeAudioAdvertisements())
      blocks[index] = extensionBlock.block
    }
    return AudioRemoval(edid: EDID(blocks: blocks), removed: removed)
  }
}

private struct Block: Equatable, Sendable {
  var bytes: [UInt8]

  init(_ bytes: [UInt8], index: Int) throws {
    guard bytes.count == EDID.blockSize else {
      throw EDID.ValidationError.invalidLength(bytes.count)
    }
    guard bytes.reduce(0, &+) == 0 else {
      throw EDID.ValidationError.invalidChecksum(block: index)
    }
    self.bytes = bytes
  }

  mutating func updateChecksum() {
    bytes[127] = 0 &- bytes[..<127].reduce(0, &+)
  }
}

private struct CTAExtension {
  static let tag: UInt8 = 0x02

  private struct DataBlockTag: Hashable {
    let primary: UInt8
    let extended: UInt8?
  }

  private struct DataBlock {
    let bytes: [UInt8]

    var tag: DataBlockTag {
      let primary = bytes[0] >> 5
      return DataBlockTag(primary: primary, extended: primary == 7 ? bytes.dropFirst().first : nil)
    }
  }

  private static let audioBlocks: [DataBlockTag: EDID.AudioAdvertisement] = [
    DataBlockTag(primary: 1, extended: nil): .audioDataBlock,
    DataBlockTag(primary: 4, extended: nil): .speakerAllocation,
    DataBlockTag(primary: 7, extended: 0x11): .vendorSpecificAudio,
    DataBlockTag(primary: 7, extended: 0x12): .hdmiAudio,
    DataBlockTag(primary: 7, extended: 0x13): .roomConfiguration,
    DataBlockTag(primary: 7, extended: 0x14): .speakerLocation,
  ]

  var block: Block

  mutating func removeAudioAdvertisements() throws -> Set<EDID.AudioAdvertisement> {
    var removed: Set<EDID.AudioAdvertisement> = []
    if block.bytes[3] & 0x40 != 0 {
      block.bytes[3] &= ~0x40
      removed.insert(.basicAudio)
    }

    let offset = Int(block.bytes[2])
    guard offset != 0 else {
      if !removed.isEmpty { block.updateChecksum() }
      return removed
    }
    guard (4...127).contains(offset) else {
      throw EDID.ValidationError.malformedCTAExtension("invalid DTD offset \(offset)")
    }

    let dataBlocks = try Self.parseDataBlocks(block.bytes[4..<offset])
    let retained = dataBlocks.filter { dataBlock in
      guard let advertisement = Self.audioBlocks[dataBlock.tag] else { return true }
      removed.insert(advertisement)
      return false
    }
    guard retained.count != dataBlocks.count else {
      if !removed.isEmpty { block.updateChecksum() }
      return removed
    }

    let encoded = retained.flatMap(\.bytes)
    let tail = Array(block.bytes[offset..<127])
    let padding = [UInt8](repeating: 0, count: 123 - encoded.count - tail.count)
    block.bytes[2] = UInt8(4 + encoded.count)
    block.bytes.replaceSubrange(4..<127, with: encoded + tail + padding)
    block.updateChecksum()
    return removed
  }

  private static func parseDataBlocks(_ bytes: ArraySlice<UInt8>) throws -> [DataBlock] {
    var blocks: [DataBlock] = []
    var cursor = bytes.startIndex
    while cursor < bytes.endIndex {
      let header = bytes[cursor]
      if header == 0 {
        guard bytes[cursor...].allSatisfy({ $0 == 0 }) else {
          throw EDID.ValidationError.malformedCTAExtension("non-zero data after padding")
        }
        break
      }

      let end = cursor + 1 + Int(header & 0x1f)
      guard end <= bytes.endIndex else {
        throw EDID.ValidationError.malformedCTAExtension("data block overruns DTD offset")
      }
      blocks.append(DataBlock(bytes: Array(bytes[cursor..<end])))
      cursor = end
    }
    return blocks
  }
}
