import SwiftUI
import UIKit

// Global theme helpers for colors and button styling.

extension UIColor {
    // Initialize UIColor from hex string like "#RRGGBB" or "#AARRGGBB"
    convenience init?(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }

        var value: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&value) else { return nil }

        switch cleaned.count {
        case 6: // RRGGBB
            let r = CGFloat((value & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((value & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(value & 0x0000FF) / 255.0
            self.init(red: r, green: g, blue: b, alpha: 1.0)
        case 8: // AARRGGBB
            let a = CGFloat((value & 0xFF000000) >> 24) / 255.0
            let r = CGFloat((value & 0x00FF0000) >> 16) / 255.0
            let g = CGFloat((value & 0x0000FF00) >> 8) / 255.0
            let b = CGFloat(value & 0x000000FF) / 255.0
            self.init(red: r, green: g, blue: b, alpha: a)
        default:
            return nil
        }
    }
}

extension Color {
    init(hex: String) {
        if let ui = UIColor(hex: hex) { self = Color(ui) } else { self = Color(.systemBlue) }
    }
    static let brandPrimary = Color(hex: "#ad85fd")
}

struct PrimaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.brandPrimary)
            .foregroundColor(.white)
            .cornerRadius(12)
    }
}

extension View {
    func primaryButton() -> some View { self.modifier(PrimaryButtonModifier()) }
}