import StoreKit
import SwiftUI

/// Only the lessons unlocked by this purchase, excluding already-free content.
struct PurchaseContents {
    let lessons: [Lesson]

    init(lessons: [Lesson], access: String) {
        self.lessons = lessons.filter { $0.access == access }
    }

    var lessonCount: Int { lessons.count }
    var genreCount: Int { Set(lessons.map(\.genre).filter { !$0.isEmpty }).count }
}

/// The same purchase controls serve Settings pack rows.
@MainActor
struct PurchaseControls: View {
    @Environment(StoreManager.self) private var store
    @Environment(SettingsManager.self) private var settings
    let access: String

    private var product: Product? {
        store.productID(for: access).flatMap { store.products[$0] }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.controlGap) {
            if let product {
                Button {
                    Task { await store.purchase(product) }
                } label: {
                    Text(settings.localized("Unlock for %@", product.displayPrice))
                        .font(Theme.rowTitle)
                        .frame(maxWidth: .infinity, minHeight: Theme.Size.control)
                }
                .buttonStyle(PadPrimaryButtonStyle())
                .disabled(store.busy || !store.entitlementsLoaded)
            }
            if store.loadingProducts || store.busy || !store.entitlementsLoaded {
                ProgressView().tint(Theme.ink).frame(maxWidth: .infinity)
                    .accessibilityLabel(settings.localized("Loading purchases"))
            }
            if store.productLoadFailed || (product == nil && !store.loadingProducts) {
                Text(settings.localized("Purchases are unavailable. Free lessons still work."))
                    .font(Theme.meta)
                Button { Task { await store.loadProducts() } } label: {
                    Text(settings.localized("Try again"))
                        .font(Theme.control)
                        .frame(minHeight: Theme.Size.touch)
                }
                .buttonStyle(PadSecondaryButtonStyle())
                .disabled(store.loadingProducts || store.busy)
            }
            Button { Task { await store.restore() } } label: {
                Text(settings.localized("Restore purchase"))
                    .font(Theme.meta)
                    .frame(minHeight: Theme.Size.touch)
            }
            .buttonStyle(PadSecondaryButtonStyle())
            .disabled(store.busy)
            if let message = store.message {
                Text(settings.localized(message)).font(Theme.meta)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
    }
}

@MainActor
struct PurchasesSection: View {
    @Environment(StoreManager.self) private var store
    @Environment(SettingsManager.self) private var settings
    @State private var showingPurchase = false

    var body: some View {
        Section {
            LabeledContent(settings.localized("Access"), value: settings.localized(store.hasFullAccess ? "Full" : "Free"))
                .font(Theme.control)
            if !store.hasFullAccess {
                Button { showingPurchase = true } label: {
                    Text(settings.localized("Full unlock"))
                        .font(Theme.control)
                        .frame(minHeight: Theme.Size.touch)
                }
                .buttonStyle(PadSecondaryButtonStyle())
            }
            ForEach(store.packIDs, id: \.self) { id in
                let productID = StoreManager.productPrefix + ".pack." + id
                if store.ownedProductIDs.contains(productID) || store.ownedProductIDs.contains(StoreManager.bundleID) {
                    LabeledContent(store.products[productID]?.displayName ?? id, value: settings.localized("Owned"))
                } else {
                    VStack(alignment: .leading, spacing: Theme.Space.small) {
                        Text(store.products[productID]?.displayName ?? id).font(Theme.rowTitle)
                        PurchaseControls(access: "pack:" + id)
                    }
                }
            }
            Button { Task { await store.restore() } } label: {
                Text(settings.localized("Restore Purchases"))
                    .font(Theme.control)
                    .frame(minHeight: Theme.Size.touch)
            }
            .disabled(store.busy)
            .buttonStyle(PadSecondaryButtonStyle())
            if store.busy { ProgressView().tint(Theme.ink) }
            if let message = store.message { Text(settings.localized(message)).font(Theme.meta) }
        } header: {
            SectionHeader(title: settings.localized("Purchases"))
        }
        .sheet(isPresented: $showingPurchase) { PurchaseSheet() }
    }
}

@MainActor
struct PurchaseSheet: View {
    @Environment(StoreManager.self) private var store
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressionManager.self) private var progression
    @Environment(\.dismiss) private var dismiss
    var access = "full"
    var onDismiss: (() -> Void)? = nil

    private var owned: Bool {
        if access == "full" { return store.hasFullAccess }
        return store.ownedProductIDs.contains(StoreManager.bundleID)
            || store.productID(for: access).map { store.ownedProductIDs.contains($0) } == true
    }

    private var contents: PurchaseContents {
        PurchaseContents(lessons: LessonStore.shared.lessons, access: access)
    }

    private var product: Product? {
        store.productID(for: access).flatMap { store.products[$0] }
    }

    private var stageCount: Int {
        progression.catalog.stages.count
    }

    private var headlineText: String {
        guard access != "full", let id = store.productID(for: access), let product = store.products[id] else {
            return settings.localized("paywall.title")
        }
        return product.displayName.uppercased()
    }

    private var extraLessonsSubtitle: String {
        let count = contents.lessonCount
        switch settings.languagePreference {
        case .czech:
            if count == 1 { return "lekce navíc" }
            if count >= 2 && count <= 4 { return "lekce navíc" }
            return "lekcí navíc"
        case .english:
            return count == 1 ? "extra lesson" : "extra lessons"
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let isLandscapeLayout = geometry.size.width >= 960
            Group {
                if isLandscapeLayout {
                    HStack(spacing: 40) {
                        heroPanel(compact: false)
                            .frame(width: 500)
                            .frame(maxHeight: .infinity)

                        VStack(alignment: .leading, spacing: 0) {
                            benefitsStack(spacing: 30)
                                .padding(.top, 96)
                            Spacer(minLength: 24)
                            actionsBlock
                                .padding(.bottom, 40)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .padding(.trailing, 40)
                    }
                    .padding(Theme.Space.page)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 28) {
                            heroPanel(compact: true)
                                .frame(maxWidth: .infinity)
                            benefitsStack(spacing: 22)
                                .padding(.horizontal, 8)
                            actionsBlock
                                .padding(.horizontal, 8)
                        }
                        .padding(Theme.Space.page)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background.ignoresSafeArea())
        }
        .foregroundStyle(Theme.ink)
        .tint(Theme.ink)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .interactiveDismissDisabled(store.busy)
        .task {
            store.message = nil
            if store.products.isEmpty { await store.loadProducts() }
        }
    }

    private func heroPanel(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            BackButton(onDark: true) {
                if let onDismiss { onDismiss() } else { dismiss() }
            }

            if compact {
                Spacer(minLength: 28)
            } else {
                Spacer()
            }

            PadLogoGrid(neutralColor: Theme.white, gap: compact ? 10 : 12, padRadius: 6)
                .frame(width: compact ? 96 : 120, height: compact ? 96 : 120)

            Text(headlineText)
                .font(Theme.padTitle(size: compact ? 64 : 76))
                .lineSpacing(compact ? -4 : -6)
                .foregroundStyle(Theme.white)
                .padding(.top, compact ? 24 : 32)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(contents.lessonCount)")
                    .font(Theme.boldDisplay(compact ? 38 : 44).monospacedDigit())
                    .foregroundStyle(Theme.orange)
                Text(extraLessonsSubtitle)
                    .font(Theme.display(compact ? 18 : 20))
                    .foregroundStyle(Color(red: 179/255, green: 173/255, blue: 162/255))
            }
            .padding(.top, 16)
        }
        .padding(compact ? 28 : 40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.black, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Theme.white.opacity(0.10), lineWidth: 1)
        }
    }

    private func benefitsStack(spacing: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            benefitRow(
                icon: "books.vertical",
                title: settings.localized("Whole library"),
                subtitle: settings.localized("All %lld Path stages and lessons across %lld genres", stageCount, contents.genreCount)
            )
            benefitRow(
                icon: "creditcard",
                title: settings.localized("One-time payment"),
                subtitle: settings.localized("No subscription")
            )
            benefitRow(
                icon: "star",
                title: settings.localized("Progress by stars"),
                subtitle: settings.localized("More stages unlock as you collect stars")
            )
        }
    }

    private func benefitRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.surface)
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Theme.ink)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.strong(20))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(Theme.display(15))
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var actionsBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            if owned {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.orange)
                    Text(settings.localized("Purchased"))
                        .font(Theme.boldDisplay(24))
                        .foregroundStyle(Theme.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(Theme.black, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Theme.white.opacity(0.12), lineWidth: 1)
                }
            } else {
                if let product {
                    Button {
                        Task { await store.purchase(product) }
                    } label: {
                        Text(settings.localized("Unlock for %@", product.displayPrice))
                            .font(Theme.boldDisplay(24))
                            .foregroundStyle(Theme.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .background(Theme.orange, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(BadgeTileButtonStyle())
                    .disabled(store.busy || !store.entitlementsLoaded)
                }

                if store.loadingProducts || store.busy || !store.entitlementsLoaded {
                    ProgressView()
                        .tint(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(settings.localized("Loading purchases"))
                }

                if store.productLoadFailed || (product == nil && !store.loadingProducts) {
                    Text(settings.localized("Purchases are unavailable. Free lessons still work."))
                        .font(Theme.meta)
                        .foregroundStyle(Theme.secondary)
                    Button {
                        Task { await store.loadProducts() }
                    } label: {
                        Text(settings.localized("Try again"))
                            .font(Theme.strong(17))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Theme.ink.opacity(0.28), lineWidth: 1.5)
                            }
                    }
                    .buttonStyle(.plain)
                    .disabled(store.loadingProducts || store.busy)
                }

                Button {
                    Task { await store.restore() }
                } label: {
                    Text(settings.localized("Restore purchase"))
                        .font(Theme.strong(17))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Theme.ink.opacity(0.28), lineWidth: 1.5)
                        }
                }
                .buttonStyle(.plain)
                .disabled(store.busy)

                if let message = store.message {
                    Text(settings.localized(message))
                        .font(Theme.meta)
                        .foregroundStyle(Theme.secondary)
                        .accessibilityAddTraits(.updatesFrequently)
                }
            }
        }
    }
}
