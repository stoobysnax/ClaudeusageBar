import Foundation
import ThreeThingsCore

/// Holds the board for the UI, saves every change, and keeps alarms in step.
@MainActor
final class BoardStore: ObservableObject {
    @Published private(set) var board: Board
    private let file: BoardFile

    init(file: BoardFile = BoardFile()) {
        self.file = file
        self.board = file.load()
        Alarms.sync(board)
    }

    func update(_ change: (inout Board) -> Void) {
        var changed = board
        change(&changed)
        guard changed != board else { return }
        board = changed
        do {
            try file.save(changed)
        } catch {
            NSLog("3 Things could not save: \(error.localizedDescription)")
        }
        Alarms.sync(changed)
    }
}
