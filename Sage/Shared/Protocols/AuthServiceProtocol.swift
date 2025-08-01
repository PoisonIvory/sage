import Foundation

/// Protocol for authentication service (for testability)
protocol AuthServiceProtocol {
    var currentUserId: String? { get }
} 