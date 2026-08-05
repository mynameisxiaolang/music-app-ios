import XCTest
@testable import YueYin

final class QueueLogicTests: XCTestCase {
    func testAutoNextOrderWraps() {
        XCTAssertEqual(QueueLogic.autoNextIndex(current: 0, count: 3, mode: .order, shuffled: []), 1)
        XCTAssertEqual(QueueLogic.autoNextIndex(current: 2, count: 3, mode: .order, shuffled: []), 0)
    }

    func testAutoNextRepeatOneStays() {
        XCTAssertEqual(QueueLogic.autoNextIndex(current: 1, count: 3, mode: .repeatOne, shuffled: []), 1)
    }

    func testAutoNextShuffleWalksPermutation() {
        let shuffled = [2, 0, 1]
        var seen: [Int] = []
        var current = 0
        for _ in 0..<3 {
            guard let next = QueueLogic.autoNextIndex(current: current, count: 3, mode: .shuffle, shuffled: shuffled) else {
                return XCTFail("unexpected nil")
            }
            seen.append(next)
            current = next
        }
        XCTAssertEqual(Set(seen), [0, 1, 2])
    }

    func testUserNextIgnoresRepeatOne() {
        XCTAssertEqual(QueueLogic.userNextIndex(current: 1, count: 3, mode: .repeatOne, shuffled: []), 2)
    }

    func testUserPreviousWraps() {
        XCTAssertEqual(QueueLogic.userPreviousIndex(current: 0, count: 3, mode: .order, shuffled: []), 2)
        XCTAssertEqual(QueueLogic.userPreviousIndex(current: 2, count: 3, mode: .order, shuffled: []), 1)
    }
}
