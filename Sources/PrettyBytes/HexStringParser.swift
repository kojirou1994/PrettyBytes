public struct HexStringParser {
  public init(extraByteHandling: ExtraByteHandling = .error) {
    self.extraByteHandling = extraByteHandling
  }

  public var extraByteHandling: ExtraByteHandling

  public enum ExtraByteHandling {
    case ignored
    case error
    case leftPadded
    case rightPadded
  }

  public enum Error: Swift.Error {
    case invalidHexValue
    case notAligned
  }
}

public extension HexStringParser {

  func parse<S, B>(_ string: S) throws -> B where S: StringProtocol, B: RangeReplaceableCollection, B.Element == UInt8 {
    try parse(string.utf8)
  }

  func parse<S, B>(_ bytes: S) throws -> B where S: Sequence, S.Element == UInt8, B: RangeReplaceableCollection, B.Element == UInt8 {

    if let fast: B = try bytes.withContiguousStorageIfAvailable(parse) {
      return fast
    }

    var result = B()
    result.reserveCapacity(bytes.underestimatedCount / 2 + 1)
    var iterator = bytes.makeIterator()
    while let left = iterator.next() {
      if let right = iterator.next() {
        result.append(try hToI(left: left, right: right))
      } else {
        switch extraByteHandling {
        case .ignored:
          break
        case .error:
          throw Error.notAligned
        case .leftPadded:
          result.append(try hToI(left: 0, right: left))
        case .rightPadded:
          result.append(try hToI(left: left, right: 0))
        }
      }
    }
    return result
  }

  func parse<B>(_ buffer: UnsafeBufferPointer<UInt8>) throws -> B where B: RangeReplaceableCollection, B.Element == UInt8 {
    let aligned = buffer.count % 2 == 0
    if !aligned, extraByteHandling == .error {
      throw Error.notAligned
    }

    var result = B()
    if buffer.isEmpty {
      return result
    }
    result.reserveCapacity(buffer.count / 2 + 1)

    for i in 0...((buffer.count / 2) - 1) {
      result.append(try hToI(left: buffer[2 * i], right: buffer[2 * i + 1]))
    }

    if !aligned {
      switch extraByteHandling {
      case .ignored, .error:
        break
      case .leftPadded:
        result.append(try hToI(left: 0, right: buffer.last!))
      case .rightPadded:
        result.append(try hToI(left: buffer.last!, right: 0))
      }
    }

    return result
  }

  private func hToI(left: UInt8, right: UInt8) throws -> UInt8 {
    func hTo4b(_ value: UInt8) throws -> UInt8 {
      switch value {
      case UInt8(ascii: "0")...UInt8(ascii: "9"):
        return value - UInt8(ascii: "0")
      case UInt8(ascii: "A")...UInt8(ascii: "F"):
        return value - UInt8(ascii: "A") + 10
      case UInt8(ascii: "a")...UInt8(ascii: "f"):
        return value - UInt8(ascii: "a") + 10
      default:
        throw HexStringParser.Error.invalidHexValue
      }
    }

    return try hTo4b(left) << 4 + hTo4b(right)
  }

}
