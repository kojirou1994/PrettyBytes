public struct BytesStringFormatter {
  public init(uppercase: Bool = true) {
    self.uppercase = uppercase
  }

  public var uppercase: Bool
}

extension BytesStringFormatter {

  /// value only have right side 4bits
  private func r4bitsToHexASCII(_ value: UInt8) -> UInt8 {
    assert(value & 0xf0 == 0)
    return (value > 9) ? ((uppercase ? UInt8(ascii: "A") : UInt8(ascii: "a")) + value - 10) : (UInt8(ascii: "0") + value)
  }

  public func bytesToHexString(buffer: UnsafeBufferPointer<UInt8>, outputBuffer: UnsafeMutableBufferPointer<UInt8>) {
    assert(outputBuffer.count == (buffer.count * 2))
    for (offset, i) in buffer.enumerated() {
      outputBuffer[offset * 2] = r4bitsToHexASCII((i >> 4) & 0xF)
      outputBuffer[offset * 2 + 1] = r4bitsToHexASCII(i & 0xF)
    }
  }

  public func bytesToHexString(_ bytes: some Sequence<UInt8>) -> String {
    if let string = bytes.withContiguousStorageIfAvailable({ bytesBuffer -> String in

      let hexLen = bytesBuffer.count * 2
      if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
        return String(unsafeUninitializedCapacity: hexLen) { hexBuffer in
          bytesToHexString(buffer: bytesBuffer, outputBuffer: hexBuffer)
          return hexLen
        }
      } else {
        return withUnsafeTemporaryAllocation(of: UInt8.self, capacity: hexLen) { hexBuffer in
          bytesToHexString(buffer: bytesBuffer, outputBuffer: hexBuffer)
          return String(decoding: hexBuffer, as: UTF8.self)
        }
      }

    }) {
      return string
    }

    let maxStackSize = 7
    let bytesBuffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: maxStackSize)
    defer {
      bytesBuffer.initialize(repeating: 0)
      bytesBuffer.deallocate()
    }

    var result = ""
    result.reserveCapacity(bytes.underestimatedCount * 2)

    var iterator = bytes.makeIterator()
    var currentStackSize = 0

    while let next = iterator.next() {
      currentStackSize += 1
      bytesBuffer[currentStackSize-1] = next
      if currentStackSize == maxStackSize {
        result.append(bytesToHexString(bytesBuffer))
        currentStackSize = 0
      }
    }
    if currentStackSize > 0 {
      result.append(bytesToHexString(bytesBuffer.prefix(currentStackSize)))
    }

    return result
  }

}
