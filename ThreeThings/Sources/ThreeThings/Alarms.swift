import Foundation
import ThreeThingsCore
import UserNotifications

/// Schedules a daily notification for every item in 3 Things that has an alarm,
/// and removes the rest. Items in Next keep their time but don't ring.
enum Alarms {
    private static let prefix = "thing-"

    /// Notifications need a real app bundle (not `swift run`).
    static var available: Bool { Bundle.main.bundleIdentifier != nil }

    static func sync(_ board: Board) {
        guard available else { return }
        let center = UNUserNotificationCenter.current()

        let wanted: [UNNotificationRequest] = board.liveAlarms.compactMap { item in
            guard let alarm = item.alarm else { return nil }
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = "One of your 3 Things"
            content.sound = .default

            var when = DateComponents()
            when.hour = alarm.hour
            when.minute = alarm.minute
            // Repeats: rings again tomorrow at the same time if it's still not done.
            let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
            return UNNotificationRequest(identifier: prefix + item.id.uuidString, content: content, trigger: trigger)
        }
        let keep = Set(wanted.map(\.identifier))

        center.getPendingNotificationRequests { pending in
            let stale = pending.map(\.identifier).filter { $0.hasPrefix(prefix) && !keep.contains($0) }
            center.removePendingNotificationRequests(withIdentifiers: stale)
            guard !wanted.isEmpty else { return }
            center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                guard granted else { return }
                // Adding with the same identifier replaces the old one (e.g. after a rename).
                wanted.forEach { center.add($0) }
            }
        }
    }
}

extension AlarmTime {
    init(date: Date) {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        self.init(hour: parts.hour ?? 9, minute: parts.minute ?? 0)
    }

    /// Today at this time.
    var date: Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    var label: String { date.formatted(date: .omitted, time: .shortened) }

    /// The next full hour from now.
    static var suggested: AlarmTime {
        let hour = Calendar.current.component(.hour, from: Date())
        return AlarmTime(hour: (hour + 1) % 24, minute: 0)
    }
}
