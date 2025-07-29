import SwiftUI

struct SageSpacing {
    // MARK: - Static Spacing
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let xLarge: CGFloat = 32
    static let xlarge: CGFloat = 40 // UI_STANDARDS.md §2.2
    static let cornerRadius: CGFloat = 12
    static let pageMargin: CGFloat = 20
    
    // MARK: - Dynamic Spacing (Feature Flag Aware) - DISABLED
    static func xSmall(_ flags: FeatureFlags) -> CGFloat {
        // Always return default spacing - feature flags disabled
        return xSmall
    }
    
    static func small(_ flags: FeatureFlags) -> CGFloat {
        // Always return default spacing - feature flags disabled
        return small
    }
    
    static func medium(_ flags: FeatureFlags) -> CGFloat {
        // Always return default spacing - feature flags disabled
        return medium
    }
    
    static func large(_ flags: FeatureFlags) -> CGFloat {
        // Always return default spacing - feature flags disabled
        return large
    }
    
    static func xLarge(_ flags: FeatureFlags) -> CGFloat {
        // Always return default spacing - feature flags disabled
        return xLarge
    }
    
    static func cornerRadius(_ flags: FeatureFlags) -> CGFloat {
        // Always return default spacing - feature flags disabled
        return cornerRadius
    }
    
    static func pageMargin(_ flags: FeatureFlags) -> CGFloat {
        // Always return default spacing - feature flags disabled
        return pageMargin
    }
    
    // MARK: - Optional Feature Flag Methods - DISABLED
    static func xSmall(_ flags: FeatureFlags?) -> CGFloat {
        // Always return default spacing - feature flags disabled
        return xSmall
    }
    
    static func small(_ flags: FeatureFlags?) -> CGFloat {
        // Always return default spacing - feature flags disabled
        return small
    }
    
    static func medium(_ flags: FeatureFlags?) -> CGFloat {
        // Always return default spacing - feature flags disabled
        return medium
    }
    
    static func large(_ flags: FeatureFlags?) -> CGFloat {
        // Always return default spacing - feature flags disabled
        return large
    }
    
    static func xLarge(_ flags: FeatureFlags?) -> CGFloat {
        // Always return default spacing - feature flags disabled
        return xLarge
    }
    
    static func cornerRadius(_ flags: FeatureFlags?) -> CGFloat {
        // Always return default spacing - feature flags disabled
        return cornerRadius
    }
    
    static func pageMargin(_ flags: FeatureFlags?) -> CGFloat {
        // Always return default spacing - feature flags disabled
        return pageMargin
    }
} 