//
//  Theme.swift
//  seedlock
//
//  Created by Fine Ke on 24/10/2025.
//

import SwiftUI

struct Theme {
    // Colors - Light Mode
    struct Light {
        static let primary = Color(hex: "2F6BFF")
        static let secondary = Color(hex: "6B7A90")
        static let background = Color(hex: "FFFFFF")
        static let surface = Color(hex: "F6F8FB")
        static let label = Color(hex: "111418")
        static let secondaryLabel = Color(hex: "6B7380")
        static let tertiaryLabel = Color(hex: "8E99A8")
        static let success = Color(hex: "18A957")
        static let warning = Color(hex: "F29D38")
        static let danger = Color(hex: "E5484D")
        static let divider = Color(hex: "E7EAF0")
    }
    
    // Colors - Dark Mode
    struct Dark {
        static let primary = Color(hex: "7DA0FF")
        static let secondary = Color(hex: "9AA7BB")
        static let background = Color(hex: "0D0F13")
        static let surface = Color(hex: "151922")
        static let label = Color(hex: "E9ECF2")
        static let secondaryLabel = Color(hex: "A6AFBD")
        static let tertiaryLabel = Color(hex: "737E8E")
        static let success = Color(hex: "22C26B")
        static let warning = Color(hex: "FFB15A")
        static let danger = Color(hex: "FF6B70")
        static let divider = Color(hex: "232A36")
    }
    
    // Spacing
    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
    
    // Radius
    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
    
    // Minimum tap target
    static let minTapTarget: CGFloat = 44
}

// Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Adaptive colors based on color scheme
extension Color {
    static func adaptive(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
    
    static let appBackground = Color.adaptive(light: Theme.Light.background, dark: Theme.Dark.background)
    static let appSurface = Color.adaptive(light: Theme.Light.surface, dark: Theme.Dark.surface)
    static let appLabel = Color.adaptive(light: Theme.Light.label, dark: Theme.Dark.label)
    static let appSecondaryLabel = Color.adaptive(light: Theme.Light.secondaryLabel, dark: Theme.Dark.secondaryLabel)
    static let appTertiaryLabel = Color.adaptive(light: Theme.Light.tertiaryLabel, dark: Theme.Dark.tertiaryLabel)
    static let appPrimary = Color.adaptive(light: Theme.Light.primary, dark: Theme.Dark.primary)
    static let appDivider = Color.adaptive(light: Theme.Light.divider, dark: Theme.Dark.divider)
    static let appSuccess = Color.adaptive(light: Theme.Light.success, dark: Theme.Dark.success)
    static let appWarning = Color.adaptive(light: Theme.Light.warning, dark: Theme.Dark.warning)
    static let appDanger = Color.adaptive(light: Theme.Light.danger, dark: Theme.Dark.danger)
}

