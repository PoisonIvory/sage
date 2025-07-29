import Foundation

/// Simplified design system variants for experimentation
/// Each variant represents a complete design language with colors, typography, spacing, and interaction patterns
enum DesignVariant: String, CaseIterable, Identifiable {
    case legacy = "legacy"
    case editorial = "editorial"
    
    var id: String { rawValue }
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .legacy: return "Legacy"
        case .editorial: return "Editorial"
        }
    }
    
    /// Description for experimentation context
    var description: String {
        switch self {
        case .legacy:
            return "Original system fonts and colors"
        case .editorial:
            return "Magazine-style with Georgia and earth tones"
        }
    }
    
    /// Simple boolean check for editorial design system
    var useEditorialDesignSystem: Bool {
        self == .editorial
    }
} 