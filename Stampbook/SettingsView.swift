import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: StampbookStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("stampbook_haptics_enabled") private var hapticsEnabled: Bool = true

    @State private var showingDeleteConfirm = false
    @State private var sheetMode: CardSheetMode?

    var body: some View {
        NavigationStack {
            ZStack {
                SBTheme.backdrop.ignoresSafeArea()

                Form {
                    Section {
                        if purchases.isPro {
                            HStack {
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(SBTheme.reward)
                                Text("Stampbook Pro active")
                                    .foregroundStyle(SBTheme.ink)
                            }
                        } else {
                            Button {
                                sheetMode = .paywall
                            } label: {
                                HStack {
                                    Image(systemName: "star.fill").foregroundStyle(SBTheme.reward)
                                    Text("Unlock Stampbook Pro")
                                        .foregroundStyle(SBTheme.ink)
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(SBTheme.inkFaded)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowBackground(SBTheme.card)

                    if !purchases.isPro {
                        Section("Pro Features") {
                            Text("Unlock unlimited punch cards, photo attachments, and card archiving with Stampbook Pro.")
                                .font(.caption)
                                .foregroundStyle(SBTheme.inkFaded)
                        }
                        .listRowBackground(SBTheme.card)
                    }

                    Section("Cards") {
                        Button {
                            if store.canAddCard(isPro: purchases.isPro) {
                                sheetMode = .add
                            } else {
                                sheetMode = .paywall
                            }
                        } label: {
                            Label("Add Card", systemImage: "plus.circle")
                                .foregroundStyle(SBTheme.stamp)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("settingsAddCardButton")

                        if !purchases.isPro {
                            Text("\(store.activeCards.count)/\(StampbookStore.freeCardLimit) free cards used")
                                .font(.caption)
                                .foregroundStyle(SBTheme.inkFaded)
                        }

                        if !store.archivedCards.isEmpty {
                            Text("\(store.archivedCards.count) archived card\(store.archivedCards.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(SBTheme.inkFaded)
                        }
                    }
                    .listRowBackground(SBTheme.card)

                    Section("Preferences") {
                        Toggle(isOn: $hapticsEnabled) {
                            Label("Haptics", systemImage: "hand.tap.fill")
                                .foregroundStyle(SBTheme.ink)
                        }
                        .tint(SBTheme.stamp)
                        .onChange(of: hapticsEnabled) { _, newValue in
                            Haptics.enabled = newValue
                        }

                        Button {
                            Task { await purchases.restore() }
                        } label: {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                                .foregroundStyle(SBTheme.ink)
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(SBTheme.card)

                    Section("About") {
                        Link(destination: URL(string: "https://shimondeitel.github.io/stampbook-site/privacy.html")!) {
                            Label("Privacy Policy", systemImage: "hand.raised.fill")
                                .foregroundStyle(SBTheme.ink)
                        }
                        Link(destination: URL(string: "https://shimondeitel.github.io/stampbook-site/support.html")!) {
                            Label("Support", systemImage: "questionmark.circle")
                                .foregroundStyle(SBTheme.ink)
                        }
                        Link(destination: URL(string: "mailto:s0533495227@gmail.com")!) {
                            Label("Contact Support", systemImage: "envelope.fill")
                                .foregroundStyle(SBTheme.ink)
                        }
                        HStack {
                            Text("Version").foregroundStyle(SBTheme.ink)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundStyle(SBTheme.inkFaded)
                        }
                    }
                    .listRowBackground(SBTheme.card)

                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Delete All Data", systemImage: "trash.fill")
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(SBTheme.card)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(item: $sheetMode) { mode in
                switch mode {
                case .paywall:
                    PaywallView().environmentObject(purchases)
                case .add, .edit:
                    CardEditSheet(mode: mode) { name, category, colorHex, punches, reward, photo in
                        switch mode {
                        case .add:
                            store.addCard(name: name, category: category, colorHex: colorHex, punchesRequired: punches, rewardDescription: reward, photoData: photo, isPro: purchases.isPro)
                        case .edit(let card):
                            store.updateCard(card.id, name: name, category: category, colorHex: colorHex, punchesRequired: punches, rewardDescription: reward, photoData: photo)
                        case .paywall:
                            break
                        }
                    }
                }
            }
            .alert("Delete All Data?", isPresented: $showingDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    store.deleteAllData()
                }
            } message: {
                Text("This permanently removes every tracked card. This cannot be undone.")
            }
        }
        .dismissKeyboardOnTap()
    }
}

#Preview {
    SettingsView()
        .environmentObject(StampbookStore())
        .environmentObject(PurchaseManager())
}
