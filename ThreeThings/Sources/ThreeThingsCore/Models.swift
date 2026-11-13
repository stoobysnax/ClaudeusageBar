import Foundation

/// The three lists. Order here is the order they appear in the sidebar.
public enum ListKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case three, next, done

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .three: return "3 Things"
        case .next: return "Next"
        case .done: return "Done"
        }
    }
}

/// A time of day, with no date. Alarms repeat daily while the item sits in 3 Things.
public struct AlarmTime: Codable, Hashable, Sendable {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }
}

public struct Item: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var alarm: AlarmTime?
    public var completedAt: Date?

    public init(id: UUID = UUID(), title: String, alarm: AlarmTime? = nil, completedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.alarm = alarm
        self.completedAt = completedAt
    }
}
