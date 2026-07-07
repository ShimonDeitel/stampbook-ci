import SwiftUI
import PhotosUI

/// One unified sheet enum per screen — stacking multiple `.sheet(item:)` or
/// `.alert(...)` modifiers on the same view is a known SwiftUI bug (only the
/// last-declared one reliably fires). Route every sheet through this enum.
enum CardSheetMode: Identifiable {
    case add
    case edit(Card)
    case paywall

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let card): return card.id.uuidString
        case .paywall: return "paywall"
        }
    }
}

struct CardEditSheet: View {
    let mode: CardSheetMode
    let onSave: (String, CardCategory, String, Int, String, Data?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var category: CardCategory
    @State private var colorHex: String
    @State private var punchesRequiredText: String
    @State private var rewardDescription: String
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?

    init(mode: CardSheetMode, onSave: @escaping (String, CardCategory, String, Int, String, Data?) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .edit(let card):
            _name = State(initialValue: card.name)
            _category = State(initialValue: card.category)
            _colorHex = State(initialValue: card.colorHex)
            _punchesRequiredText = State(initialValue: String(card.punchesRequired))
            _rewardDescription = State(initialValue: card.rewardDescription)
            _photoData = State(initialValue: card.photoData)
        default:
            _name = State(initialValue: "")
            _category = State(initialValue: .coffee)
            _colorHex = State(initialValue: CardColorOption.stampRed.rawValue)
            _punchesRequiredText = State(initialValue: "10")
            _rewardDescription = State(initialValue: "")
            _photoData = State(initialValue: nil)
        }
    }

    private var title: String {
        if case .edit = mode { return "Edit Card" }
        return "New Card"
    }

    private var parsedPunches: Int {
        Int(punchesRequiredText) ?? 0
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedPunches > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Card") {
                    TextField("Business name", text: $name)
                        .accessibilityIdentifier("cardNameField")

                    Picker("Category", selection: $category) {
                        ForEach(CardCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.symbolName).tag(cat)
                        }
                    }
                    .accessibilityIdentifier("cardCategoryPicker")

                    Picker("Color", selection: $colorHex) {
                        ForEach(CardColorOption.allCases) { option in
                            Text(option.rawValue).tag(option.rawValue)
                        }
                    }
                    .accessibilityIdentifier("cardColorPicker")
                }

                Section("Punches") {
                    TextField("Punches required", text: $punchesRequiredText)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("punchesRequiredField")

                    TextField("Reward (e.g. Free coffee)", text: $rewardDescription)
                        .accessibilityIdentifier("rewardField")
                }

                Section("Photo") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(photoData == nil ? "Attach Photo" : "Change Photo", systemImage: "camera.fill")
                    }
                    .accessibilityIdentifier("photoPickerButton")

                    if let photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, category, colorHex, parsedPunches, rewardDescription, photoData)
                        dismiss()
                    }
                    .accessibilityIdentifier("cardSaveButton")
                    .disabled(!isValid)
                }
            }
            .onChange(of: photoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
        .dismissKeyboardOnTap()
    }
}

struct CardDetailSheet: View {
    let card: Card
    let onPunch: () -> Void
    let onReset: () -> Void
    let onArchive: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var accentColor: Color {
        Color(hex: card.colorHex)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SBTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if let data = card.photoData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .clipped()
                        }

                        Text(card.name)
                            .font(SBTheme.titleFont)
                            .foregroundStyle(SBTheme.ink)

                        Text(card.rewardDescription.isEmpty ? "Reward" : card.rewardDescription)
                            .font(.subheadline)
                            .foregroundStyle(SBTheme.inkFaded)

                        PunchGridView(card: card, accentColor: accentColor)
                            .padding(.horizontal, 12)

                        if card.isRewardEarned {
                            VStack(spacing: 10) {
                                Text("Reward Earned!")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(SBTheme.reward)
                                    .accessibilityIdentifier("rewardEarnedLabel")

                                Button {
                                    onReset()
                                    dismiss()
                                } label: {
                                    Text("Start New Card")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(SBTheme.reward)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .accessibilityIdentifier("resetCardButton")

                                Button {
                                    onArchive()
                                    dismiss()
                                } label: {
                                    Text("Archive This Card")
                                        .font(.subheadline)
                                        .foregroundStyle(SBTheme.inkFaded)
                                }
                                .accessibilityIdentifier("archiveCardButton")
                            }
                            .padding(.horizontal, 24)
                        } else {
                            Button {
                                onPunch()
                            } label: {
                                Text("Punch Card")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(accentColor)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .accessibilityIdentifier("punchButton")
                            .padding(.horizontal, 24)
                        }

                        Text("\(card.currentPunches)/\(card.punchesRequired) punches")
                            .font(.caption)
                            .foregroundStyle(SBTheme.inkFaded)
                    }
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("Card Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: onEdit) {
                            Label("Edit Card", systemImage: "pencil")
                        }
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete Card", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityIdentifier("cardDetailMenu")
                }
            }
        }
    }
}

/// The signature visual: a grid of circular punch holes, filled/stamped as
/// punches accumulate.
struct PunchGridView: View {
    let card: Card
    let accentColor: Color

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<card.punchesRequired, id: \.self) { index in
                ZStack {
                    Circle()
                        .strokeBorder(accentColor.opacity(0.4), lineWidth: 2)
                        .background(Circle().fill(index < card.currentPunches ? accentColor : SBTheme.card))
                    if index < card.currentPunches {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 36, height: 36)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
