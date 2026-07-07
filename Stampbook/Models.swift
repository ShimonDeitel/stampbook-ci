import Foundation

enum CardCategory: String, Codable, CaseIterable, Identifiable {
    case coffee = "Coffee"
    case carWash = "Car Wash"
    case sandwich = "Sandwich Shop"
    case haircut = "Haircut"
    case yogurt = "Frozen Yogurt"
    case bakery = "Bakery"
    case other = "Other"

    var id: String { rawValue }
    var symbolName: String {
        switch self {
        case .coffee: return "cup.and.saucer.fill"
        case .carWash: return "car.fill"
        case .sandwich: return "takeoutbag.and.cup.and.straw.fill"
        case .haircut: return "scissors"
        case .yogurt: return "snowflake"
        case .bakery: return "birthday.cake.fill"
        case .other: return "star.fill"
        }
    }
}

/// A single physical paper punch card the user is tracking digitally.
struct Card: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: CardCategory
    var colorHex: String
    var punchesRequired: Int
    var currentPunches: Int
    var rewardDescription: String
    var photoData: Data?
    var dateCreated: Date
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        name: String,
        category: CardCategory,
        colorHex: String,
        punchesRequired: Int,
        currentPunches: Int = 0,
        rewardDescription: String,
        photoData: Data? = nil,
        dateCreated: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.colorHex = colorHex
        self.punchesRequired = max(1, punchesRequired)
        self.currentPunches = currentPunches
        self.rewardDescription = rewardDescription
        self.photoData = photoData
        self.dateCreated = dateCreated
        self.isArchived = isArchived
    }

    var isRewardEarned: Bool {
        currentPunches >= punchesRequired
    }

    var progress: Double {
        guard punchesRequired > 0 else { return 0 }
        return min(1.0, Double(currentPunches) / Double(punchesRequired))
    }
}

/// A small palette of preset card colors offered in the add-card sheet.
enum CardColorOption: String, CaseIterable, Identifiable {
    case stampRed = "B93A29"
    case brassGold = "BF9236"
    case forestGreen = "3D6B4A"
    case denimBlue = "355C7D"
    case plum = "6B4064"
    case espresso = "45311F"

    var id: String { rawValue }
}
