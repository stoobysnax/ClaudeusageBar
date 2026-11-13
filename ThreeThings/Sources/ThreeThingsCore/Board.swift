import Foundation

/// All of the user's items, and the rules for moving them between lists.
///
/// Rules:
/// - 3 Things never holds more than 3 items, in order of importance.
/// - When a 3 Things item is done (or deleted), the top of Next moves to the bottom of 3 Things.
/// - Moving an item into a full 3 Things bumps the current last one to the top of Next.
/// - Only items in 3 Things have live alarms (`liveAlarms`).
public struct Board: Codable, Equatable, Sendable {
    public static let limit = 3

    public private(set) var three: [Item]
    public private(set) var next: [Item]
    /// Most recently finished first.
    public private(set) var done: [Item]

    public init(three: [Item] = [], next: [Item] = [], done: [Item] = []) {
        self.three = three
        self.next = next
        self.done = done
        while self.three.count > Self.limit { self.next.insert(self.three.removeLast(), at: 0) }
    }

    // MARK: Reading

    public func items(in list: ListKind) -> [Item] {
        switch list {
        case .three: return three
        case .next: return next
        case .done: return done
        }
    }

    public func location(of id: UUID) -> (list: ListKind, index: Int)? {
        for list in ListKind.allCases {
            if let index = items(in: list).firstIndex(where: { $0.id == id }) { return (list, index) }
        }
        return nil
    }

    public func item(_ id: UUID) -> Item? {
        guard let loc = location(of: id) else { return nil }
        return items(in: loc.list)[loc.index]
    }

    /// Items whose alarm should ring: only those in 3 Things.
    public var liveAlarms: [Item] { three.filter { $0.alarm != nil } }

    // MARK: Changing

    /// Adds a new item. Adding to a full 3 Things puts it at the end of Next instead.
    @discardableResult
    public mutating func add(_ title: String, to list: ListKind = .three, now: Date = Date()) -> Item? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var item = Item(title: trimmed)
        switch list {
        case .three where three.count < Self.limit:
            three.append(item)
        case .done:
            item.completedAt = now
            done.insert(item, at: 0)
        default:
            next.append(item)
        }
        return item
    }

    public mutating func complete(_ id: UUID, now: Date = Date()) {
        guard let loc = location(of: id), loc.list != .done else { return }
        move(id, to: .done, at: 0, now: now)
    }

    /// Un-finishes an item: back into 3 Things if there's room, otherwise to the top of Next.
    public mutating func reopen(_ id: UUID) {
        guard location(of: id)?.list == .done else { return }
        if three.count < Self.limit {
            move(id, to: .three)
        } else {
            move(id, to: .next, at: 0)
        }
    }

    /// Moves an item to `target` at `index` (nil = end of the list).
    public mutating func move(_ id: UUID, to target: ListKind, at index: Int? = nil, now: Date = Date()) {
        guard let from = location(of: id) else { return }
        var item = withList(from.list) { $0.remove(at: from.index) }

        if target == .done {
            if item.completedAt == nil { item.completedAt = now }
        } else {
            item.completedAt = nil
        }

        switch target {
        case .three:
            // When full, the new item takes the last slot and that item drops to the top of Next.
            let slot = max(0, min(index ?? three.count, three.count, Self.limit - 1))
            three.insert(item, at: slot)
            while three.count > Self.limit { next.insert(three.removeLast(), at: 0) }
        case .next:
            next.insert(item, at: Self.clamp(index, next.count))
        case .done:
            done.insert(item, at: Self.clamp(index, done.count))
        }

        if from.list == .three && target == .done { refill() }
    }

    /// Reorders within one list (drag and drop). Same arguments as SwiftUI's `onMove`.
    public mutating func reorder(_ list: ListKind, fromOffsets source: IndexSet, toOffset destination: Int) {
        withList(list) { items in
            let indices = source.sorted().filter { $0 < items.count }
            guard !indices.isEmpty else { return }
            let moving = indices.map { items[$0] }
            let shift = indices.filter { $0 < destination }.count
            for i in indices.reversed() { items.remove(at: i) }
            let insertAt = max(0, min(destination - shift, items.count))
            items.insert(contentsOf: moving, at: insertAt)
        }
    }

    public mutating func rename(_ id: UUID, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        update(id) { $0.title = trimmed }
    }

    public mutating func setAlarm(_ alarm: AlarmTime?, for id: UUID) {
        update(id) { $0.alarm = alarm }
    }

    public mutating func delete(_ id: UUID) {
        guard let loc = location(of: id) else { return }
        withList(loc.list) { _ = $0.remove(at: loc.index) }
        if loc.list == .three { refill() }
    }

    public mutating func clearDone() {
        done.removeAll()
    }

    /// Fills open 3 Things slots from the top of Next.
    public mutating func refill() {
        while three.count < Self.limit, !next.isEmpty {
            three.append(next.removeFirst())
        }
    }

    // MARK: Helpers

    private mutating func update(_ id: UUID, _ change: (inout Item) -> Void) {
        guard let loc = location(of: id) else { return }
        withList(loc.list) { change(&$0[loc.index]) }
    }

    private mutating func withList<T>(_ list: ListKind, _ body: (inout [Item]) -> T) -> T {
        switch list {
        case .three: return body(&three)
        case .next: return body(&next)
        case .done: return body(&done)
        }
    }

    private static func clamp(_ index: Int?, _ count: Int) -> Int {
        max(0, min(index ?? count, count))
    }
}
