import XCTest
@testable import ThreeThingsCore

final class BoardTests: XCTestCase {
    private func board(three: [String], next: [String] = []) -> Board {
        var b = Board()
        three.forEach { b.add($0, to: .three) }
        next.forEach { b.add($0, to: .next) }
        return b
    }

    private func titles(_ b: Board, _ list: ListKind) -> [String] { b.items(in: list).map(\.title) }

    func testThreeNeverHoldsMoreThanThree() {
        var b = board(three: ["a", "b", "c"])
        b.add("d", to: .three)
        XCTAssertEqual(titles(b, .three), ["a", "b", "c"])
        XCTAssertEqual(titles(b, .next), ["d"])
    }

    func testCompletingPullsTopOfNextToBottom() {
        var b = board(three: ["a", "b", "c"], next: ["d", "e"])
        b.complete(b.three[0].id)
        XCTAssertEqual(titles(b, .three), ["b", "c", "d"])
        XCTAssertEqual(titles(b, .next), ["e"])
        XCTAssertEqual(titles(b, .done), ["a"])
        XCTAssertNotNil(b.done[0].completedAt)
    }

    func testMovingIntoFullThreeBumpsLastToTopOfNext() {
        var b = board(three: ["a", "b", "c"], next: ["d", "e"])
        b.move(b.next[1].id, to: .three, at: 0)
        XCTAssertEqual(titles(b, .three), ["e", "a", "b"])
        XCTAssertEqual(titles(b, .next), ["c", "d"])
    }

    func testMovingToEndOfFullThreeTakesLastSlot() {
        var b = board(three: ["a", "b", "c"], next: ["d"])
        b.move(b.next[0].id, to: .three)
        XCTAssertEqual(titles(b, .three), ["a", "b", "d"])
        XCTAssertEqual(titles(b, .next), ["c"])
    }

    func testMovingOutOfThreeToNextDoesNotRefill() {
        var b = board(three: ["a", "b", "c"], next: ["d"])
        b.move(b.three[0].id, to: .next)
        XCTAssertEqual(titles(b, .three), ["b", "c"])
        XCTAssertEqual(titles(b, .next), ["d", "a"])
    }

    func testOnlyThreeAlarmsAreLive() {
        var b = board(three: ["a"], next: ["b"])
        b.setAlarm(AlarmTime(hour: 9, minute: 0), for: b.three[0].id)
        b.setAlarm(AlarmTime(hour: 10, minute: 0), for: b.next[0].id)
        XCTAssertEqual(b.liveAlarms.map(\.title), ["a"])
        b.complete(b.three[0].id) // "b" moves up and its alarm goes live
        XCTAssertEqual(b.liveAlarms.map(\.title), ["b"])
    }

    func testReopenGoesToThreeOrTopOfNext() {
        var b = board(three: ["a", "b", "c"], next: ["d"])
        b.complete(b.three[0].id)
        let a = b.done[0].id
        b.reopen(a)
        XCTAssertEqual(titles(b, .next), ["a"])
        XCTAssertNil(b.item(a)?.completedAt)
    }

    func testReorder() {
        var b = board(three: ["a", "b", "c"])
        b.reorder(.three, fromOffsets: IndexSet(integer: 0), toOffset: 3)
        XCTAssertEqual(titles(b, .three), ["b", "c", "a"])
    }

    func testDeleteFromThreeRefills() {
        var b = board(three: ["a", "b", "c"], next: ["d"])
        b.delete(b.three[1].id)
        XCTAssertEqual(titles(b, .three), ["a", "c", "d"])
    }

    func testRoundTripsThroughFile() throws {
        var b = board(three: ["a"], next: ["b"])
        b.setAlarm(AlarmTime(hour: 7, minute: 30), for: b.three[0].id)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("board.json")
        let file = BoardFile(url: url)
        try file.save(b)
        XCTAssertEqual(file.load(), b)
    }
}
