import SwiftUI
import UserNotifications

@main
struct ThreeThingsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = BoardStore()

    var body: some Scene {
        WindowGroup("3 Things") {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 720, height: 460)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .aqua) // always the clean white look
        if Alarms.available {
            UNUserNotificationCenter.current().delegate = self
        }
    }

    // Show the alarm even when 3 Things is the app in front.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
