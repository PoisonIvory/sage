import Foundation
import os.log

/// Centralized logging utility for consistent logging across the app
/// - Replaces scattered print statements with structured logging
/// - Follows project standards for simple, effective logging
enum Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.sage.app"
    
    // MARK: - Log Categories
    private static let general = OSLog(subsystem: subsystem, category: "general")
    private static let network = OSLog(subsystem: subsystem, category: "network")
    private static let audio = OSLog(subsystem: subsystem, category: "audio")
    private static let auth = OSLog(subsystem: subsystem, category: "auth")
    private static let analytics = OSLog(subsystem: subsystem, category: "analytics")
    
    // MARK: - Public Logging Methods
    
    static func info(_ message: String, category: LogCategory = .general) {
        let log = logForCategory(category)
        os_log(.info, log: log, "%{public}@", message)
    }
    
    static func error(_ message: String, category: LogCategory = .general) {
        let log = logForCategory(category)
        os_log(.error, log: log, "%{public}@", message)
    }
    
    static func debug(_ message: String, category: LogCategory = .general) {
        #if DEBUG
        let log = logForCategory(category)
        os_log(.debug, log: log, "%{public}@", message)
        #endif
    }
    
    // MARK: - Private Helpers
    
    private static func logForCategory(_ category: LogCategory) -> OSLog {
        switch category {
        case .general:
            return general
        case .network:
            return network
        case .audio:
            return audio
        case .auth:
            return auth
        case .analytics:
            return analytics
        }
    }
}

// MARK: - Log Categories

enum LogCategory {
    case general
    case network
    case audio
    case auth
    case analytics
} 