import SwiftUI

/// Stampbook's identity: warm kraft-paper card stock with a punched-hole
/// motif. Distinct from every sibling app's palette — not the cream/ink/amber
/// "luxury ledger" family, not Envelo's bright warm-white/coral/teal, not any
/// dark slate/mint/copper combination used elsewhere. Kraft brown backdrop,
/// a deep espresso ink for text, a warm postal-stamp red accent for the
/// punch/reward action, and a brass-gold "reward earned" highlight.
enum SBTheme {
    static let backdrop = Color(red: 0.878, green: 0.816, blue: 0.706)       // kraft paper tan
    static let card = Color(red: 0.949, green: 0.913, blue: 0.847)          // lighter kraft card stock
    static let cardBorder = Color(red: 0.678, green: 0.588, blue: 0.463)

    static let ink = Color(red: 0.271, green: 0.192, blue: 0.129)          // espresso brown ink
    static let inkFaded = Color(red: 0.271, green: 0.192, blue: 0.129).opacity(0.56)

    static let stamp = Color(red: 0.729, green: 0.216, blue: 0.161)         // postal-stamp red — punch accent
    static let stampDeep = Color(red: 0.573, green: 0.145, blue: 0.106)

    static let hole = Color(red: 0.616, green: 0.518, blue: 0.373)          // punched-hole shadow tone

    static let reward = Color(red: 0.749, green: 0.573, blue: 0.212)        // brass-gold reward highlight

    static let danger = Color(red: 0.678, green: 0.235, blue: 0.192)
    static let rule = Color.black.opacity(0.08)

    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let displayFont = Font.system(size: 40, weight: .bold, design: .rounded)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

enum Haptics {
    static var enabled: Bool = true

    static func light() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
