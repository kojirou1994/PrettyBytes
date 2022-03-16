public struct BytesStringFormatter {
  public init(uppercase: Bool = true) {
    self.uppercase = uppercase
  }

  public var uppercase: Bool
}

public extension BytesStringFormatter {

  @inlinable
  func bytesToHexString<T>(_ bytes: T) -> String where T: Sequence, T.Element == UInt8 {
    if let string = bytes.withContiguousStorageIfAvailable({ bytesBuffer -> String in

      func itoh(_ value: UInt8) -> UInt8 {
        (value > 9) ? ((uppercase ? UInt8(ascii: "A") : UInt8(ascii: "a")) + value - 10) : (UInt8(ascii: "0") + value)
      }

      func convert(toBuffer buffer: UnsafeMutableBufferPointer<UInt8>) {
        for (offset, i) in bytesBuffer.enumerated() {
          buffer[offset * 2] = itoh((i >> 4) & 0xF)
          buffer[offset * 2 + 1] = itoh(i & 0xF)
        }
      }

      let hexLen = bytesBuffer.count * 2
      if #available(macOS 11.0, *) {
        return String(unsafeUninitializedCapacity: hexLen) { hexBuffer in
          convert(toBuffer: hexBuffer)
          return hexLen
        }
      } else {
        let hexBuffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: hexLen)
        defer {
          hexBuffer.initialize(repeating: 0)
          hexBuffer.deallocate()
        }
        convert(toBuffer: hexBuffer)
        return String(decoding: hexBuffer, as: UTF8.self)
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
