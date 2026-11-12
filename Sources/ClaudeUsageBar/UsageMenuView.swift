import SwiftUI

struct UsageMenuView: View {
    @ObservedObject var store: UsageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Claude Usage").font(.headline)
                Spacer()
                if store.isLoading { ProgressView().controlSize(.small) }
            }

            if let u = store.usage {
                UsageRow(title: "Current session (5h)", window: u.fiveHour)
                UsageRow(title: "This week (all models)", window: u.sevenDay)
                if let opus = u.sevenDayOpus, opus.utilization > 0 {
                    UsageRow(title: "This week (Opus)", window: opus)
                }
                if let sonnet = u.sevenDaySonnet, sonnet.utilization > 0 {
                    UsageRow(title: "This week (Sonnet)", window: sonnet)
                }
            }

            if let err = store.error {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            HStack {
                if let t = store.lastUpdated {
                    Text("Updated \(t.formatted(date: .omitted, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Refresh") { Task { await store.refresh() } }
                    .keyboardShortcut("r")
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q")
            }
        }
        .padding(16)
        .frame(width: 300)
    }
}

struct UsageRow: View {
    let title: String
    let window: UsageWindow?

    var body: some View {
        let pct = window?.utilization ?? 0
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Text(window == nil ? "–" : "\(Int(pct.rounded()))%")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
            }
            ProgressView(value: min(pct, 100), total: 100)
                .tint(color(for: pct))
            if let reset = window?.resetsAt {
                Text("Resets \(resetText(reset))")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func color(for pct: Double) -> Color {
        switch pct {
        case ..<50: return .green
        case ..<80: return .orange
        default: return .red
        }
    }

    private func resetText(_ date: Date) -> String {
        let rel = RelativeDateTimeFormatter()
        rel.unitsStyle = .short
        let relative = rel.localizedString(for: date, relativeTo: Date())
        let abs = date.formatted(.dateTime.weekday(.abbreviated).hour().minute())
        return "\(relative) (\(abs))"
    }
}
