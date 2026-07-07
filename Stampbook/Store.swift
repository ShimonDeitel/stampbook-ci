import Foundation

@MainActor
final class StampbookStore: ObservableObject {
    @Published private(set) var cards: [Card] = []

    static let freeCardLimit = 3

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("stampbook_cards.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
        if cards.isEmpty {
            seedDefaults()
        }
    }

    private func seedDefaults() {
        cards = [
            Card(name: "Corner Café", category: .coffee, colorHex: CardColorOption.stampRed.rawValue,
                 punchesRequired: 10, currentPunches: 4, rewardDescription: "Free coffee"),
            Card(name: "Suds & Shine Car Wash", category: .carWash, colorHex: CardColorOption.denimBlue.rawValue,
                 punchesRequired: 8, currentPunches: 2, rewardDescription: "Free wash")
        ]
        save()
    }

    var activeCards: [Card] {
        cards.filter { !$0.isArchived }
    }

    var archivedCards: [Card] {
        cards.filter { $0.isArchived }
    }

    func canAddCard(isPro: Bool) -> Bool {
        isPro || activeCards.count < Self.freeCardLimit
    }

    @discardableResult
    func addCard(
        name: String,
        category: CardCategory,
        colorHex: String,
        punchesRequired: Int,
        rewardDescription: String,
        photoData: Data?,
        isPro: Bool
    ) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, punchesRequired > 0, canAddCard(isPro: isPro) else { return false }
        let card = Card(
            name: trimmed,
            category: category,
            colorHex: colorHex,
            punchesRequired: punchesRequired,
            rewardDescription: rewardDescription,
            photoData: photoData
        )
        cards.append(card)
        save()
        return true
    }

    func updateCard(
        _ id: UUID,
        name: String,
        category: CardCategory,
        colorHex: String,
        punchesRequired: Int,
        rewardDescription: String,
        photoData: Data?
    ) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, punchesRequired > 0, let idx = cards.firstIndex(where: { $0.id == id }) else { return }
        cards[idx].name = trimmed
        cards[idx].category = category
        cards[idx].colorHex = colorHex
        cards[idx].punchesRequired = punchesRequired
        cards[idx].rewardDescription = rewardDescription
        cards[idx].photoData = photoData
        save()
    }

    func deleteCard(_ id: UUID) {
        cards.removeAll { $0.id == id }
        save()
    }

    func deleteAllData() {
        cards = []
        seedDefaults()
    }

    /// Tap-to-punch: increments count by one, capped at punchesRequired.
    /// Free tier does NOT block punching existing cards, only adding new ones.
    @discardableResult
    func punch(_ id: UUID) -> Bool {
        guard let idx = cards.firstIndex(where: { $0.id == id }) else { return false }
        guard cards[idx].currentPunches < cards[idx].punchesRequired else { return false }
        cards[idx].currentPunches += 1
        save()
        return cards[idx].isRewardEarned
    }

    /// Resets a card to 0 punches for a new cycle after the reward is claimed.
    func resetCard(_ id: UUID) {
        guard let idx = cards.firstIndex(where: { $0.id == id }) else { return }
        cards[idx].currentPunches = 0
        save()
    }

    func archiveCard(_ id: UUID) {
        guard let idx = cards.firstIndex(where: { $0.id == id }) else { return }
        cards[idx].isArchived = true
        save()
    }

    func unarchiveCard(_ id: UUID) {
        guard let idx = cards.firstIndex(where: { $0.id == id }) else { return }
        cards[idx].isArchived = false
        save()
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var cards: [Card]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            cards = decoded.cards
        }
    }

    private func save() {
        let snapshot = Snapshot(cards: cards)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
