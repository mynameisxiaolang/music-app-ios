import XCTest
@testable import YueYinCore

final class BiliJSONParsersTests: XCTestCase {
    func testParseRanking() {
        let items = BiliJSONParsers.parseRanking(Fixtures.rankingJSON)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].bvid, "BV1GJ411x7h7")
        XCTAssertEqual(items[0].duration, "04:22")
        XCTAssertEqual(items[0].cover, "https://i0.hdslb.com/bfs/archive/abc.jpg")
        XCTAssertEqual(items[1].duration, "1:03:41")
        XCTAssertNil(items[1].cover)
    }

    func testParseRankingJunkReturnsEmpty() {
        XCTAssertTrue(BiliJSONParsers.parseRanking(Data("not json".utf8)).isEmpty)
    }

    func testParseAudioUrlPicksMaxBandwidth() {
        XCTAssertEqual(BiliJSONParsers.parseAudioUrl(Fixtures.playurlJSON), "https://legacy.example.com/30232.m4a")
    }

    func testParseAudioUrlJunkReturnsNil() {
        XCTAssertNil(BiliJSONParsers.parseAudioUrl(Data("not json".utf8)))
    }

    func testParseCid() {
        XCTAssertEqual(BiliJSONParsers.parseCid(Fixtures.pagelistJSON), 251_767_522)
    }

    func testParseCidJunkReturnsNil() {
        XCTAssertNil(BiliJSONParsers.parseCid(Data("not json".utf8)))
    }
}
