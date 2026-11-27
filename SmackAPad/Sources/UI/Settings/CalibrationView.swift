import AVFoundation
import SwiftUI

@MainActor
struct CalibrationView: View {
    @Environment(\.dismiss) private var dismiss
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

    private var inputOptions: [(String, String)] {
        var options: [(String, String)] = [
            ("touch", settings.localized("On-screen pads"))
        ]
        if midi.isKeyboardConnected {
            options.append(("keyboard", settings.localized("Hardware keyboard")))
        }
        for source in midi.sources {
            options.append((source.id, source.name))
        }
        return options
    }

    var body: some View {
        @Bindable var session = session
        VStack(spacing: 0) {
            ScreenTopBar {
                HardwareBackButton { dismiss() }
            } center: {
                Text(settings.localized("Timing calibration"))
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
                    // MARK: Input
                    VStack(alignment: .leading, spacing: Theme.Space.small) {
                        HardwareSectionHeader(title: settings.localized("Calibration input"))

                        HardwareCard {
                            PlexSegmentedPicker(
                                title: settings.localized("Calibration input"),
                                selection: $session.deviceID,
                                options: inputOptions,
                                fitsColumn: true,
                                size: .compact
                            )
                            .disabled(session.busy)
                            .padding(.horizontal, Theme.Space.regular)
                            .padding(.vertical, 12)

                            HardwareDivider()

                            HardwareRow(title: settings.localized("Saved offset")) {
                                Text(signed(session.savedOffset))
                                    .font(Theme.meta.monospacedDigit())
                                    .foregroundStyle(Theme.secondary)
                            }
                        }

                        Text("\(settings.localized("Calibrate touch separately; it differs from a controller.")) \(settings.localized("Listen to four clicks, then tap with each of the next ten. Follow the sound, not the screen."))")
                            .font(Theme.meta)
                            .foregroundStyle(Theme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // MARK: Progress & Pad
                    VStack(alignment: .leading, spacing: Theme.Space.small) {
                        HardwareSectionHeader(title: settings.localized("Calibration progress"))

                        HardwareCard(padding: Theme.Space.regular) {
                            VStack(alignment: .leading, spacing: Theme.Space.regular) {
                                HStack(spacing: Theme.Space.controlGap) {
                                    Text(status)
                                        .font(Theme.control)
                                        .foregroundStyle(Theme.ink)
                                        .accessibilityAddTraits(.updatesFrequently)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    if session.busy {
                                        Text("\(session.matchedClicks.count) / 10")
                                            .font(Theme.strong(14).monospacedDigit())
                                            .foregroundStyle(Theme.orange)
                                    }
                                }

                                calibrationStepStrip

                                if session.deviceID == "touch" {
                                    touchPadSurface
                                } else if session.deviceID == "keyboard" {
                                    Text(settings.localized("Press any mapped key with the click"))
                                        .font(Theme.control)
                                        .foregroundStyle(Theme.secondary)
                                        .frame(maxWidth: .infinity, minHeight: 100)
                                        .background(Theme.recessed, in: RoundedRectangle(cornerRadius: Theme.Radius.panel))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: Theme.Radius.panel)
                                                .strokeBorder(Theme.hairline, lineWidth: 1.5)
                                        }
                                }

                                if let result = session.result {
                                    VStack(spacing: 0) {
                                        HardwareDivider(inset: 0)
                                        resultRow(title: settings.localized("Saved offset"), value: signed(session.savedOffset))
                                        HardwareDivider(inset: 0)
                                        resultRow(title: settings.localized("Usable taps"), value: "\(result.usableTaps) / 10")
                                        HardwareDivider(inset: 0)
                                        resultRow(title: settings.localized("Timing spread"), value: "\(Int(result.spreadMilliseconds.rounded())) ms")
                                    }

                                    if result.discardedTaps > 0 {
                                        Text(settings.localized("Outlier taps were ignored"))
                                            .font(Theme.meta)
                                            .foregroundStyle(Theme.secondary)
                                    }
                                    Text(settings.localized("Play a lesson to check the result."))
                                        .font(Theme.meta)
                                        .foregroundStyle(Theme.secondary)
                                }

                                if let error = session.audioError {
                                    Text(error)
                                        .font(Theme.meta)
                                        .foregroundStyle(Theme.destructive)
                                }

                                if session.busy {
                                    Button(role: .cancel) { session.cancel() } label: {
                                        Text(settings.localized("Cancel calibration"))
                                            .font(Theme.control)
                                            .frame(maxWidth: .infinity, minHeight: Theme.Size.rowLarge)
                                    }
                                    .buttonStyle(PadSecondaryButtonStyle())
                                } else {
                                    Button { touching = false; session.start() } label: {
                                        Text(settings.localized("Start calibration"))
                                            .font(Theme.action)
                                            .frame(maxWidth: .infinity, minHeight: Theme.Size.rowLarge)
                                    }
                                    .buttonStyle(PadPrimaryButtonStyle())
                                }
                            }
                        }
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

    @ViewBuilder
    private var touchPadSurface: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.panel)
        VStack(spacing: Theme.Space.small) {
            Circle()
                .fill(touching ? Theme.orange : Theme.ledOff)
                .frame(width: 10, height: 10)
                .shadow(color: touching ? Theme.accentGlow : .clear, radius: touching ? 6 : 0)

            Text(settings.localized("Tap with the click"))
                .font(Theme.rowTitle)
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, minHeight: 164)
        .background {
            shape
                .fill(touching ? Theme.surfaceElevated : Theme.recessed)
                .overlay {
                    shape
                        .fill(Theme.orange.opacity(touching ? 0.24 : 0))
                }
                .overlay {
                    shape.strokeBorder(touching ? Theme.orange : Theme.hairline, lineWidth: 1.5)
                }
        }
        .shadow(color: touching ? Theme.accentGlow : .clear, radius: touching ? 10 : 0)
        .scaleEffect(touching ? 0.985 : 1)
        .animation(Theme.Motion.padFlash, value: touching)
        .contentShape(shape)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !touching else { return }
                    touching = true
                    session.touch()
                }
                .onEnded { _ in
                    touching = false
                }
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { session.touch() }
    }

    private var calibrationStepStrip: some View {
        let isCountIn = session.phase == .countIn
        let isMeasuring = session.phase == .measuring
        let isDone = session.phase == .completed
        let countInProgress = isCountIn ? max(0, min(4, session.clickNumber)) : (isMeasuring || isDone ? 4 : 0)
        let measuredProgress = isMeasuring ? max(0, min(10, session.clickNumber)) : (isDone ? 10 : 0)

        return HStack(spacing: Theme.Space.controlGap) {
            // 4 count-in clicks
            HStack(spacing: 4) {
                ForEach(1...4, id: \.self) { step in
                    let lit = step <= countInProgress
                    RoundedRectangle(cornerRadius: 2)
                        .fill(lit ? Theme.orange.opacity(isCountIn && step == countInProgress ? 1 : 0.55) : Theme.ledOff)
                        .frame(height: 6)
                }
            }
            .frame(maxWidth: 96)

            Rectangle()
                .fill(Theme.hairline)
                .frame(width: 1, height: 10)

            // 10 measured taps
            HStack(spacing: 4) {
                ForEach(1...10, id: \.self) { step in
                    let recorded = step <= session.matchedClicks.count
                    let current = isMeasuring && step == measuredProgress
                    RoundedRectangle(cornerRadius: 2)
                        .fill((recorded || current) ? Theme.orange : Theme.ledOff)
                        .frame(height: 6)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityHidden(true)
    }

    private func resultRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(Theme.control)
                .foregroundStyle(Theme.ink)
            Spacer()
            Text(value)
                .font(Theme.meta.monospacedDigit())
                .foregroundStyle(Theme.secondary)
        }
        .padding(.vertical, 10)
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
