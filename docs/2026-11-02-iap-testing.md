# In-app purchase testing

## Local StoreKit configuration

Open `SmackAPad.xcodeproj`, choose the shared **SmackAPad** scheme and run from Xcode on an iPad or simulator. **Edit Scheme → Run → Options → StoreKit Configuration** is already set to the root `Products.storekit` file. These are simulated purchases; no App Store Connect setup or real payment is needed.

The configuration contains non-consumables `cz.kju.SmackAPad.full`, `cz.kju.SmackAPad.pack.example` and `cz.kju.SmackAPad.bundle.all`. The example pack is a placeholder with no lessons and no in-app offer. The bundle is disabled in the product catalogue. Prices in this file are local test fixtures only; the application always displays StoreKit's `Product.displayPrice`.

Use **Debug → StoreKit → Manage Transactions** to inspect, delete, refund or revoke purchases. Delete all transactions to return to Free. StoreKit configuration settings control interrupted purchases, Ask to Buy and simulated errors. Restore does not erase ownership.

## Manual acceptance checklist (Jakub)

- [ ] Fresh install: all 25 Intro exercises and Path stage 1 (`L1-groove`) are free. Other lessons have a small orange purchase lock; the existing stage lock remains separate. Play next must also show the purchase sheet when its candidate requires payment.
- [ ] Buy Full from a paid lesson. Check the local price, purchase confirmation and immediate removal of purchase locks without restarting. Stage locks must remain and their existing manual unlock must not bypass a purchase lock.
- [ ] Cancel the purchase confirmation: no error message and no stuck loading state.
- [ ] Enable Ask to Buy, request Full and check “Purchase pending approval”. Approve it in Manage Transactions and verify access updates without restarting.
- [ ] Simulate product-loading and purchase errors. Check the message and Try again. Free lessons must remain playable. Retry after clearing the simulated error.
- [ ] Restore from both Settings and the purchase sheet, first without purchases (“No previous purchases found”), then with Full owned. Cancel the restore sign-in and verify loading ends silently.
- [ ] After buying Full, terminate the app, enable airplane mode and relaunch. Paid content stays purchased through cached StoreKit entitlements; unavailable product prices must not remove ownership.
- [ ] Refund/revoke Full in Manage Transactions. Purchase locks must return, including after foregrounding/relaunching.
- [ ] Check English/Czech, light/dark and both iPad orientations. No fixed price or hard-coded lesson total may appear.

Local transactions are deleted when the app is uninstalled. Test **restore after reinstall** and cross-device purchases with Sandbox/TestFlight, with local StoreKit configuration set to **None**. Also test real offline launch after a Sandbox purchase. These runtime checks were not performed by the coding agent.

## Future packs

Set a lesson's JSON `access` to `pack:<id>`; its non-consumable identifier is `cz.kju.SmackAPad.pack.<id>`. Pack IDs are discovered from lesson data and appear in Settings with StoreKit prices or Owned. `free` and `full` are the other supported values; missing metadata defaults to `full`, unknown values grant no access. Preserve `access` when projecting lessons into the library. Full unlock does not grant packs; an owned all-content bundle grants both Full and packs. Before offering that bundle, configure it in App Store Connect and enable `StoreManager.bundleEnabled`.

All existing bundled lessons, including the old Jersey/Footwork “Extensions” group, belong to the base library. There are currently no separate paid packs. The free selection is stored in the four lesson JSON files, not inferred by the purchase logic.

## App Store Connect setup (manual)

1. For app bundle ID `cz.kju.SmackAPad`, create **Non-Consumable** product `cz.kju.SmackAPad.full`.
2. Set its price, availability, English/Czech name and description, review screenshot and review information. The download price of the app stays Free.
3. Accept the **Paid Apps Agreement** and complete the required tax and banking details in App Store Connect.
4. Submit the Full product with the app version. Verify the visible Restore Purchases actions in both Settings and the purchase sheet using Sandbox/TestFlight.
5. Do not submit the placeholder `.pack.example` or enable `.bundle.all` yet. Create actual pack products and the bundle only when their content and commercial setup are ready.

StoreKit behavior reference: [Apple — Transaction](https://developer.apple.com/documentation/storekit/transaction), [currentEntitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements).

## Changed and new files

New: `Products.storekit`, `SmackAPad/Sources/Store/StoreManager.swift`, `SmackAPad/Sources/UI/PurchasesView.swift`, this guide.

Updated: `SmackAPad.xcodeproj/project.pbxproj`, `SmackAPad.xcodeproj/xcshareddata/xcschemes/SmackAPad.xcscheme`, `SmackAPad/Sources/App/SmackAPadApp.swift`, `SmackAPad/Sources/Data/LessonData.swift`, `SmackAPad/Sources/Progression/LibraryCatalog.swift`, `SmackAPad/Sources/UI/ContentView.swift`, `SmackAPad/Sources/UI/IntroScreen.swift`, `SmackAPad/Sources/UI/LibraryScreen.swift`, `SmackAPad/Sources/UI/SettingsView.swift`, all four lesson JSON files in `SmackAPad/Resources/Data/`, both `en.lproj` / `cs.lproj` localization catalogs, and ticket 32.
