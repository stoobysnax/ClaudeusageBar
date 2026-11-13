import SwiftUI
import ThreeThingsCore

struct ItemRow: View {
    let item: Item
    let list: ListKind

    @EnvironmentObject private var store: BoardStore
    @State private var hovering = false
    @State private var editing = false
    @State private var draft = ""
    @FocusState private var fieldFocused: Bool

    private var isDone: Bool { list == .done }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggleDone) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(isDone ? Color.secondary : Color.primary.opacity(hovering ? 0.7 : 0.35))
                    .frame(width: 18)
            }
            .buttonStyle(.plain)
            .help(isDone ? "Mark as not done" : "Mark as done")

            if editing {
                TextField("", text: $draft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .focused($fieldFocused)
                    .onSubmit(commitEdit)
                    .onExitCommand { editing = false }
                    .onChange(of: fieldFocused) { focused in
                        if !focused { commitEdit() }
                    }
            } else {
                Text(item.title)
                    .font(.system(size: 15))
                    .strikethrough(isDone, color: .secondary)
                    .foregroundStyle(isDone ? Color.secondary : Color.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2, perform: startEdit)
            }

            if !isDone {
                AlarmButton(item: item, isLive: list == .three, rowHovering: hovering)
            }
        }
        .padding(.vertical, 8)
        .onHover { hovering = $0 }
        .contextMenu {
            Button("Rename", action: startEdit)
            Divider()
            ForEach(ListKind.allCases.filter { $0 != list }) { target in
                Button("Move to \(target.title)") {
                    store.update { $0.move(item.id, to: target, at: target == .done ? 0 : nil) }
                }
            }
            Divider()
            Button("Delete", role: .destructive) {
                store.update { $0.delete(item.id) }
            }
        }
    }

    private func toggleDone() {
        if isDone {
            store.update { $0.reopen(item.id) }
        } else {
            store.update { $0.complete(item.id) }
        }
    }

    private func startEdit() {
        draft = item.title
        editing = true
        DispatchQueue.main.async { fieldFocused = true }
    }

    private func commitEdit() {
        guard editing else { return }
        let title = draft
        store.update { $0.rename(item.id, to: title) }
        editing = false
    }
}

/// The one-button alarm: a bell that opens a small time picker.
/// Hidden until you hover the row, unless an alarm is set.
struct AlarmButton: View {
    let item: Item
    /// True in 3 Things. In Next the time is kept but doesn't ring.
    let isLive: Bool
    let rowHovering: Bool

    @EnvironmentObject private var store: BoardStore
    @State private var open = false
    @State private var time = Date()

    var body: some View {
        Button {
            time = (item.alarm ?? .suggested).date
            open = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: item.alarm != nil && isLive ? "bell.fill" : "bell")
                if let alarm = item.alarm {
                    Text(alarm.label).monospacedDigit()
                }
            }
            .font(.system(size: 12))
            .foregroundStyle(item.alarm != nil && isLive ? Color.primary.opacity(0.8) : Color.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.black.opacity(item.alarm != nil && isLive ? 0.05 : 0)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(item.alarm != nil || rowHovering || open ? 1 : 0)
        .help(helpText)
        .popover(isPresented: $open, arrowEdge: .bottom) { editor }
    }

    private var helpText: String {
        guard let alarm = item.alarm else { return "Set an alarm" }
        return isLive ? "Rings at \(alarm.label)" : "Rings at \(alarm.label) once this is in 3 Things"
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Remind me at")
                .font(.system(size: 13, weight: .semibold))

            DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.field)

            HStack(spacing: 6) {
                preset("In 1 hr") { AlarmTime(date: Date().addingTimeInterval(3600)) }
                preset("Noon") { AlarmTime(hour: 12, minute: 0) }
                preset("5 PM") { AlarmTime(hour: 17, minute: 0) }
            }

            if !isLive {
                Text("Rings once this moves into 3 Things.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                if item.alarm != nil {
                    Button("Remove") { set(nil) }
                }
                Spacer()
                Button("Set") { set(AlarmTime(date: time)) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 240)
    }

    private func preset(_ title: String, _ make: @escaping () -> AlarmTime) -> some View {
        Button(title) { set(make()) }
            .buttonStyle(.bordered)
            .controlSize(.small)
    }

    private func set(_ alarm: AlarmTime?) {
        store.update { $0.setAlarm(alarm, for: item.id) }
        open = false
    }
}
