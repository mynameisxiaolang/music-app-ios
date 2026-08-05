import XCTest
@testable import YueYinCore

final class TitleCleanerTests: XCTestCase {
    func testStripsTagsAndCollapsesWhitespace() {
        XCTAssertEqual(TitleCleaner.displayTitle("【钢琴】告白气球 - 周杰伦"), "告白气球 - 周杰伦")
        XCTAssertEqual(TitleCleaner.displayTitle("[4K] 星空  音乐会"), "星空 音乐会")
    }

    func testBlankFallsBackToOriginal() {
        XCTAssertEqual(TitleCleaner.displayTitle("【】"), "【】")
    }
}
