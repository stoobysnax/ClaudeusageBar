import Foundation
import SwiftUI

@MainActor
final class UsageStore: ObservableObject {
    @Published var usage: UsageResponse?
    @Published var error: String?
    @Published var lastUpdated: Date?
    @Published var isLoading = false

    private var timer: Timer?
    private let interval: TimeInterval = 120

    init() {
        Task { await refresh() }
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }

    var menuBarTitle: String {
        guard let u = usage else { return error == nil ? "✳︎ …" : "✳︎ !" }
        let s = u.fiveHour.map { "\(Int($0.utilization.rounded()))%" } ?? "–"
        let w = u.sevenDay.map { "\(Int($0.utilization.rounded()))%" } ?? "–"
        return "✳︎ \(s) · \(w)"
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            usage = try await UsageAPI.fetch()
            error = nil
            lastUpdated = Date()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
