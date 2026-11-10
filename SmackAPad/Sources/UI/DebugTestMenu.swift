#if DEBUG
import Darwin
import SwiftUI

@MainActor
struct DebugDeveloperSection: View {
    var body: some View {
        Section {
            NavigationLink {
                DebugTestMenu()
            } label: {
                Text(verbatim: "Test scenarios")
                    .font(Theme.control)
                    .frame(minHeight: Theme.Size.touch)
            }
        } header: {
            Text(verbatim: "Developer")
        }
    }
}

@MainActor
struct DebugTestMenu: View {
    private let store = DebugSnapshotStore.shared
    @State private var names: [String] = []
    @State private var name = ""
    @State private var overrides = DebugSnapshotStore.shared.overrides
    @State private var pendingChange: Change?
    @State private var errorMessage: String?
    @State private var pendingDeletion: String?

    private enum Change {
        case scenario(DebugScenario), snapshot(String), overrides, restore
    }

    var body: some View {
        Form {
            Section {
                ForEach(DebugScenario.allCases) { scenario in
                    Button {
                        pendingChange = .scenario(scenario)
                    } label: {
                        Text(verbatim: scenario.rawValue)
                    }
                }
            } header: {
                Text(verbatim: "Built-in scenarios")
            } footer: {
                Text(verbatim: "Built-in scenarios use the purchase access and day shift selected below.")
            }

            Section {
                Picker(selection: $overrides.access) {
                    ForEach(DebugAccessOverride.allCases, id: \.self) { access in
                        Text(verbatim: access.rawValue.capitalized).tag(access)
                    }
                } label: {
                    Text(verbatim: "Purchase access")
                }
                HStack {
                    Text(verbatim: "Day shift")
                    Spacer()
                    Text(verbatim: dayLabel)
                        .monospacedDigit()
                }
                HStack(spacing: Theme.Space.regular) {
                    dayButton("−1 day", by: -1)
                    dayButton("+1 day", by: 1)
                    dayButton("+7 days", by: 7)
                }
                Button {
                    overrides.dayOffset = 0
                } label: {
                    Text(verbatim: "Reset to real date")
                }
                .disabled(overrides.dayOffset == 0)

                Button {
                    pendingChange = .overrides
                } label: {
                    Text(verbatim: "Apply overrides")
                }
                .disabled(overrides == store.overrides)
            } header: {
                Text(verbatim: "Overrides")
            } footer: {
                Text(verbatim: "Applying overrides to your real profile starts a test copy. Saved snapshots keep their own overrides.")
            }

            Section {
                TextField(text: $name, prompt: Text(verbatim: "Snapshot name")) {
                    Text(verbatim: "Snapshot name")
                }
                Button {
                    run {
                        try checkSavedProgress()
                        try store.capture(name: trimmedName)
                        name = ""
                        names = try store.list()
                    }
                } label: {
                    Text(verbatim: "Save current state as…")
                }
                .disabled(trimmedName.isEmpty)

                ForEach(names, id: \.self) { name in
                    VStack(alignment: .leading, spacing: Theme.Space.small) {
                        Text(verbatim: name)
                        HStack(spacing: Theme.Space.regular) {
                            Button {
                                pendingChange = .snapshot(name)
                            } label: {
                                Text(verbatim: "Apply")
                            }
                            Button(role: .destructive) {
                                pendingDeletion = name
                            } label: {
                                Text(verbatim: "Delete")
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                }
            } header: {
                Text(verbatim: "Saved snapshots")
            }

            Section {
                Button {
                    pendingChange = .restore
                } label: {
                    Text(verbatim: "Restore my real profile")
                }
                .disabled(store.activeScenario == nil)
            }
        }
        .appFormStyle()
        .navigationTitle(Text(verbatim: "Test scenarios"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { run { names = try store.list() } }
        .alert(Text(verbatim: "The app will close. Open it again."),
               isPresented: isPresenting($pendingChange), presenting: pendingChange) { change in
            Button {
                apply(change)
            } label: {
                Text(verbatim: "Apply and close")
            }
            Button(role: .cancel) { } label: { Text(verbatim: "Cancel") }
        }
        .alert(Text(verbatim: "Delete snapshot?"), isPresented: isPresenting($pendingDeletion),
               presenting: pendingDeletion) { name in
            Button(role: .destructive) {
                run {
                    try store.delete(name: name)
                    names = try store.list()
                }
            } label: {
                Text(verbatim: "Delete")
            }
            Button(role: .cancel) { } label: { Text(verbatim: "Cancel") }
        } message: { name in
            Text(verbatim: name)
        }
        .alert(Text(verbatim: "Profile change failed"), isPresented: isPresenting($errorMessage)) {
            Button { } label: { Text(verbatim: "OK") }
        } message: {
            Text(verbatim: errorMessage ?? "")
        }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var dayLabel: String {
        let offset = overrides.dayOffset
        return offset == 0 ? "Real date" : "\(offset > 0 ? "+" : "")\(offset) d"
    }

    private func dayButton(_ title: String, by amount: Int) -> some View {
        let next = overrides.dayOffset + amount
        return Button {
            overrides.dayOffset = min(DebugOverrides.dayRange.upperBound, max(DebugOverrides.dayRange.lowerBound, next))
        } label: {
            Text(verbatim: title)
        }
        .buttonStyle(.borderless)
        .disabled(amount < 0 ? overrides.dayOffset == DebugOverrides.dayRange.lowerBound
                            : overrides.dayOffset == DebugOverrides.dayRange.upperBound)
    }

    private func isPresenting<Value>(_ value: Binding<Value?>) -> Binding<Bool> {
        Binding(get: { value.wrappedValue != nil }, set: { if !$0 { value.wrappedValue = nil } })
    }

    private func checkSavedProgress() throws {
        if let error = ProgressStore.shared.lastSaveError { throw error }
    }

    private func run(_ action: () throws -> Void) {
        do { try action() }
        catch { errorMessage = error.localizedDescription }
    }

    private func apply(_ change: Change) {
        run {
            if store.activeScenario == nil { try checkSavedProgress() }
            switch change {
            case .scenario(let scenario):
                try store.queueScenario(scenario, catalog: LessonStore.shared.libraryCatalog, overrides: overrides)
            case .snapshot(let name): try store.queueSnapshot(name: name)
            case .overrides:
                try checkSavedProgress()
                try store.queueOverrides(overrides)
            case .restore: try store.queueRestore()
            }
            exit(EXIT_SUCCESS)
        }
    }
}

@MainActor
private struct DebugTestMarker: ViewModifier {
    @State private var showingMenu = false

    private var label: String? {
        let store = DebugSnapshotStore.shared
        let overrides = store.overrides
        var parts = [store.activeScenario].compactMap { $0 }
        if overrides.access != .real { parts.append(overrides.access.rawValue.uppercased()) }
        if overrides.dayOffset != 0 {
            let sign = overrides.dayOffset > 0 ? "+" : ""
            parts.append("\(sign)\(overrides.dayOffset) d")
        }
        guard !parts.isEmpty else { return nil }
        return "TEST: " + parts.joined(separator: " · ")
    }

    func body(content: Content) -> some View {
        if let label {
            content
                .safeAreaInset(edge: .top, alignment: .trailing, spacing: 0) {
                    Button {
                        showingMenu = true
                    } label: {
                        Text(verbatim: label)
                            .font(Theme.meta)
                            .lineLimit(1)
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, Theme.Space.small)
                            .padding(.vertical, 4)
                            .background(Theme.surface, in: Capsule())
                            .overlay { Capsule().strokeBorder(Theme.orange) }
                            .frame(minHeight: Theme.Size.touch)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, Theme.Space.regular)
                }
                .sheet(isPresented: $showingMenu) {
                    NavigationStack {
                        DebugTestMenu()
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button {
                                        showingMenu = false
                                    } label: {
                                        Text(verbatim: "Done")
                                    }
                                }
                            }
                    }
                    .tint(Theme.ink)
                }
        } else {
            content
        }
    }
}

extension View {
    @MainActor
    func debugTestMarker() -> some View {
        modifier(DebugTestMarker())
    }
}
#endif
