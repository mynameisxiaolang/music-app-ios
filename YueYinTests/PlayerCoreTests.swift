import XCTest
import YueYinCore
@testable import YueYin

final class PlayerCoreTests: XCTestCase {
    // 只断言队列/索引/当前曲目(不触发真实网络播放;bvid 无效时 playCurrent 静默失败,不阻塞断言)
    func testPlaySetsQueueAndIndex() {
        let core = PlayerCore.shared
        let songs = [
            Song(name: "A", bvid: "BV1"),
            Song(name: "B", bvid: "BV2"),
            Song(name: "C", bvid: "BV3"),
        ]
        core.play(songs, startAt: 1)
        XCTAssertEqual(core.queue.count, 3)
        XCTAssertEqual(core.currentIndex, 1)
        XCTAssertEqual(core.currentSong?.name, "B")
    }

    func testNextAndPreviousMove() {
        let core = PlayerCore.shared
        let songs = [Song(name: "A", bvid: "BV1"), Song(name: "B", bvid: "BV2"), Song(name: "C", bvid: "BV3")]
        core.play(songs, startAt: 0)
        core.next()
        XCTAssertEqual(core.currentIndex, 1)
        core.previous()
        XCTAssertEqual(core.currentIndex, 0)
    }
}
