import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            CardListView()
                .tabItem {
                    Label("Home", systemImage: "rectangle.stack.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(SBTheme.stamp)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(SBTheme.card)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(StampbookStore())
        .environmentObject(PurchaseManager())
}
