import SwiftUI

/// Scalable spacing system supporting multiple design variants
/// Usage: SageSpacing.medium(flags) for new code, SageSpacing.medium for legacy code
struct SageSpacing {
    
    // MARK: - Base Spacing Values (8pt grid system)
    
    private static let baseSpacing: CGFloat = 8
    
    // MARK: - Feature Flags Based Spacing (New API)
    
    /// Extra small spacing - tight layouts, component internal padding
    static func xSmall(_ flags: FeatureFlags) -> CGFloat {
        baseSpacing * 0.5 * (flags.useEditorialDesignSystem ? 1.2 : 1.0) // 4pt base
    }
    
    /// Small spacing - compact elements, form field gaps
    static func small(_ flags: FeatureFlags) -> CGFloat {
        baseSpacing * 1.0 * (flags.useEditorialDesignSystem ? 1.2 : 1.0) // 8pt base
    }
    
    /// Medium spacing - standard component spacing, card padding
    static func medium(_ flags: FeatureFlags) -> CGFloat {
        baseSpacing * 2.0 * (flags.useEditorialDesignSystem ? 1.2 : 1.0) // 16pt base
    }
    
    /// Large spacing - section separation, major layout gaps
    static func large(_ flags: FeatureFlags) -> CGFloat {
        baseSpacing * 3.0 * (flags.useEditorialDesignSystem ? 1.2 : 1.0) // 24pt base
    }
    
    /// Extra large spacing - page sections, hero spacing
    static func xLarge(_ flags: FeatureFlags) -> CGFloat {
        baseSpacing * 4.0 * (flags.useEditorialDesignSystem ? 1.2 : 1.0) // 32pt base
    }
    
    /// XXL spacing - major page divisions, hero sections
    static func xxLarge(_ flags: FeatureFlags) -> CGFloat {
        baseSpacing * 5.0 * (flags.useEditorialDesignSystem ? 1.2 : 1.0) // 40pt base
    }
    
    // MARK: - Corner Radius (adapts to design variant)
    
    /// Small corner radius - buttons, small cards
    static func cornerRadiusSmall(_ flags: FeatureFlags) -> CGFloat {
        flags.useEditorialDesignSystem ? 4 : 8
    }
    
    /// Standard corner radius - cards, modals, main UI elements
    static func cornerRadius(_ flags: FeatureFlags) -> CGFloat {
        flags.useEditorialDesignSystem ? 8 : 12
    }
    
    /// Large corner radius - hero cards, major UI surfaces
    static func cornerRadiusLarge(_ flags: FeatureFlags) -> CGFloat {
        flags.useEditorialDesignSystem ? 12 : 16
    }
    
    // MARK: - Contextual Spacing
    
    /// Button internal padding
    static func buttonPadding(_ flags: FeatureFlags) -> EdgeInsets {
        let base = medium(flags)
        return EdgeInsets(top: base * 0.75, leading: base, bottom: base * 0.75, trailing: base)
    }
    
    /// Card internal padding
    static func cardPadding(_ flags: FeatureFlags) -> EdgeInsets {
        let base = medium(flags)
        return EdgeInsets(top: base, leading: base, bottom: base, trailing: base)
    }
    
    /// Page margin - main content area padding
    static func pageMargin(_ flags: FeatureFlags) -> CGFloat {
        medium(flags)
    }
    
    /// Section spacing - vertical space between major sections
    static func sectionSpacing(_ flags: FeatureFlags) -> CGFloat {
        xLarge(flags)
    }
    
    // MARK: - Legacy Compatibility Spacing (Backward Compatible)
    
    /// Legacy small spacing
    static let small: CGFloat = 8
    
    /// Legacy medium spacing  
    static let medium: CGFloat = 16
    
    /// Legacy large spacing
    static let large: CGFloat = 24
    
    /// Legacy xLarge spacing
    static let xLarge: CGFloat = 32
    
    /// Legacy xlarge spacing (from UI_STANDARDS.md §2.2)
    static let xlarge: CGFloat = 40
    
    // MARK: - Convenience Methods
    
    /// Get all spacing values for current variant (useful for debugging/previews)
    static func allSpacing(_ flags: FeatureFlags) -> [String: CGFloat] {
        return [
            "xSmall": xSmall(flags),
            "small": small(flags),
            "medium": medium(flags), 
            "large": large(flags),
            "xLarge": xLarge(flags),
            "xxLarge": xxLarge(flags),
            "cornerRadius": cornerRadius(flags)
        ]
    }
    
    /// Get spacing preview for variant selection
    static func spacingPreview(_ variant: DesignVariant) -> [CGFloat] {
        let multiplier = variant.useEditorialDesignSystem ? 1.2 : 1.0
        return [
            baseSpacing * 1.0 * multiplier, // small
            baseSpacing * 2.0 * multiplier, // medium
            baseSpacing * 3.0 * multiplier, // large
            variant.useEditorialDesignSystem ? 8 : 12 // corner radius
        ]
    }
    
    // MARK: - Animation Durations (variant-aware)
    
    /// Quick animations - micro interactions, state changes
    static func animationQuick(_ flags: FeatureFlags) -> Double {
        0.15
    }
    
    /// Standard animations - transitions, modals
    static func animationStandard(_ flags: FeatureFlags) -> Double {
        0.3
    }
    
    /// Slow animations - page transitions, complex animations
    static func animationSlow(_ flags: FeatureFlags) -> Double {
        0.5
    }
} 