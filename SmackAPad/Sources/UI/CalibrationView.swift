import AVFoundation
import SwiftUI

@MainActor
struct CalibrationView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var session: CalibrationSession
    @State private var touching = false
    let settings: SettingsManager
    let midi: MIDIInput

    init(settings: SettingsManager, midi: MIDIInput) {
        self.settings = settings
        self.midi = midi
        _session = State(initialValue: CalibrationSession(settings: settings, midi: midi))
    }

    var body: some View {
        @Bindable var session = session
        Form {
            Group {
                Section {
                    Picker(settings.localized("Calibration input"), selection: $session.deviceID) {
                        Text(settings.localized("On-screen pads")).tag("touch")
                        if midi.isKeyboardConnected {
                            Text(settings.localized("Hardware keyboard")).tag("keyboard")
                        }
                        ForEach(midi.sources) { source in Text(source.name).font(Theme.rowTitle).tag(source.id) }
                    }
                    .disabled(session.busy)
                    LabeledContent(settings.localized("Saved offset"), value: signed(session.savedOffset))
                    Text(settings.localized("Calibrate touch separately; it differs from a controller."))
                        .font(Theme.meta).foregroundStyle(Theme.secondary)
                    Text(settings.localized("Listen to four clicks, then tap with each of the next ten. Follow the sound, not the screen."))
                        .font(Theme.meta).foregroundStyle(Theme.secondary)
                } header: { SectionHeader(title: settings.localized("Calibration input")) }

                Section {
                    Text(status).font(Theme.control).accessibilityAddTraits(.updatesFrequently)
                    if session.busy {
                        ProgressView(value: Double(session.matchedClicks.count), total: 10)
                            .tint(Theme.orange)
                        LabeledContent(settings.localized("Recorded taps"), value: "\(session.matchedClicks.count) / 10")
                    }
                    if session.deviceID == "touch" {
                        Text(settings.localized("Tap with the click"))
                            .font(Theme.rowTitle)
                            .frame(maxWidth: .infinity, minHeight: 140)
                            .background {
                                RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius)
                                    .fill(touching ? Theme.activeFill : Theme.Skin.Pad.fill)
                                    .overlay {
                                        SkinBevel(
                                            radius: Theme.Skin.Pad.radius,
                                            highlight: Theme.Skin.Pad.highlight,
                                            shade: Theme.Skin.Pad.shade,
                                            top: Theme.Skin.Pad.topBevel,
                                            bottom: Theme.Skin.Pad.bottomBevel
                                        )
                                    }
                                    .overlay {
                                        RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius)
                                            .strokeBorder(touching ? Theme.orange : Theme.hairline,
                                                          lineWidth: touching ? Theme.Size.border : 1)
                                    }
                                    .shadow(color: Theme.black.opacity(0.08), radius: 2, y: 2)
                            }
                            .contentShape(RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius))
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    guard !touching else { return }
                                    touching = true
                                    session.touch()
                                }
                                .onEnded { _ in touching = false })
                            .accessibilityAddTraits(.isButton)
                            .accessibilityAction { session.touch() }
                    } else if session.deviceID == "keyboard" {
                        Text(settings.localized("Press any mapped key with the click"))
                            .font(Theme.rowTitle)
                            .frame(maxWidth: .infinity, minHeight: 80)
                            .background {
                                RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius)
                                    .fill(Theme.Skin.Pad.fill)
                                    .overlay {
                                        SkinBevel(
                                            radius: Theme.Skin.Pad.radius,
                                            highlight: Theme.Skin.Pad.highlight,
                                            shade: Theme.Skin.Pad.shade,
                                            top: Theme.Skin.Pad.topBevel,
                                            bottom: Theme.Skin.Pad.bottomBevel
                                        )
                                    }
                                    .overlay {
                                        RoundedRectangle(cornerRadius: Theme.Skin.Pad.radius)
                                            .strokeBorder(Theme.hairline, lineWidth: 1)
                                    }
                                    .shadow(color: Theme.black.opacity(0.08), radius: 2, y: 2)
                            }
                    }
                    if let result = session.result {
                        LabeledContent(settings.localized("Saved offset"), value: signed(session.savedOffset))
                        LabeledContent(settings.localized("Usable taps"), value: "\(result.usableTaps) / 10")
                        LabeledContent(settings.localized("Timing spread"), value: "\(Int(result.spreadMilliseconds.rounded())) ms")
                        if result.discardedTaps > 0 { Text(settings.localized("Outlier taps were ignored")).font(Theme.meta) }
                        Text(settings.localized("Play a lesson to check the result.")).font(Theme.meta)
                    }
                    if let error = session.audioError { Text(error).font(Theme.meta).foregroundStyle(Theme.secondary) }
                    if session.busy {
                        Button(role: .cancel) { session.cancel() } label: {
                            Text(settings.localized("Cancel calibration"))
                                .font(Theme.control)
                                .frame(minHeight: Theme.Size.touch)
                        }
                        .buttonStyle(PadSecondaryButtonStyle())
                    } else {
                        Button { touching = false; session.start() } label: {
                            Text(settings.localized("Start calibration"))
                                .font(Theme.control)
                                .frame(minHeight: Theme.Size.touch)
                        }
                        .buttonStyle(PadPrimaryButtonStyle())
                    }
                } header: { SectionHeader(title: settings.localized("Calibration progress")) }
            }
            .listRowBackground(Theme.surface)
            .listRowInsets(EdgeInsets(top: Theme.Space.small, leading: Theme.Space.regular,
                                     bottom: Theme.Space.small, trailing: Theme.Space.regular))
        }
        .appFormStyle()
        .navigationTitle(settings.localized("Timing calibration"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { ScreenHeader(title: settings.localized("Timing calibration")) }
        }
        .onAppear { session.attach() }
        .onDisappear { session.close() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { session.refreshOutputRoute() }
            else { session.cancel() }
        }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .receive(on: RunLoop.main)) { _ in
                session.refreshOutputRoute()
            }
        .onChange(of: midi.sources) { _, sources in
            if !session.busy, session.deviceID != "touch", session.deviceID != "keyboard", !sources.contains(where: { $0.id == session.deviceID }) {
                session.deviceID = "touch"
            }
        }
        .onChange(of: midi.isKeyboardConnected) { _, connected in
            if !session.busy, session.deviceID == "keyboard", !connected {
                session.deviceID = "touch"
            }
        }
    }

    private func signed(_ value: Double) -> String { String(format: "%+.0f ms", value) }

    private var status: String {
        switch session.phase {
        case .idle: return settings.localized("Ready. Choose an input and start.")
        case .preparing: return settings.localized("Preparing audio…")
        case .countIn: return settings.localized("Listen first · %lld / 4", max(1, session.clickNumber))
        case .measuring: return settings.localized("Tap with the sound · %lld / 10", session.clickNumber)
        case .completed: return settings.localized("Calibration saved")
        case .cancelled: return settings.localized("Calibration cancelled. Previous settings kept.")
        case .failed:
            switch session.failure {
            case .tooFewTaps: return settings.localized("Too few taps. Record at least six of ten clicks. Previous settings kept.")
            case .unevenTaps: return settings.localized("Taps were too uneven. Follow the sound and try again. Previous settings kept.")
            case .audioClockChanged: return settings.localized("Audio timing changed or is not ready. Try again. Previous settings kept.")
            case nil: return settings.localized("Audio could not start. Try again. Previous settings kept.")
            }
        }
    }
}
