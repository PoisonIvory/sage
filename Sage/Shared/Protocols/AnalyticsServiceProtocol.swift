import Foundation
import Mixpanel

/// Protocol for analytics service to enable mocking and testing
/// - Provides abstraction for analytics tracking
/// - Enables consistent event tracking across the app
/// - Supports different analytics implementations
protocol AnalyticsServiceProtocol {
    func track(_ name: String, properties: [String: MixpanelType]?, origin: String?)
    func identifyUser(userId: String, userProfile: UserProfile)
} 