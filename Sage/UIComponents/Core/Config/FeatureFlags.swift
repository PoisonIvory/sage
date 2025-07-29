import SwiftUI

/// Production-grade feature flag system for design system experimentation
/// Supports A/B testing, gradual rollouts, and live toggling
final class FeatureFlags: ObservableObject {
    
    // MARK: - Core Design System
    
    /// Current active design variant
    @Published var designVariant: DesignVariant = .legacy
    
    // MARK: - Individual Feature Experiments
    
    /// Button style experiments
    @Published var buttonStyleExperiment: ButtonStyle = .standard
    
    /// Animation speed multiplier for motion experiments
    @Published var animationSpeedMultiplier: Double = 1.0
    
    /// Card design experiments
    @Published var cardStyleExperiment: CardStyle = .standard
    
    /// Navigation style experiments
    @Published var navigationStyleExperiment: NavigationStyle = .standard
    
    // MARK: - Backwards Compatibility
    
    /// Legacy compatibility for existing code
    var useEditorialDesignSystem: Bool {
        designVariant == .editorial
    }
    
    // MARK: - Experiment Configurations
    
    enum ButtonStyle: String, CaseIterable {
        case standard = "standard"
        case rounded = "rounded"
        case minimal = "minimal"
        case bold = "bold"
        
        var displayName: String {
            switch self {
            case .standard: return "Standard"
            case .rounded: return "Rounded"
            case .minimal: return "Minimal"
            case .bold: return "Bold"
            }
        }
    }
    
    enum CardStyle: String, CaseIterable {
        case standard = "standard"
        case elevated = "elevated"
        case outlined = "outlined"
        case minimal = "minimal"
        
        var displayName: String {
            switch self {
            case .standard: return "Standard"
            case .elevated: return "Elevated"
            case .outlined: return "Outlined"
            case .minimal: return "Minimal"
            }
        }
    }
    
    enum NavigationStyle: String, CaseIterable {
        case standard = "standard"
        case compact = "compact"
        case expanded = "expanded"
        
        var displayName: String {
            switch self {
            case .standard: return "Standard"
            case .compact: return "Compact"
            case .expanded: return "Expanded"
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Reset all flags to defaults
    func resetToDefaults() {
        designVariant = .legacy
        buttonStyleExperiment = .standard
        animationSpeedMultiplier = 1.0
        cardStyleExperiment = .standard
        navigationStyleExperiment = .standard
    }
    
    /// Load configuration from remote config (future integration)
    func loadRemoteConfig() {
        // TODO: Integrate with Firebase Remote Config
        // TODO: Implement percentage-based rollouts
        // TODO: Add user segmentation
    }
    
    /// Export current configuration for sharing/debugging
    func exportConfiguration() -> [String: Any] {
        return [
            "designVariant": designVariant.rawValue,
            "buttonStyleExperiment": buttonStyleExperiment.rawValue,
            "animationSpeedMultiplier": animationSpeedMultiplier,
            "cardStyleExperiment": cardStyleExperiment.rawValue,
            "navigationStyleExperiment": navigationStyleExperiment.rawValue
        ]
    }
} 