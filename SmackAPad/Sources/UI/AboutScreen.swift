//
//  AboutScreen.swift
//  SmackAPad
//
//  About screen: app title, version, font credits.
//  Used in Settings (pushed) and from the Home center pad (modal zoom).
//

import SwiftUI

public struct AboutDetailView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var showsDoneButton: Bool = false
    var onDismiss: (() -> Void)? = nil

    public init(showsDoneButton: Bool = false, onDismiss: (() -> Void)? = nil) {
        self.showsDoneButton = showsDoneButton
        self.onDismiss = onDismiss
    }

    public var body: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            Text("Smack-a-Pad")
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.ink)
            Text(settings.localized("Version %@", version))
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
            Divider()
            Text(settings.localized("Font IBM Plex Sans, SIL OFL 1.1"))
                .font(Theme.meta)
                .foregroundStyle(Theme.secondary)
            Spacer()
        }
        .padding(Theme.Space.page)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(settings.localized("About"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) { ScreenHeader(title: settings.localized("About")) }
            if showsDoneButton || onDismiss != nil {
                ToolbarItem(placement: .confirmationAction) {
                    Button(settings.localized("Done")) {
                        if let onDismiss { onDismiss() } else { dismiss() }
                    }
                    .font(Theme.control)
                    .frame(minHeight: Theme.Size.touch)
                }
            }
        }
    }
}
