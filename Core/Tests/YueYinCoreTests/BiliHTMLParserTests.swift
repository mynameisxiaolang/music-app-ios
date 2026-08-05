import XCTest
@testable import YueYinCore

final class BiliHTMLParserTests: XCTestCase {
    func testParsesThreeCards() {
        let cards = BiliHTMLParser.parseSearchCards(html: Fixtures.searchHTML)
        XCTAssertEqual(cards.count, 3)
        XCTAssertEqual(cards[0].bvid, "BV1GJ411x7h7")
        XCTAssertEqual(cards[0].title, "【钢琴】告白气球 - 周杰伦")
        XCTAssertEqual(cards[0].duration, "04:22")
        XCTAssertEqual(cards[0].cover, "https://i0.hdslb.com/bfs/archive/abc123.jpg@672w_378h_1c.webp")
        XCTAssertEqual(cards[1].bvid, "BV1Zx411w7KC")
        XCTAssertEqual(cards[1].duration, "1:03:41")
        XCTAssertEqual(cards[1].cover, "https://i1.hdslb.com/bfs/archive/def456.jpg")
        XCTAssertEqual(cards[2].bvid, "BV1wK411a7s2")
        XCTAssertNil(cards[2].cover)
        XCTAssertEqual(cards[2].duration, "")
    }

    func testJunkHTMLReturnsEmpty() {
        XCTAssertTrue(BiliHTMLParser.parseSearchCards(html: "<html>nothing here</html>").isEmpty)
        XCTAssertTrue(BiliHTMLParser.parseSearchCards(html: "").isEmpty)
    }
}
