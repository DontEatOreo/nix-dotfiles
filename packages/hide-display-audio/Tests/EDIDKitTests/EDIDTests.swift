import EDIDKit
import Foundation
import Testing

private let factory = Data(
  base64Encoded:
    "AP///////wAF4wIkejQAAB8eAQOANR54KvtVo1VQnSYOUFS/7wDRwLMAlQCBgIFAgcABAQEBAjqAGHE4LUBYLEUADyghAAAeKkSAoHA4J0AwIDUADyghAAAaAAAA/AAyNEcyVzFHNQogICAgAAAA/QAwSx5VEgAKICAgICAgAQsCAyfxSxAfBRQEEwMSAhEBIwkHB4MBAABlAwwAEABoGgAAAQEwS+aMCtCKIOAtEBA+lgAPKCEAABgBHQByUdAeIG4oVQAPKCEAAB6MCtCKIOAtEBA+lgAPKCEAABiMCtCQIEAxIAxAVQAPKCEAABgAAAAAAAAAAAAAAAAAAAAA3w=="
)!
private let audioFree = Data(
  base64Encoded:
    "AP///////wAF4wIkejQAAB8eAQOANR54KvtVo1VQnSYOUFS/7wDRwLMAlQCBgIFAgcABAQEBAjqAGHE4LUBYLEUADyghAAAeKkSAoHA4J0AwIDUADyghAAAaAAAA/AAyNEcyVzFHNQogICAgAAAA/QAwSx5VEgAKICAgICAgAQsCAx+xSxAfBRQEEwMSAhEBZQMMABAAaBoAAAEBMEvmjArQiiDgLRAQPpYADyghAAAYAR0AclHQHiBuKFUADyghAAAejArQiiDgLRAQPpYADyghAAAYjArQkCBAMSAMQFUADyghAAAYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA5Q=="
)!

@Test func removesOnlyAudioAdvertisements() throws {
  let edid = try EDID(data: factory)
  let result = try edid.removingAudioAdvertisements()

  #expect(
    result.removed == [
      .basicAudio,
      .audioDataBlock,
      .speakerAllocation,
    ]
  )
  #expect(result.edid.data == audioFree)
  #expect(result.edid.identity == edid.identity)
}

@Test func transformationIsIdempotent() throws {
  let edid = try EDID(data: audioFree)
  let result = try edid.removingAudioAdvertisements()

  #expect(result.removed.isEmpty)
  #expect(result.edid == edid)
}

@Test func validatesEveryBlockChecksum() throws {
  var corrupt = factory
  corrupt[200] ^= 1

  #expect(throws: EDID.ValidationError.invalidChecksum(block: 1)) {
    try EDID(data: corrupt)
  }
}

@Test func rejectsDataBlocksThatOverrunTheCTACollection() throws {
  var malformed = factory
  malformed[130] = 5
  malformed.updateChecksum(block: 1)

  #expect(
    throws: EDID.ValidationError.malformedCTAExtension("data block overruns DTD offset")
  ) {
    try EDID(data: malformed).removingAudioAdvertisements()
  }
}

extension Data {
  fileprivate mutating func updateChecksum(block: Int) {
    let start = block * EDID.blockSize
    let checksum = start + EDID.blockSize - 1
    self[checksum] = 0
    self[checksum] = 0 &- self[start..<checksum].reduce(UInt8.zero, { $0 &+ $1 })
  }
}
