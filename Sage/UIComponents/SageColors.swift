import SwiftUI

struct SageColors {
    // MARK: - Static Colors
    static let earthClay = Color("EarthClay") // #C3A18D
    static let sandstone = Color("Sandstone") // #E6CFBB
    static let cinnamonBark = Color("CinnamonBark") // #8B5A3C
    static let coralBlush = Color("CoralBlush") // #D99C7A
    static let sageTeal = Color("SageTeal") // #6CA59E
    static let fogWhite = Color("FogWhite") // #F5EEE7
    static let softTaupe = Color("SoftTaupe") // #B8A396
    static let espressoBrown = Color("EspressoBrown") // #3E2B25
    static let error = Color(red: 0.8, green: 0.2, blue: 0.2) // Error red
    
    // MARK: - Dynamic Colors (Feature Flag Aware) - DISABLED
    static func primary(_ flags: FeatureFlags) -> Color {
        // Always return default color - feature flags disabled
        return espressoBrown
    }
    
    static func secondary(_ flags: FeatureFlags) -> Color {
        // Always return default color - feature flags disabled
        return cinnamonBark
    }
    
    static func background(_ flags: FeatureFlags) -> Color {
        // Always return default color - feature flags disabled
        return fogWhite
    }
    
    static func surface(_ flags: FeatureFlags) -> Color {
        // Always return default color - feature flags disabled
        return fogWhite
    }
    
    static func accent(_ flags: FeatureFlags) -> Color {
        // Always return default color - feature flags disabled
        return coralBlush
    }
    
    static func muted(_ flags: FeatureFlags) -> Color {
        // Always return default color - feature flags disabled
        return sageTeal
    }
    
    // MARK: - Optional Feature Flag Methods - DISABLED
    static func primary(_ flags: FeatureFlags?) -> Color {
        // Always return default color - feature flags disabled
        return espressoBrown
    }
    
    static func secondary(_ flags: FeatureFlags?) -> Color {
        // Always return default color - feature flags disabled
        return cinnamonBark
    }
    
    static func background(_ flags: FeatureFlags?) -> Color {
        // Always return default color - feature flags disabled
        return fogWhite
    }
    
    static func surface(_ flags: FeatureFlags?) -> Color {
        // Always return default color - feature flags disabled
        return fogWhite
    }
    
    static func accent(_ flags: FeatureFlags?) -> Color {
        // Always return default color - feature flags disabled
        return coralBlush
    }
    
    static func muted(_ flags: FeatureFlags?) -> Color {
        // Always return default color - feature flags disabled
        return sageTeal
    }
} 