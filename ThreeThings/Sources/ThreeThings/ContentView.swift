import SwiftUI
import ThreeThingsCore
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selection: ListKind = .three

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(selection: $selection)
                .frame(width: 180)
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(width: 1)
            ListPane(list: selection)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 560, minHeight: 360)
        .background(Color.white.ignoresSafeArea())
        .background(shortcuts)
    }

    /// ⌘1 3 Things, ⌘2 Next, ⌘3 Done.
    private var shortcuts: some View {
        ZStack {
            ForEach(Array(ListKind.allCases.enumerated()), id: \.element) { index, list in
                Button("") { selection = list }
                    .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
            }
        }
        .opacity(0)
        .allowsHitTesting(false)
    }
}

// MARK: - Sidebar

struct Sidebar: View {
    @Binding var selection: ListKind
    @EnvironmentObject private var store: BoardStore

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(ListKind.allCases) { list in
                SidebarRow(list: list, count: countLabel(list), isSelected: selection == list) {
                    selection = list
                }
            }
            Spacer()
        }
        .padding(.top, 44)
        .padding(.horizontal, 10)
    }

    private func countLabel(_ list: ListKind) -> String {
        let n = store.board.items(in: list).count
        if list == .three { return "\(n)/\(Board.limit)" }
        return n == 0 ? "" : "\(n)"
    }
}

/// A sidebar entry. Drop an item on it to move the item to that list.
struct SidebarRow: View {
    let list: ListKind
    let count: String
    let isSelected: Bool
    let select: () -> Void

    @EnvironmentObject private var store: BoardStore
    @State private var isTargeted = false

    var body: some View {
        Button(action: select) {
            HStack {
                Text(list.title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                Spacer()
                Text(count)
                    .font(.system(size: 12))
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.black.opacity(isTargeted ? 0.08 : (isSelected ? 0.04 : 0)))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onDrop(of: [UTType.plainText], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: NSString.self) { object, _ in
                guard let text = object as? NSString, let id = UUID(uuidString: text as String) else { return }
                DispatchQueue.main.async {
                    // Next: to the end. Done: to the top. 3 Things: to the end (bumps #3 if full).
                    store.update { $0.move(id, to: list, at: list == .done ? 0 : nil) }
                }
            }
            return true
        }
    }
}

// MARK: - List

struct ListPane: View {
    let list: ListKind
    @EnvironmentObject private var store: BoardStore

    var body: some View {
        let items = store.board.items(in: list)
        VStack(alignment: .leading, spacing: 0) {
            header(isEmpty: items.isEmpty)
                .padding(.horizontal, 32)
                .padding(.top, 40)
                .padding(.bottom, 14)

            List {
                ForEach(items) { item in
                    ItemRow(item: item, list: list)
                        .itemProvider { NSItemProvider(object: item.id.uuidString as NSString) }
                }
                .onMove { from, to in
                    store.update { $0.reorder(list, fromOffsets: from, toOffset: to) }
                }

                switch list {
                case .three:
                    // Always show three slots: the first open one takes a new thing.
                    ForEach(Array(min(items.count, Board.limit)..<Board.limit), id: \.self) { slot in
                        if slot == items.count {
                            AddRow(list: .three, placeholder: "Add a thing")
                        } else {
                            EmptySlotRow()
                        }
                    }
                case .next:
                    AddRow(list: .next, placeholder: "Add to Next")
                case .done:
                    if items.isEmpty {
                        Text("Nothing finished yet.")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 8)
                            .moveDisabled(true)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 40)
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private func header(isEmpty: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(list.title)
                    .font(.system(size: 28, weight: .semibold))
                    .tracking(-0.4)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if list == .done && !isEmpty {
                Button("Clear") { store.update { $0.clearDone() } }
                    .buttonStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var subtitle: String {
        switch list {
        case .three: return Date().formatted(.dateTime.weekday(.wide).month(.wide).day())
        case .next: return "Moves up when one of your 3 Things is done."
        case .done: return "Finished."
        }
    }
}

struct AddRow: View {
    let list: ListKind
    let placeholder: String

    @EnvironmentObject private var store: BoardStore
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
                .frame(width: 18)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .focused($focused)
                .onSubmit {
                    let title = text
                    store.update { _ = $0.add(title, to: list) }
                    text = ""
                    focused = true
                }
        }
        .padding(.vertical, 8)
        .moveDisabled(true)
    }
}

struct EmptySlotRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .strokeBorder(Color.black.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                .frame(width: 16, height: 16)
                .frame(width: 18)
            Spacer()
        }
        .padding(.vertical, 8)
        .moveDisabled(true)
    }
}
