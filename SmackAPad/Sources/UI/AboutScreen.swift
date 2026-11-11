//
//  AboutScreen.swift
//  SmackAPad
//
//  About screen: app mark, version and build, links, font licences, copyright.
//  Used in Settings (pushed) and from the Home center pad (modal zoom).
//

import SwiftUI

private enum AboutLinks {
    // Populate from ticket 81 once the support and privacy pages are published.
    static let supportURL: URL? = nil
    static let privacyURL: URL? = nil
    static let copyrightAuthor = "[AUTHOR]"
}

public struct AboutDetailView: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showFontLicences = false

    var onDismiss: (() -> Void)? = nil

    public init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    private var versionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildString: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                VStack(spacing: 0) {
                    PadLogoGrid(neutralColor: Theme.ink, gap: 10, padRadius: 5)
                        .padding(24)
                        .frame(width: 132, height: 132)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 30))
                        .shadow(color: Theme.black.opacity(0.12), radius: 6, y: 2)

                    Text("SMACK-A-PAD")
                        .font(Theme.padTitle(size: 56))
                        .tracking(56 * 0.02)
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 28)

                    Text(settings.localized("Version %@ (build %@)", versionString, buildString))
                        .font(Theme.display(16).monospacedDigit())
                        .foregroundStyle(Theme.secondary)
                        .padding(.top, 8)

                    groupedList
                        .padding(.top, 36)

                    Text("© 2026 \(AboutLinks.copyrightAuthor)")
                        .font(Theme.display(14))
                        .foregroundStyle(Theme.secondary)
                        .padding(.top, 28)
                }
                .frame(maxWidth: 520)
                .padding(.top, 70)
                .padding(.horizontal, Theme.Space.page)
                .padding(.bottom, Theme.Space.page)
                .frame(maxWidth: .infinity)
            }

            BackButton {
                if let onDismiss { onDismiss() } else { dismiss() }
            }
            .padding(.top, Theme.Space.page)
            .padding(.leading, Theme.Space.page)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var groupedList: some View {
        let hasSupport = AboutLinks.supportURL != nil
        let hasPrivacy = AboutLinks.privacyURL != nil

        return VStack(spacing: 0) {
            if let supportURL = AboutLinks.supportURL {
                linkRow(
                    icon: "envelope",
                    title: settings.localized("Support"),
                    showTopDivider: false
                ) {
                    openURL(supportURL)
                }
            }

            if let privacyURL = AboutLinks.privacyURL {
                linkRow(
                    icon: "shield",
                    title: settings.localized("Privacy"),
                    showTopDivider: hasSupport
                ) {
                    openURL(privacyURL)
                }
            }

            fontLicencesRow(showTopDivider: hasSupport || hasPrivacy)
        }
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Theme.ink.opacity(0.10), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func linkRow(icon: String, title: String, showTopDivider: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            if showTopDivider {
                rowDivider
            }
            Button(action: action) {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 22)
                    Text(title)
                        .font(Theme.display(17))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.secondary)
                }
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 18)
                .frame(minHeight: 58)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func fontLicencesRow(showTopDivider: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if showTopDivider {
                rowDivider
            }
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    showFontLicences.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 22)
                    Text(settings.localized("Font licences"))
                        .font(Theme.display(17))
                    Spacer()
                    Image(systemName: showFontLicences ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.secondary)
                }
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 18)
                .frame(minHeight: 58)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(settings.localized(showFontLicences ? "Expanded" : "Collapsed"))

            if showFontLicences {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: "IBM Plex Sans · SIL OFL 1.1")
                    Text(verbatim: "Barlow Condensed · SIL OFL 1.1")
                }
                .font(Theme.display(14))
                .foregroundStyle(Theme.secondary)
                .padding(.leading, 54)
                .padding(.trailing, 18)
                .padding(.bottom, 16)
            }
        }
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Theme.ink.opacity(0.10))
            .frame(height: 1)
    }
}
