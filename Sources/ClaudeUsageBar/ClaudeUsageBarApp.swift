import SwiftUI

@main
struct ClaudeUsageBarApp: App {
    @StateObject private var store = UsageStore()

    var body: some Scene {
        MenuBarExtra {
            UsageMenuView(store: store)
        } label: {
            Text(store.menuBarTitle)
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)
    }
}
