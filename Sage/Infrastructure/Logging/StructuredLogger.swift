import Foundation
import os.log

/// Unified structured logging system for Sage voice analysis
/// Provides consistent formatting, correlation IDs, and rich context across all components
///
/// Usage:
///   let logger = StructuredLogger(component: "HybridAnalysis")
///   logger.startOperation("voice_analysis", recordingId: recording.id, userId: userId) { operation in
///       operation.logProgress("Local analysis started")
///       // ... perform work
///       operation.logProgress("Cloud upload triggered", extra: ["size": fileSize])
///   }

public struct LogContext {
    public let recordingId: String?
    public let userId: String?
    public let operationId: String?
    public let operation: String?
    public let sessionId: String?
    
    public init(recordingId: String? = nil, userId: String? = nil, operationId: String? = nil, 
                operation: String? = nil, sessionId: String? = nil) {
        self.recordingId = recordingId
        self.userId = userId
        self.operationId = operationId ?? UUID().uuidString
        self.operation = operation
        self.sessionId = sessionId
    }
    
    /// Convert to structured data for logging
    public var logData: [String: Any] {
        var data: [String: Any] = [:]
        if let recordingId = recordingId { data["recording_id"] = recordingId }
        if let userId = userId { data["user_id"] = userId }
        if let operationId = operationId { data["operation_id"] = operationId }
        if let operation = operation { data["operation"] = operation }
        if let sessionId = sessionId { data["session_id"] = sessionId }
        return data
    }
}

public class StructuredLogger {
    private let osLogger: os.Logger
    private let component: String
    private let debugEnabled: Bool
    
    /// Global debug settings per component
    private static var debugComponents: Set<String> = []
    
    public init(component: String, subsystem: String = "com.sage.voice") {
        self.component = component
        self.osLogger = os.Logger(subsystem: subsystem, category: component)
        self.debugEnabled = Self.debugComponents.contains("*") || Self.debugComponents.contains(component)
    }
    
    // MARK: - Debug Configuration
    
    public static func enableDebug(for component: String? = nil) {
        if let component = component {
            debugComponents.insert(component)
        } else {
            debugComponents.insert("*")
        }
    }
    
    public static func disableDebug(for component: String? = nil) {
        if let component = component {
            debugComponents.remove(component)
        } else {
            debugComponents.removeAll()
        }
    }
    
    // MARK: - Core Logging Methods
    
    public func debug(_ message: String, context: LogContext? = nil, extra: [String: Any] = [:]) {
        guard debugEnabled else { return }
        log(level: .debug, message: message, context: context, extra: extra)
    }
    
    public func info(_ message: String, context: LogContext? = nil, extra: [String: Any] = [:]) {
        log(level: .info, message: message, context: context, extra: extra)
    }
    
    public func warning(_ message: String, context: LogContext? = nil, extra: [String: Any] = [:]) {
        log(level: .error, message: message, context: context, extra: extra) // Use .error for warnings in os.log
    }
    
    public func error(_ message: String, error: Error? = nil, context: LogContext? = nil, extra: [String: Any] = [:]) {
        var logExtra = extra
        if let error = error {
            logExtra["error_type"] = String(describing: type(of: error))
            logExtra["error_message"] = error.localizedDescription
        }
        log(level: .fault, message: message, context: context, extra: logExtra)
    }
    
    public func performance(_ operation: String, durationMs: Double, context: LogContext? = nil, extra: [String: Any] = [:]) {
        var logExtra = extra
        logExtra["duration_ms"] = durationMs
        logExtra["operation"] = operation
        log(level: .info, message: "Performance: \(operation) completed in \(String(format: "%.2f", durationMs))ms", 
            context: context, extra: logExtra)
    }
    
    private func log(level: OSLogType, message: String, context: LogContext?, extra: [String: Any]) {
        // Build structured log message
        var logData: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "component": component,
            "message": message
        ]
        
        // Add context if provided
        if let context = context {
            logData["context"] = context.logData
        }
        
        // Add extra data if provided
        if !extra.isEmpty {
            logData["data"] = extra
        }
        
        // Convert to JSON for structured logging
        let structuredMessage = formatAsJSON(logData)
        
        // Log to os.log with appropriate level
        osLogger.log(level: level, "\(structuredMessage, privacy: .public)")
    }
    
    private func formatAsJSON(_ data: [String: Any]) -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted])
            return String(data: jsonData, encoding: .utf8) ?? "\(data)"
        } catch {
            return "\(data)"
        }
    }
    
    // MARK: - Operation Logging
    
    public func startOperation<T>(_ operation: String, recordingId: String? = nil, userId: String? = nil, 
                                 extra: [String: Any] = [:], 
                                 work: (OperationLogger) throws -> T) rethrows -> T {
        let context = LogContext(recordingId: recordingId, userId: userId, operation: operation)
        let operationLogger = OperationLogger(logger: self, operation: operation, context: context)
        
        return try operationLogger.execute(extra: extra, work: work)
    }
    
    public func startAsyncOperation<T>(_ operation: String, recordingId: String? = nil, userId: String? = nil, 
                                      extra: [String: Any] = [:], 
                                      work: (OperationLogger) async throws -> T) async rethrows -> T {
        let context = LogContext(recordingId: recordingId, userId: userId, operation: operation)
        let operationLogger = OperationLogger(logger: self, operation: operation, context: context)
        
        return try await operationLogger.executeAsync(extra: extra, work: work)
    }
}

public class OperationLogger {
    private let logger: StructuredLogger
    private let operation: String
    private let context: LogContext
    private let startTime: Date
    
    init(logger: StructuredLogger, operation: String, context: LogContext) {
        self.logger = logger
        self.operation = operation
        self.context = context
        self.startTime = Date()
    }
    
    public func logProgress(_ message: String, extra: [String: Any] = [:]) {
        let elapsed = Date().timeIntervalSince(startTime) * 1000
        var logExtra = extra
        logExtra["elapsed_ms"] = elapsed
        
        logger.info("\(operation): \(message)", context: context, extra: logExtra)
    }
    
    public func logWarning(_ message: String, extra: [String: Any] = [:]) {
        let elapsed = Date().timeIntervalSince(startTime) * 1000
        var logExtra = extra
        logExtra["elapsed_ms"] = elapsed
        
        logger.warning("\(operation): \(message)", context: context, extra: logExtra)
    }
    
    public func logError(_ message: String, error: Error? = nil, extra: [String: Any] = [:]) {
        let elapsed = Date().timeIntervalSince(startTime) * 1000
        var logExtra = extra
        logExtra["elapsed_ms"] = elapsed
        
        logger.error("\(operation): \(message)", error: error, context: context, extra: logExtra)
    }
    
    func execute<T>(extra: [String: Any], work: (OperationLogger) throws -> T) rethrows -> T {
        logger.info("Starting \(operation)", context: context, extra: extra)
        
        do {
            let result = try work(self)
            let duration = Date().timeIntervalSince(startTime) * 1000
            logger.performance(operation, durationMs: duration, context: context, extra: extra)
            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime) * 1000
            var errorExtra = extra
            errorExtra["duration_ms"] = duration
            logger.error("Failed \(operation)", error: error, context: context, extra: errorExtra)
            throw error
        }
    }
    
    func executeAsync<T>(extra: [String: Any], work: (OperationLogger) async throws -> T) async rethrows -> T {
        logger.info("Starting \(operation)", context: context, extra: extra)
        
        do {
            let result = try await work(self)
            let duration = Date().timeIntervalSince(startTime) * 1000
            logger.performance(operation, durationMs: duration, context: context, extra: extra)
            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime) * 1000
            var errorExtra = extra
            errorExtra["duration_ms"] = duration
            logger.error("Failed \(operation)", error: error, context: context, extra: errorExtra)
            throw error
        }
    }
}

// MARK: - Convenience Extensions

extension StructuredLogger {
    /// Log voice analysis start with standard context
    public func logVoiceAnalysisStart(recordingId: String, userId: String, extra: [String: Any] = [:]) {
        let context = LogContext(recordingId: recordingId, userId: userId, operation: "voice_analysis")
        var logExtra = extra
        logExtra["analysis_type"] = "hybrid"
        info("Voice analysis started", context: context, extra: logExtra)
    }
    
    /// Log voice analysis completion with metrics
    public func logVoiceAnalysisComplete(recordingId: String, f0Mean: Double, confidence: Double, 
                                        durationMs: Double, extra: [String: Any] = [:]) {
        let context = LogContext(recordingId: recordingId, operation: "voice_analysis")
        var logExtra = extra
        logExtra["f0_mean_hz"] = f0Mean
        logExtra["confidence_percent"] = confidence
        
        performance("voice_analysis", durationMs: durationMs, context: context, extra: logExtra)
    }
    
    /// Log upload progress with standardized format
    public func logUploadProgress(recordingId: String, progressPercent: Int, extra: [String: Any] = [:]) {
        let context = LogContext(recordingId: recordingId, operation: "cloud_upload")
        var logExtra = extra
        logExtra["progress_percent"] = progressPercent
        info("Upload progress: \(progressPercent)%", context: context, extra: logExtra)
    }
    
    /// Log Firestore operation with standard context
    public func logFirestoreOperation(_ operation: String, collection: String, documentId: String, 
                                     error: Error? = nil, extra: [String: Any] = [:]) {
        let context = LogContext(operation: "firestore_\(operation)")
        var logExtra = extra
        logExtra["collection"] = collection
        logExtra["document_id"] = documentId
        
        if let error = error {
            self.error("Firestore \(operation) failed", error: error, context: context, extra: logExtra)
        } else {
            info("Firestore \(operation) successful", context: context, extra: logExtra)
        }
    }
}