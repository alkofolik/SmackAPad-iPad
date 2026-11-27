#if DEBUG
import Darwin
import SwiftUI

@MainActor
struct DebugDeveloperSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HardwareSectionHeader(title: "Developer")

            HardwareCard {
                NavigationLink {
                    DebugTestMenu()
                } label: {
                    HardwareRow(title: "Test scenarios") {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

@MainActor
struct DebugTestMenu: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("smackapad.debug.timingReadout") private var timingReadout = false
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
        VStack(spacing: 0) {
            ScreenTopBar {
                HardwareBackButton { dismiss() }
            } center: {
                Text(verbatim: "Test scenarios")
                    .font(Theme.screenTitle)
                    .foregroundStyle(Theme.ink)
            } trailing: {
                EmptyView()
            }
            .padding(.horizontal, Theme.Space.page)
            .padding(.vertical, Theme.Space.small)
            .background(Theme.chassis)

            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 1)

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.page) {
                    VStack(alignment: .leading, spacing: Theme.Space.small) {
                        HardwareSectionHeader(title: "Timing")
                        HardwareCard {
                            HardwareRow(title: "Timing readout") {
                                HardwareToggle(isOn: $timingReadout)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: Theme.Space.small) {
                        HardwareSectionHeader(title: "Built-in scenarios")
                        HardwareCard {
                            ForEach(Array(DebugScenario.allCases.enumerated()), id: \.element.id) { index, scenario in
                                if index > 0 {
                                    HardwareDivider()
                                }
                                Button {
                                    pendingChange = .scenario(scenario)
                                } label: {
                                    HardwareRow(title: scenario.rawValue) {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(Theme.secondary)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Text(verbatim: "Built-in scenarios use the purchase access and day shift selected below.")
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
                    }

                    VStack(alignment: .leading, spacing: Theme.Space.small) {
                        HardwareSectionHeader(title: "Overrides")
                        HardwareCard {
                            VStack(alignment: .leading, spacing: Theme.Space.small) {
                                Text(verbatim: "Purchase access")
                                    .font(Theme.control)
                                    .foregroundStyle(Theme.ink)
                                PlexSegmentedPicker(
                                    title: "Purchase access",
                                    selection: $overrides.access,
                                    options: DebugAccessOverride.allCases.map { ($0, $0.rawValue.capitalized) },
                                    fitsColumn: true,
                                    size: .compact
                                )
                            }
                            .padding(.horizontal, Theme.Space.regular)
                            .padding(.vertical, 12)

                            HardwareDivider()

                            HardwareRow(title: "Day shift") {
                                Text(verbatim: dayLabel)
                                    .font(Theme.meta.monospacedDigit())
                                    .foregroundStyle(Theme.secondary)
                            }

                            HardwareDivider()

                            HStack(spacing: Theme.Space.controlGap) {
                                dayButton("−1 day", by: -1)
                                dayButton("+1 day", by: 1)
                                dayButton("+7 days", by: 7)
                            }
                            .padding(.horizontal, Theme.Space.regular)
                            .padding(.vertical, 12)

                            HardwareDivider()

                            HStack(spacing: Theme.Space.controlGap) {
                                Button {
                                    overrides.dayOffset = 0
                                } label: {
                                    Text(verbatim: "Reset to real date")
                                        .font(Theme.control)
                                        .frame(maxWidth: .infinity, minHeight: Theme.Size.touch)
                                }
                                .buttonStyle(PadSecondaryButtonStyle())
                                .disabled(overrides.dayOffset == 0)

                                Button {
                                    pendingChange = .overrides
                                } label: {
                                    Text(verbatim: "Apply overrides")
                                        .font(Theme.control)
                                        .frame(maxWidth: .infinity, minHeight: Theme.Size.touch)
                                }
                                .buttonStyle(PadPrimaryButtonStyle())
                                .disabled(overrides == store.overrides)
                            }
                            .padding(.horizontal, Theme.Space.regular)
                            .padding(.vertical, 12)
                        }
                        Text(verbatim: "Applying overrides to your real profile starts a test copy. Saved snapshots keep their own overrides.")
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
                    }

                    VStack(alignment: .leading, spacing: Theme.Space.small) {
                        HardwareSectionHeader(title: "Saved snapshots")
                        HardwareCard {
                            VStack(alignment: .leading, spacing: Theme.Space.small) {
                                TextField(text: $name, prompt: Text(verbatim: "Snapshot name")) {
                                    Text(verbatim: "Snapshot name")
                                }
                                .font(Theme.control)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Theme.recessed, in: RoundedRectangle(cornerRadius: Theme.Radius.control))
                                .overlay {
                                    RoundedRectangle(cornerRadius: Theme.Radius.control)
                                        .strokeBorder(Theme.hairline, lineWidth: 1)
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
                                        .font(Theme.control)
                                        .frame(maxWidth: .infinity, minHeight: Theme.Size.touch)
                                }
                                .buttonStyle(PadSecondaryButtonStyle())
                                .disabled(trimmedName.isEmpty)
                            }
                            .padding(.horizontal, Theme.Space.regular)
                            .padding(.vertical, 12)

                            ForEach(names, id: \.self) { snapshotName in
                                HardwareDivider()
                                HardwareRow(title: snapshotName) {
                                    HStack(spacing: Theme.Space.small) {
                                        Button {
                                            pendingChange = .snapshot(snapshotName)
                                        } label: {
                                            Text(verbatim: "Apply")
                                                .font(Theme.meta)
                                                .frame(minHeight: 36)
                                        }
                                        .buttonStyle(PadSecondaryButtonStyle())

                                        HardwareIconButton(systemName: "trash", accessibilityLabel: "Delete", compact: true) {
                                            pendingDeletion = snapshotName
                                        }
                                    }
                                }
                            }
                        }
                    }

                    HardwareCard(padding: Theme.Space.regular) {
                        Button {
                            pendingChange = .restore
                        } label: {
                            Text(verbatim: "Restore my real profile")
                                .font(Theme.control)
                                .frame(maxWidth: .infinity, minHeight: Theme.Size.touch)
                        }
                        .buttonStyle(PadSecondaryButtonStyle())
                        .disabled(store.activeScenario == nil)
                    }
                }
                .frame(maxWidth: 700, alignment: .leading)
                .padding(Theme.Space.page)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Theme.chassis.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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
                .font(Theme.meta.monospacedDigit())
                .frame(maxWidth: .infinity, minHeight: Theme.Size.touch)
        }
        .buttonStyle(PadSecondaryButtonStyle())
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
            VStack(spacing: 0) {
                Button {
                    showingMenu = true
                } label: {
                    HStack(spacing: Theme.Space.tight) {
                        Circle()
                            .fill(Theme.orange)
                            .frame(width: 6, height: 6)
                        Text(verbatim: label)
                            .font(Theme.meta)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundStyle(Theme.ink)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, Theme.Space.regular)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(Theme.surface.ignoresSafeArea(edges: .top))
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Theme.hairline)
                            .frame(height: 1)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                content
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
