import XCTest
@testable import YueYinCore

final class DurationFormatTests: XCTestCase {
    func testFormat() {
        XCTAssertEqual(DurationFormat.format(seconds: 0), "")
        XCTAssertEqual(DurationFormat.format(seconds: 90), "01:30")
        XCTAssertEqual(DurationFormat.format(seconds: 262), "04:22")
        XCTAssertEqual(DurationFormat.format(seconds: 3821), "1:03:41")
    }

    func testParse() {
        XCTAssertEqual(DurationFormat.parse("04:22"), 262_000)
        XCTAssertEqual(DurationFormat.parse("1:03:41"), 3_821_000)
        XCTAssertEqual(DurationFormat.parse("junk"), 0)
        XCTAssertEqual(DurationFormat.parse(""), 0)
    }
}
