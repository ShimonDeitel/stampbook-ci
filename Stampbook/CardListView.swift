import SwiftUI

struct CardListView: View {
    @EnvironmentObject private var store: StampbookStore
    @EnvironmentObject private var purchases: PurchaseManager

    @State private var sheetMode: CardSheetMode?
    @State private var detailCard: Card?
    @State private var deletingCard: Card?
    @State private var showConfetti = false

    private var sortedCards: [Card] {
        store.activeCards.sorted { $0.dateCreated > $1.dateCreated }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SBTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        if store.activeCards.isEmpty {
                            emptyState
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                                ForEach(sortedCards) { card in
                                    StampCardTile(card: card) {
                                        detailCard = card
                                    } onPunch: {
                                        punch(card)
                                    }
                                }
                            }
                            .padding(.horizontal, 18)

                            if !purchases.isPro {
                                Text("Free plan: \(store.activeCards.count)/\(StampbookStore.freeCardLimit) cards used")
                                    .font(.caption)
                                    .foregroundStyle(SBTheme.inkFaded)
                                    .padding(.horizontal, 18)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }

                if showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                }
            }
            .navigationBarHidden(true)
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
            .sheet(item: $detailCard) { card in
                CardDetailSheet(card: card) {
                    punch(card)
                } onReset: {
                    store.resetCard(card.id)
                } onArchive: {
                    store.archiveCard(card.id)
                } onEdit: {
                    detailCard = nil
                    sheetMode = .edit(card)
                } onDelete: {
                    detailCard = nil
                    deletingCard = card
                }
            }
            .confirmationDialog(
                "Delete \(deletingCard?.name ?? "")?",
                isPresented: Binding(
                    get: { deletingCard != nil },
                    set: { if !$0 { deletingCard = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let deletingCard {
                        store.deleteCard(deletingCard.id)
                    }
                    deletingCard = nil
                }
                Button("Cancel", role: .cancel) { deletingCard = nil }
            }
        }
    }

    private func punch(_ card: Card) {
        let rewardEarned = store.punch(card.id)
        Haptics.medium()
        if rewardEarned {
            Haptics.success()
            triggerConfetti()
        }
        // Keep detail sheet's card reference fresh if it's the one showing.
        if let updated = store.activeCards.first(where: { $0.id == card.id }) {
            detailCard = detailCard != nil ? updated : detailCard
        }
    }

    private func triggerConfetti() {
        showConfetti = true
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            showConfetti = false
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Stampbook")
                    .font(SBTheme.titleFont)
                    .foregroundStyle(SBTheme.ink)
                Text("Your punch cards, digitized")
                    .font(.caption)
                    .foregroundStyle(SBTheme.inkFaded)
            }
            Spacer()
            Button {
                if store.canAddCard(isPro: purchases.isPro) {
                    sheetMode = .add
                } else {
                    sheetMode = .paywall
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(SBTheme.stamp)
            }
            .accessibilityIdentifier("addCardButton")
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 34))
                .foregroundStyle(SBTheme.inkFaded)
            Text("No cards yet. Tap + to add your first punch card.")
                .font(.subheadline)
                .foregroundStyle(SBTheme.inkFaded)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
    }
}

private struct StampCardTile: View {
    let card: Card
    let onTap: () -> Void
    let onPunch: () -> Void

    private var accentColor: Color {
        Color(hex: card.colorHex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: card.category.symbolName)
                    .foregroundStyle(accentColor)
                Spacer()
                if card.isRewardEarned {
                    Image(systemName: "star.fill")
                        .foregroundStyle(SBTheme.reward)
                        .accessibilityIdentifier("rewardBadge_\(card.name)")
                }
            }

            Text(card.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SBTheme.ink)
                .lineLimit(1)

            Text("\(card.currentPunches)/\(card.punchesRequired)")
                .font(.caption)
                .foregroundStyle(SBTheme.inkFaded)

            HStack(spacing: 4) {
                ForEach(0..<min(card.punchesRequired, 8), id: \.self) { index in
                    Circle()
                        .fill(index < card.currentPunches ? accentColor : SBTheme.hole.opacity(0.25))
                        .frame(width: 8, height: 8)
                }
            }

            Button {
                onPunch()
            } label: {
                Text(card.isRewardEarned ? "View Reward" : "Punch")
                    .font(.caption.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .accessibilityIdentifier("tilePunchButton_\(card.name)")
        }
        .padding(12)
        .background(SBTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(accentColor.opacity(0.35), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityIdentifier("cardTile_\(card.name)")
        .onTapGesture {
            onTap()
        }
    }
}

/// A lightweight confetti burst shown when a reward is earned.
struct ConfettiView: View {
    @State private var animate = false
    private let pieces = 24
    private let colors: [Color] = [SBTheme.stamp, SBTheme.reward, SBTheme.hole, SBTheme.ink]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<pieces, id: \.self) { i in
                    Circle()
                        .fill(colors[i % colors.count])
                        .frame(width: 8, height: 8)
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: animate ? geo.size.height + 20 : -20
                        )
                        .animation(
                            .easeIn(duration: Double.random(in: 1.0...1.6)).delay(Double.random(in: 0...0.3)),
                            value: animate
                        )
                }
            }
        }
        .onAppear { animate = true }
        .accessibilityIdentifier("confettiView")
    }
}

#Preview {
    CardListView()
        .environmentObject(StampbookStore())
        .environmentObject(PurchaseManager())
}
