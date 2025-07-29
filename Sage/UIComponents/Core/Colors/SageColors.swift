import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

/// Scalable color system supporting multiple design variants
/// Usage: SageColors.primary(flags) for new code, SageColors.primary for legacy code
struct SageColors {
    
    // MARK: - Feature Flags Based Colors (New API)
    
    /// Primary color - main brand color, buttons, key UI elements
    static func primary(_ flags: FeatureFlags) -> Color {
        flags.useEditorialDesignSystem ? Color(hex: "#3B2722") : Color("EspressoBrown")
    }
    
    /// Secondary color - supporting elements, secondary buttons
    static func secondary(_ flags: FeatureFlags) -> Color {
        flags.useEditorialDesignSystem ? Color(hex: "#845634") : Color("CinnamonBark")
    }
    
    /// Background color - main app background
    static func background(_ flags: FeatureFlags) -> Color {
        flags.useEditorialDesignSystem ? Color(hex: "#F5EFE9") : Color("FogWhite")
    }
    
    /// Surface color - cards, sheets, elevated content
    static func surface(_ flags: FeatureFlags) -> Color {
        flags.useEditorialDesignSystem ? Color(hex: "#B99E93") : Color("EarthClay")
    }
    
    /// Accent color - highlights, progress indicators, active states
    static func accent(_ flags: FeatureFlags) -> Color {
        flags.useEditorialDesignSystem ? Color(hex: "#DA9F7C") : Color("CoralBlush")
    }
    
    /// Muted color - subtle text, inactive elements, dividers
    static func muted(_ flags: FeatureFlags) -> Color {
        flags.useEditorialDesignSystem ? Color(hex: "#6D9C97") : Color("SageTeal")
    }
    
    // MARK: - Legacy Compatibility Colors (Backward Compatible)
    
    /// Legacy: Espresso brown - maps to primary color
    static var espressoBrown: Color { Color("EspressoBrown") }
    static var espresso: Color { espressoBrown }
    
    /// Legacy: Cinnamon bark - maps to secondary color
    static var cinnamonBark: Color { Color("CinnamonBark") }
    static var sienna: Color { cinnamonBark }
    
    /// Legacy: Fog white - maps to background color
    static var fogWhite: Color { Color("FogWhite") }
    static var fog: Color { fogWhite }
    
    /// Legacy: Earth clay - maps to surface color
    static var earthClay: Color { Color("EarthClay") }
    static var clay: Color { earthClay }
    
    /// Legacy: Sandstone - neutral color
    static var sandstone: Color { Color("Sandstone") }
    
    /// Legacy: Coral blush - maps to accent color
    static var coralBlush: Color { Color("CoralBlush") }
    static var dustyRose: Color { coralBlush }
    
    /// Legacy: Sage teal - maps to muted color
    static var sageTeal: Color { Color("SageTeal") }
    static var mutedTeal: Color { sageTeal }
    
    /// Legacy: Soft taupe - neutral color
    static var softTaupe: Color { Color("SoftTaupe") }
    
    // MARK: - System Colors (consistent across variants)
    
    /// Error red - consistent across all variants
    static let error = Color(hex: "#FF3B30")
    
    /// Success green - consistent across all variants  
    static let success = Color(hex: "#30D158")
    
    /// Warning orange - consistent across all variants
    static let warning = Color(hex: "#FF9500")
    
    /// Info blue - consistent across all variants
    static let info = Color(hex: "#007AFF")
    
    // MARK: - Convenience Methods
    
    /// Get all colors for current variant (useful for debugging/previews)
    static func allColors(_ flags: FeatureFlags) -> [String: Color] {
        return [
            "primary": primary(flags),
            "secondary": secondary(flags), 
            "background": background(flags),
            "surface": surface(flags),
            "accent": accent(flags),
            "muted": muted(flags)
        ]
    }
    
    /// Get color palette preview for variant selection
    static func palettePreview(_ variant: DesignVariant) -> [Color] {
        let flags = FeatureFlags()
        flags.designVariant = variant
        return [
            primary(flags),
            secondary(flags),
            accent(flags),
            muted(flags)
        ]
    }
} 