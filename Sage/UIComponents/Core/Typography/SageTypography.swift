import SwiftUI

/// Scalable typography system supporting multiple design variants
/// Usage: SageTypography.title(flags) for new code, SageTypography.title for legacy code
struct SageTypography {
    
    // MARK: - Feature Flags Based Typography (New API)
    
    /// Title typography - main headings, hero text
    static func title(_ flags: FeatureFlags) -> Font {
        flags.useEditorialDesignSystem ? 
            Font.custom("Georgia", size: 32).weight(.bold) :
            Font.system(size: 28, weight: .bold, design: .default)
    }
    
    /// Headline typography - section headers, card titles
    static func headline(_ flags: FeatureFlags) -> Font {
        flags.useEditorialDesignSystem ? 
            Font.custom("Georgia", size: 24).weight(.semibold) :
            Font.system(size: 20, weight: .semibold, design: .default)
    }
    
    /// Body typography - main content, descriptions
    static func body(_ flags: FeatureFlags) -> Font {
        flags.useEditorialDesignSystem ? 
            Font.custom("Georgia", size: 16) :
            Font.system(size: 16, weight: .regular, design: .default)
    }
    
    /// Caption typography - small text, labels, metadata
    static func caption(_ flags: FeatureFlags) -> Font {
        flags.useEditorialDesignSystem ? 
            Font.custom("Georgia", size: 12) :
            Font.system(size: 12, weight: .regular, design: .default)
    }
    
    /// Button typography - CTA text, navigation labels
    static func button(_ flags: FeatureFlags) -> Font {
        flags.useEditorialDesignSystem ? 
            Font.custom("Georgia", size: 16).weight(.semibold) :
            Font.system(size: 16, weight: .semibold, design: .default)
    }
    
    /// Input field typography - form fields, search
    static func input(_ flags: FeatureFlags) -> Font {
        flags.useEditorialDesignSystem ? 
            Font.custom("Georgia", size: 16) :
            Font.system(size: 16, weight: .regular, design: .default)
    }
    
    // MARK: - Size Variants
    
    /// Large title for hero sections
    static func titleLarge(_ flags: FeatureFlags) -> Font {
        flags.useEditorialDesignSystem ? 
            Font.custom("Georgia", size: 40).weight(.bold) :
            Font.system(size: 36, weight: .bold, design: .default)
    }
    
    /// Small body text for dense content
    static func bodySmall(_ flags: FeatureFlags) -> Font {
        flags.useEditorialDesignSystem ? 
            Font.custom("Georgia", size: 14) :
            Font.system(size: 14, weight: .regular, design: .default)
    }
    
    // MARK: - Legacy Compatibility Typography (Backward Compatible)
    
    /// Legacy: Title serif - maps to title
    static var titleSerif: Font { Font.custom("Georgia", size: 32).weight(.bold) }
    static var title: Font { Font.system(size: 28, weight: .bold, design: .default) }
    
    /// Legacy: Headline sans - maps to headline
    static var headlineSans: Font { Font.system(size: 20, weight: .semibold, design: .default) }
    static var headline: Font { headlineSans }
    
    /// Legacy: Section header - maps to headline
    static var sectionHeader: Font { headlineSans }
    
    /// Legacy: Body text
    static var body: Font { Font.system(size: 16, weight: .regular, design: .default) }
    
    /// Legacy: Caption text
    static var caption: Font { Font.system(size: 12, weight: .regular, design: .default) }
    
    // MARK: - Helper Methods
    
    /// Get all typography styles for current variant (useful for debugging/previews)
    static func allStyles(_ flags: FeatureFlags) -> [String: Font] {
        return [
            "title": title(flags),
            "titleLarge": titleLarge(flags),
            "headline": headline(flags),
            "body": body(flags),
            "bodySmall": bodySmall(flags),
            "button": button(flags),
            "input": input(flags),
            "caption": caption(flags)
        ]
    }
    
    /// Get typography preview for variant selection
    static func stylePreview(_ variant: DesignVariant) -> [Font] {
        // For now, return default system fonts for preview
        return [
            Font.system(size: 28, weight: .bold, design: .default),
            Font.system(size: 20, weight: .semibold, design: .default),
            Font.system(size: 16, weight: .regular, design: .default)
        ]
    }
} 