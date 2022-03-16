import XCTest
import PrettyBytes

func slowHex(_ v: UInt8, uppercase: Bool) -> String {
  let str = String(v, radix: 16, uppercase: uppercase)
  return String(repeating: "0", count: 2-str.count)+str
}

final class PrettyBytesTests: XCTestCase {
  func testBytesToHexString() throws {

    let buffer = Array(0...UInt8.max)

    for uppercase in [true, false] {

      for number in buffer {
        XCTAssertEqual(
          BytesStringFormatter(uppercase: uppercase).bytesToHexString(CollectionOfOne(number)),
          slowHex(number, uppercase: uppercase)
        )
      }

      XCTAssertEqual(
        BytesStringFormatter(uppercase: uppercase).bytesToHexString(buffer),
        buffer.map {slowHex($0, uppercase: uppercase)}.joined()
      )
    }
  }
}
