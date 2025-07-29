import SwiftUI

struct SageTypography {
    // MARK: - Static Typography
    static let title = Font.system(size: 28, weight: .bold, design: .serif)
    static let sectionHeader = Font.system(size: 20, weight: .semibold, design: .serif)
    static let body = Font.system(size: 16, weight: .regular, design: .serif)
    static let caption = Font.system(size: 13, weight: .regular, design: .serif)
    static let headline = Font.system(size: 18, weight: .semibold, design: .serif) // UI_STANDARDS.md §2.1
    
    // MARK: - Dynamic Typography (Feature Flag Aware) - DISABLED
    static func title(_ flags: FeatureFlags) -> Font {
        // Always return default font - feature flags disabled
        return title
    }
    
    static func sectionHeader(_ flags: FeatureFlags) -> Font {
        // Always return default font - feature flags disabled
        return sectionHeader
    }
    
    static func headline(_ flags: FeatureFlags) -> Font {
        // Always return default font - feature flags disabled
        return headline
    }
    
    static func body(_ flags: FeatureFlags) -> Font {
        // Always return default font - feature flags disabled
        return body
    }
    
    static func caption(_ flags: FeatureFlags) -> Font {
        // Always return default font - feature flags disabled
        return caption
    }
    
    // MARK: - Optional Feature Flag Methods - DISABLED
    static func title(_ flags: FeatureFlags?) -> Font {
        // Always return default font - feature flags disabled
        return title
    }
    
    static func sectionHeader(_ flags: FeatureFlags?) -> Font {
        // Always return default font - feature flags disabled
        return sectionHeader
    }
    
    static func headline(_ flags: FeatureFlags?) -> Font {
        // Always return default font - feature flags disabled
        return headline
    }
    
    static func body(_ flags: FeatureFlags?) -> Font {
        // Always return default font - feature flags disabled
        return body
    }
    
    static func caption(_ flags: FeatureFlags?) -> Font {
        // Always return default font - feature flags disabled
        return caption
    }
} 