import CoreAudioKit
import SwiftUI

@MainActor
struct MIDISettingsView: View {
    var body: some View {
        SettingsView()
    }
}

@MainActor
struct MIDILearnView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(MIDIInput.self) private var midi
    @Environment(\.dismiss) private var dismiss
    @State private var padCount = 16
    @State private var profileName = ""

    private var trimmedName: String { profileName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var nameExists: Bool { settings.profile(named: trimmedName) != nil }

    var body: some View {
        NavigationStack {
            Form {
                Group {
                    Section {
                        TextField(settings.localized("Profile name"), text: $profileName)
                            .font(Theme.control)
                        Picker(settings.localized("Pad count"), selection: $padCount) {
                            Text(settings.localized("8 pads")).tag(8)
                            Text(settings.localized("16 pads")).tag(16)
                        }
                        .pickerStyle(.segmented)
                        .disabled(midi.isLearning)

                        if nameExists {
                            Text(settings.localized("This profile name is already in use."))
                                .font(Theme.meta)
                                .foregroundStyle(Theme.markWrong)
                        }
                    } header: { SectionHeader(title: settings.localized("New controller profile")) }

                    Section {
                        if midi.isLearning {
                            LabeledContent(settings.localized("Learned pads"), value: "\(midi.learnedNotes.count) / \(padCount)")
                                .font(Theme.control)

                            if midi.learningComplete {
                                Text(settings.localized("All pads learned. Save the profile to use it."))
                                    .font(Theme.meta)
                                    .foregroundStyle(Theme.markCorrect)
                            } else {
                                Text(settings.localized("Press the highlighted pad on your controller."))
                                    .font(Theme.meta)
                            }

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Space.small), count: 4), spacing: Theme.Space.small) {
                                ForEach(0..<padCount, id: \.self) { slot in
                                    VStack(spacing: Theme.Space.small) {
                                        Text(settings.localized("Pad %lld", slot + 1))
                                            .font(Theme.control)
                                        if midi.learnedNotes.indices.contains(slot) {
                                            Text(midi.learnedNotes[slot].formatted())
                                                .font(Theme.meta)
                                                .monospacedDigit()
                                        } else {
                                            Text("—")
                                                .font(Theme.meta)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 64)
                                    .background(slot == midi.learnedNotes.count ? Theme.orange.opacity(0.3) : Theme.surface,
                                                in: RoundedRectangle(cornerRadius: Theme.Size.blockRadius))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.Size.blockRadius)
                                            .stroke(slot == midi.learnedNotes.count ? Theme.orange : Color.clear, lineWidth: Theme.Size.border)
                                    )
                                    .accessibilityAddTraits(slot == midi.learnedNotes.count ? .isSelected : [])
                                }
                            }

                            if midi.learningNotice == "duplicateNote" {
                                Text(settings.localized("That note is already assigned. Press a different pad."))
                                    .font(Theme.meta)
                                    .foregroundStyle(Theme.markWrong)
                            }

                            Button(settings.localized("Start again")) {
                                midi.startLearning(padCount: padCount)
                            }
                            .font(Theme.control)
                            .frame(minHeight: Theme.Size.touch)
                        } else {
                            Button(settings.localized("Start MIDI learn")) {
                                midi.startLearning(padCount: padCount)
                            }
                            .font(Theme.control)
                            .frame(minHeight: Theme.Size.touch)
                            .disabled(midi.sources.isEmpty)

                            if midi.sources.isEmpty {
                                Text(settings.localized("Connect a MIDI controller before starting."))
                                    .font(Theme.meta)
                                    .foregroundStyle(Theme.secondary)
                            }
                        }
                    } header: {
                        SectionHeader(title: settings.localized("MIDI LEARN"))
                    } footer: {
                        Text(settings.localized("Press each physical pad once, left to right, starting with the top row. Use the same controller and MIDI channel throughout. In 8-pad mode, positions are slots 1–8; sounds follow the lesson."))
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
                    }
                }
                .listRowBackground(Theme.surface)
                .listRowInsets(EdgeInsets(top: Theme.Space.small, leading: Theme.Space.regular,
                                         bottom: Theme.Space.small, trailing: Theme.Space.regular))
            }
            .appFormStyle()
            .navigationTitle(settings.localized("MIDI learn"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { ScreenHeader(title: settings.localized("MIDI learn")) }
                ToolbarItem(placement: .cancellationAction) {
                    Button(settings.localized("Cancel")) { dismiss() }
                        .font(Theme.control)
                        .frame(minHeight: Theme.Size.touch)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(settings.localized("Save")) {
                        if midi.saveLearnedProfile(name: profileName) { dismiss() }
                    }
                    .font(Theme.control)
                    .frame(minHeight: Theme.Size.touch)
                    .disabled(!midi.learningComplete || trimmedName.isEmpty || nameExists)
                }
            }
            .onDisappear { midi.cancelLearning() }
        }
    }
}

struct TouchPad: View {
    let number: Int
    let sound: LocalizedStringKey
    let isActive: Bool
    let onPress: (Bool) -> Void
    @State private var isTouching = false

    var body: some View {
        VStack(spacing: Theme.Space.small) {
            Text("Pad \(number)")
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
            Text(sound)
                .font(Theme.rowTitle)
                .foregroundStyle(isActive ? Theme.orange : Theme.ink)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .background(isActive ? Theme.orange.opacity(0.3) : Theme.surface,
                    in: RoundedRectangle(cornerRadius: Theme.Size.blockRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Size.blockRadius)
                .stroke(isActive ? Theme.orange : Color.clear, lineWidth: Theme.Size.border)
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isTouching else { return }
                    isTouching = true
                    onPress(true)
                }
                .onEnded { _ in release() }
        )
        .onDisappear { release() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onPress(true); onPress(false) }
    }

    private func release() {
        guard isTouching else { return }
        isTouching = false
        onPress(false)
    }
}

enum PadNames {
    // Sound names for pad indices specified by the lesson layout.
    static func name(for padIndex: Int) -> LocalizedStringKey {
        switch padIndex {
        case 2: return "Crash"
        case 3: return "Ride"
        case 7: return "Open hi-hat"
        case 9: return "Clap"
        case 10: return "Rim"
        case 11: return "Hi-hat R"
        case 12: return "Kick L"
        case 13: return "Snare L"
        default: return "Pad \(padIndex + 1)"
        }
    }
}

/// Apple's pairing screen (CABTMIDICentralViewController) is a UIKit table controller.
/// It is presented from UIKit on the topmost controller, with the iOS 27 crash workaround below.
@MainActor
enum BluetoothMIDIPresenter {
    static func present() {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let window = scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first,
              var top = window.rootViewController else { return }
        while let next = top.presentedViewController, !next.isBeingDismissed { top = next }
        let central = CABTMIDICentralViewController()
        // iOS 27 bug (Apple forums thread 850584, FB25301268): the controller's own
        // loadView builds its table with a NaN height and crashes. Supplying the table
        // first skips that code; viewDidLoad then starts Bluetooth discovery as usual.
        // Undocumented workaround from Apple DTS; remove once the minimum OS has the fix.
        if #available(iOS 27, *) {
            central.tableView = UITableView(frame: .zero, style: .grouped)
            central.viewDidLoad()
        }
        central.title = SettingsManager.shared.localized("Bluetooth MIDI")
        let navigation = UINavigationController(rootViewController: central)
        navigation.modalPresentationStyle = .formSheet
        central.navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [weak navigation] _ in navigation?.dismiss(animated: true) })
        top.present(navigation, animated: true)
    }
}

#Preview {
    SettingsView()
        .environment(SettingsManager.shared)
        .environment(MIDIInput(settings: .shared))
}
