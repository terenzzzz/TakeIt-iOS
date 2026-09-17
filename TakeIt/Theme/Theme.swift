import SwiftUI

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    init(light: Color, dark: Color) {
        #if canImport(UIKit) && !os(watchOS)
        self.init(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(dark)
                : NSColor(light)
        })
        #else
        self = light
        #endif
    }
}

enum Theme {
    static let primary = Color(light: Color(hex: 0x18181B), dark: Color(hex: 0xF4F4F5))
    static let primaryHover = Color(light: Color(hex: 0x27272A), dark: Color(hex: 0xFFFFFF))
    static let primaryText = Color(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x09090B))
    static let primaryLight = Color(light: Color(hex: 0x18181B, alpha: 0.06), dark: Color(hex: 0xF4F4F5, alpha: 0.12))

    static let bg = Color(light: Color(hex: 0xFAFAFA), dark: Color(hex: 0x09090B))
    static let bgDots = Color(light: Color(hex: 0x000000, alpha: 0.08), dark: Color(hex: 0xFFFFFF, alpha: 0.07))
    static let surface = Color(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x121215))
    static let surfaceHover = Color(light: Color(hex: 0xF4F4F5), dark: Color(hex: 0x1C1C21))
    static let surfaceGlass = Color(light: Color(hex: 0xFFFFFF, alpha: 0.88), dark: Color(hex: 0x121215, alpha: 0.85))

    static let text = Color(light: Color(hex: 0x09090B), dark: Color(hex: 0xFAFAFA))
    static let textSecondary = Color(light: Color(hex: 0x3F3F46), dark: Color(hex: 0xA1A1AA))
    // Light needs a deeper muted gray so body copy stays readable on #FAFAFA.
    static let textMuted = Color(light: Color(hex: 0x52525B), dark: Color(hex: 0xA1A1AA))

    static let border = Color(light: Color(hex: 0xE4E4E7), dark: Color(hex: 0xFFFFFF, alpha: 0.10))
    static let borderHover = Color(light: Color(hex: 0xD4D4D8), dark: Color(hex: 0xFFFFFF, alpha: 0.22))

    static let danger = Color(hex: 0xEF4444)
    static let success = Color(hex: 0x22C55E)
    static let previewBg = Color(hex: 0x020617)

    static let radiusSM: CGFloat = 8
    static let radiusMD: CGFloat = 12
    static let radiusLG: CGFloat = 16
}

struct PlatformStyle: Equatable {
    let name: String
    let color: Color
    let background: Color
    let border: Color

    static func style(for platform: String) -> PlatformStyle {
        switch platform.lowercased() {
        case "myppt", "myppt.cc":
            return PlatformStyle(
                name: "MyPPT.cc",
                color: Color(hex: 0x3B82F6),
                background: Color(hex: 0x3B82F6, alpha: 0.12),
                border: Color(hex: 0x3B82F6, alpha: 0.25)
            )
        case "lurl", "lurl.cc":
            return PlatformStyle(
                name: "LURL.cc",
                color: Color(hex: 0x10B981),
                background: Color(hex: 0x10B981, alpha: 0.12),
                border: Color(hex: 0x10B981, alpha: 0.25)
            )
        case "pptcc", "ppt.cc":
            return PlatformStyle(
                name: "PPT.cc",
                color: Color(hex: 0xF97316),
                background: Color(hex: 0xF97316, alpha: 0.12),
                border: Color(hex: 0xF97316, alpha: 0.25)
            )
        case "twitter", "twitter / x", "x":
            return PlatformStyle(
                name: "Twitter / X",
                color: Color(light: Color(hex: 0x18181B), dark: Color(hex: 0xE2E8F0)),
                background: Color(hex: 0xE2E8F0, alpha: 0.12),
                border: Color(hex: 0xE2E8F0, alpha: 0.25)
            )
        case "xiaohongshu", "xhs", "redbook", "rednote", "小红书":
            return PlatformStyle(
                name: "小红书",
                color: Color(hex: 0xFF2442),
                background: Color(hex: 0xFF2442, alpha: 0.12),
                border: Color(hex: 0xFF2442, alpha: 0.25)
            )
        case "douyin", "tiktok", "抖音":
            return PlatformStyle(
                name: "抖音",
                color: Color(light: Color(hex: 0x161823), dark: Color(hex: 0xFE2C55)),
                background: Color(hex: 0xFE2C55, alpha: 0.12),
                border: Color(hex: 0xFE2C55, alpha: 0.25)
            )
        case "instagram":
            return PlatformStyle(
                name: "Instagram",
                color: Color(hex: 0xE1306C),
                background: Color(hex: 0xE1306C, alpha: 0.12),
                border: Color(hex: 0xE1306C, alpha: 0.25)
            )
        default:
            return PlatformStyle(
                name: platform,
                color: Theme.primary,
                background: Theme.primaryLight,
                border: Theme.border
            )
        }
    }
}
