import XCTest
@testable import Stampbook

@MainActor
final class StampbookTests: XCTestCase {
    var store: StampbookStore!

    override func setUp() {
        super.setUp()
        store = StampbookStore()
        for card in store.cards {
            store.deleteCard(card.id)
        }
    }

    func testAddCard() {
        let added = store.addCard(
            name: "Test Cafe", category: .coffee, colorHex: CardColorOption.stampRed.rawValue,
            punchesRequired: 10, rewardDescription: "Free coffee", photoData: nil, isPro: false
        )
        XCTAssertTrue(added)
        XCTAssertEqual(store.activeCards.count, 1)
    }

    func testFreeLimitBlocksFourthCard() {
        for i in 0..<3 {
            _ = store.addCard(name: "Card \(i)", category: .coffee, colorHex: CardColorOption.stampRed.rawValue, punchesRequired: 10, rewardDescription: "Free", photoData: nil, isPro: false)
        }
        XCTAssertFalse(store.canAddCard(isPro: false))
        let fourth = store.addCard(name: "Card 4", category: .coffee, colorHex: CardColorOption.stampRed.rawValue, punchesRequired: 10, rewardDescription: "Free", photoData: nil, isPro: false)
        XCTAssertFalse(fourth)
        XCTAssertEqual(store.activeCards.count, 3)
    }

    func testProAllowsUnlimitedCards() {
        for i in 0..<5 {
            _ = store.addCard(name: "Card \(i)", category: .coffee, colorHex: CardColorOption.stampRed.rawValue, punchesRequired: 10, rewardDescription: "Free", photoData: nil, isPro: true)
        }
        XCTAssertEqual(store.activeCards.count, 5)
    }

    func testPunchIncrementsCount() {
        _ = store.addCard(name: "Test", category: .coffee, colorHex: CardColorOption.stampRed.rawValue, punchesRequired: 5, rewardDescription: "Free", photoData: nil, isPro: false)
        let card = store.activeCards[0]
        _ = store.punch(card.id)
        XCTAssertEqual(store.activeCards[0].currentPunches, 1)
    }

    func testPunchDoesNotExceedRequired() {
        _ = store.addCard(name: "Test", category: .coffee, colorHex: CardColorOption.stampRed.rawValue, punchesRequired: 1, rewardDescription: "Free", photoData: nil, isPro: false)
        let card = store.activeCards[0]
        let earnedReward = store.punch(card.id)
        XCTAssertTrue(earnedReward)
        let secondPunch = store.punch(card.id)
        XCTAssertFalse(secondPunch)
        XCTAssertEqual(store.activeCards[0].currentPunches, 1)
    }

    func testResetCardZeroesCount() {
        _ = store.addCard(name: "Test", category: .coffee, colorHex: CardColorOption.stampRed.rawValue, punchesRequired: 3, rewardDescription: "Free", photoData: nil, isPro: false)
        let card = store.activeCards[0]
        _ = store.punch(card.id)
        _ = store.punch(card.id)
        store.resetCard(card.id)
        XCTAssertEqual(store.activeCards[0].currentPunches, 0)
    }

    func testArchiveCardMovesToArchived() {
        _ = store.addCard(name: "Test", category: .coffee, colorHex: CardColorOption.stampRed.rawValue, punchesRequired: 3, rewardDescription: "Free", photoData: nil, isPro: false)
        let card = store.activeCards[0]
        store.archiveCard(card.id)
        XCTAssertEqual(store.activeCards.count, 0)
        XCTAssertEqual(store.archivedCards.count, 1)
    }

    func testDeleteCardRemovesIt() {
        _ = store.addCard(name: "Test", category: .coffee, colorHex: CardColorOption.stampRed.rawValue, punchesRequired: 3, rewardDescription: "Free", photoData: nil, isPro: false)
        let card = store.activeCards[0]
        store.deleteCard(card.id)
        XCTAssertEqual(store.activeCards.count, 0)
    }

    func testIsRewardEarnedWhenFull() {
        let card = Card(name: "Test", category: .coffee, colorHex: CardColorOption.stampRed.rawValue, punchesRequired: 5, currentPunches: 5, rewardDescription: "Free")
        XCTAssertTrue(card.isRewardEarned)
    }

    func testProgressCalculation() {
        let card = Card(name: "Test", category: .coffee, colorHex: CardColorOption.stampRed.rawValue, punchesRequired: 4, currentPunches: 2, rewardDescription: "Free")
        XCTAssertEqual(card.progress, 0.5, accuracy: 0.001)
    }
}
