import SwiftUI

@main
struct StampbookApp: App {
    @StateObject private var store = StampbookStore()
    @StateObject private var purchases = PurchaseManager()
    @AppStorage("stampbook_haptics_enabled") private var hapticsEnabled: Bool = true

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
                .preferredColorScheme(.light)
                .onAppear {
                    Haptics.enabled = hapticsEnabled
                }
        }
    }
}
