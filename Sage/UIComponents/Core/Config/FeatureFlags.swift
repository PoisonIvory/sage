import SwiftUI
import Foundation

// MARK: - Design Variant Enum
enum DesignVariant: String, CaseIterable, Identifiable {
    case legacy = "legacy"
    case editorial = "editorial"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .legacy: return "Legacy"
        case .editorial: return "Editorial"
        }
    }
    
    var description: String {
        switch self {
        case .legacy: return "Original Sage design"
        case .editorial: return "Editorial magazine style"
        }
    }
}

// MARK: - Feature Flags Class - DISABLED
final class FeatureFlags: ObservableObject {
    // All feature flags disabled - returning default values
    @Published var designVariant: DesignVariant = .legacy
    @Published var buttonStyleExperiment: ButtonStyle = .default
    @Published var animationSpeedMultiplier: Double = 1.0
    @Published var cardStyleExperiment: CardStyle = .default
    @Published var navigationStyleExperiment: NavigationStyle = .default
    
    // MARK: - Nested Enums
    enum ButtonStyle: String, CaseIterable {
        case `default` = "default"
        case rounded = "rounded"
        case flat = "flat"
        
        var displayName: String {
            switch self {
            case .default: return "Default"
            case .rounded: return "Rounded"
            case .flat: return "Flat"
            }
        }
    }
    
    enum CardStyle: String, CaseIterable {
        case `default` = "default"
        case elevated = "elevated"
        case minimal = "minimal"
        
        var displayName: String {
            switch self {
            case .default: return "Default"
            case .elevated: return "Elevated"
            case .minimal: return "Minimal"
            }
        }
    }
    
    enum NavigationStyle: String, CaseIterable {
        case `default` = "default"
        case modern = "modern"
        case classic = "classic"
        
        var displayName: String {
            switch self {
            case .default: return "Default"
            case .modern: return "Modern"
            case .classic: return "Classic"
            }
        }
    }
    
    // MARK: - Computed Properties - DISABLED
    var useEditorialDesign: Bool {
        // Always return false to disable editorial design
        return false
    }
    
    var useLegacyDesign: Bool {
        // Always return true to use legacy design
        return true
    }
    
    // MARK: - Configuration Methods - DISABLED
    func saveLocalConfig() {
        // No-op - feature flags disabled
        print("Feature flags disabled - no configuration saved")
    }
    
    func resetToDefaults() {
        // No-op - feature flags disabled
        print("Feature flags disabled - no reset needed")
    }
    
    func exportConfiguration() -> [String: Any] {
        // Return empty configuration - feature flags disabled
        return [:]
    }
} 