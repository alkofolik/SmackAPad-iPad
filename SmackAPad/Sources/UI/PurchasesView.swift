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

/// The same purchase controls serve Settings and the lesson paywall.
@MainActor
struct PurchaseControls: View {
    @Environment(StoreManager.self) private var store
    @Environment(SettingsManager.self) private var settings
    let access: String

    private var product: Product? {
        store.productID(for: access).flatMap { store.products[$0] }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            if let product {
                Button {
                    Task { await store.purchase(product) }
                } label: {
                    Text(settings.localized("Unlock · %@", product.displayPrice))
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
                Text(settings.localized("Restore Purchases"))
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
    private var title: String {
        guard access != "full", let id = store.productID(for: access), let product = store.products[id] else {
            return settings.localized("Full unlock")
        }
        return product.displayName
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.page) {
                    Text(title).font(Theme.screenTitle)
                    VStack(alignment: .leading, spacing: Theme.Space.regular) {
                        Text(settings.localized("%lld lessons", contents.lessonCount))
                        Text(settings.localized("Lessons across %lld genres", contents.genreCount))
                            .font(Theme.meta).foregroundStyle(Theme.secondary)
                        Text(settings.localized("One-time payment"))
                        Text(settings.localized("No subscription"))
                    }
                    .font(Theme.control)
                    Text(settings.localized("Stage progress still follows your stars."))
                        .font(Theme.meta).foregroundStyle(Theme.secondary)
                    if owned {
                        Text(settings.localized("Owned")).font(Theme.rowTitle)
                    } else {
                        PurchaseControls(access: access)
                    }
                }
                .frame(maxWidth: 520, alignment: .leading)
                .padding(Theme.Space.page).frame(maxWidth: .infinity)
            }
            .calmChassisBackground().foregroundStyle(Theme.ink).tint(Theme.ink)
            .toolbar {
                PadToolbarItem(placement: .cancellationAction) {
                    Button {
                        if let onDismiss { onDismiss() } else { dismiss() }
                    } label: {
                        Image(systemName: "xmark").frame(minWidth: Theme.Size.touch, minHeight: Theme.Size.touch)
                    }
                    .buttonStyle(PadIconButtonStyle())
                    .accessibilityLabel(settings.localized("Close"))
                }
            }
        }
        .interactiveDismissDisabled(store.busy)
        .task {
            store.message = nil
            if store.products.isEmpty { await store.loadProducts() }
        }
        .onChange(of: owned) { _, value in if value { dismiss() } }
    }
}
