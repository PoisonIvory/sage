//
//  VocalBaselineRepository.swift
//  Sage
//
//  Repository for vocal baseline persistence following DDD principles
//  AC-001: Record Initial Vocal Baseline
//  AC-002: Display Baseline Summary and Education
//  AC-003: Re-record Baseline During Onboarding
//

import Foundation

// MARK: - Vocal Baseline Repository Protocol

/// Repository for vocal baseline persistence
/// - Handles baseline storage and retrieval
/// - Follows repository pattern for domain persistence
/// - Uses dependency injection for testability
protocol VocalBaselineRepositoryProtocol {
    /// Saves a vocal baseline
    /// - Parameter baseline: Baseline to save
    /// - Throws: RepositoryError if save fails
    func saveBaseline(_ baseline: VocalBaseline) async throws
    
    /// Retrieves current baseline for a user
    /// - Parameter userId: User identifier
    /// - Returns: Current baseline or nil if none exists
    /// - Throws: RepositoryError if retrieval fails
    func getCurrentBaseline(for userId: UUID) async throws -> VocalBaseline?
    
    /// Archives a baseline when replaced
    /// - Parameter baseline: Baseline to archive
    /// - Throws: RepositoryError if archiving fails
    func archiveBaseline(_ baseline: VocalBaseline) async throws
    
    /// Retrieves baseline history for a user
    /// - Parameter userId: User identifier
    /// - Returns: Array of archived baselines
    /// - Throws: RepositoryError if retrieval fails
    func getBaselineHistory(for userId: UUID) async throws -> [ArchivedBaseline]
}

// MARK: - Vocal Baseline Repository Implementation

final class VocalBaselineRepository: VocalBaselineRepositoryProtocol {
    
    // MARK: - Dependencies
    
    private let firestoreClient: FirestoreClientProtocol
    private let logger: StructuredLogger
    
    // MARK: - Initialization
    
    init(
        firestoreClient: FirestoreClientProtocol,
        logger: StructuredLogger = StructuredLogger(component: "VocalBaselineRepository")
    ) {
        self.firestoreClient = firestoreClient
        self.logger = logger
    }
    
    // MARK: - Public Methods
    
    func saveBaseline(_ baseline: VocalBaseline) async throws {
        
        logger.debug("[VocalBaselineRepository] Saving baseline for user: \(baseline.userId)")
        
        do {
            // Convert baseline to Firestore document
            let documentData = try baselineToDocumentData(baseline)
            
            // Save to Firestore
            try await firestoreClient.saveDocument(
                collection: "vocal_baselines",
                documentId: baseline.id.uuidString,
                data: documentData
            )
            
            logger.info("[VocalBaselineRepository] Baseline saved successfully for user: \(baseline.userId)")
            
        } catch {
            logger.error("[VocalBaselineRepository] Failed to save baseline for user \(baseline.userId): \(error.localizedDescription)")
            throw VocalBaselineRepositoryError.saveFailed(error)
        }
    }
    
    func getCurrentBaseline(for userId: UUID) async throws -> VocalBaseline? {
        
        logger.debug("[VocalBaselineRepository] Retrieving current baseline for user: \(userId)")
        
        do {
            // Query for current baseline (not archived)
            let query = FirestoreQuery(
                collection: "vocal_baselines",
                filters: [
                    FirestoreFilter(field: "userId", operator: .equal, value: userId.uuidString),
                    FirestoreFilter(field: "isArchived", operator: .equal, value: false)
                ],
                orderBy: [FirestoreOrderBy(field: "establishedAt", direction: .descending)],
                limit: 1
            )
            
            let documents = try await firestoreClient.queryDocuments(query)
            
            guard let document = documents.first else {
                logger.debug("[VocalBaselineRepository] No current baseline found for user: \(userId)")
                return nil
            }
            
            // Convert document to baseline
            let baseline = try documentDataToBaseline(document)
            
            logger.info("[VocalBaselineRepository] Retrieved current baseline for user: \(userId)")
            
            return baseline
            
        } catch {
            logger.error("[VocalBaselineRepository] Failed to retrieve baseline for user \(userId): \(error.localizedDescription)")
            throw VocalBaselineRepositoryError.retrievalFailed(error)
        }
    }
    
    func archiveBaseline(_ baseline: VocalBaseline) async throws {
        
        logger.debug("[VocalBaselineRepository] Archiving baseline: \(baseline.id)")
        
        do {
            // Create archived baseline
            let archivedBaseline = ArchivedBaseline(
                originalBaselineId: baseline.id,
                archivedAt: Date(),
                replacementReason: .qualityImprovement
            )
            
            // Save archived baseline
            let archivedData = try archivedBaselineToDocumentData(archivedBaseline)
            try await firestoreClient.saveDocument(
                collection: "archived_vocal_baselines",
                documentId: archivedBaseline.id.uuidString,
                data: archivedData
            )
            
            // Mark original as archived
            let updateData: [String: Any] = ["isArchived": true, "archivedAt": Date()]
            try await firestoreClient.updateDocument(
                collection: "vocal_baselines",
                documentId: baseline.id.uuidString,
                data: updateData
            )
            
            logger.info("[VocalBaselineRepository] Baseline archived successfully: \(baseline.id)")
            
        } catch {
            logger.error("[VocalBaselineRepository] Failed to archive baseline \(baseline.id): \(error.localizedDescription)")
            throw VocalBaselineRepositoryError.archiveFailed(error)
        }
    }
    
    func getBaselineHistory(for userId: UUID) async throws -> [ArchivedBaseline] {
        
        logger.debug("[VocalBaselineRepository] Retrieving baseline history for user: \(userId)")
        
        do {
            let query = FirestoreQuery(
                collection: "archived_vocal_baselines",
                filters: [
                    FirestoreFilter(field: "originalBaseline.userId", operator: .equal, value: userId.uuidString)
                ],
                orderBy: [FirestoreOrderBy(field: "archivedAt", direction: .descending)]
            )
            
            let documents = try await firestoreClient.queryDocuments(query)
            
            let archivedBaselines = try documents.compactMap { document in
                try documentDataToArchivedBaseline(document)
            }
            
            logger.info("[VocalBaselineRepository] Retrieved \(archivedBaselines.count) archived baselines for user: \(userId)")
            
            return archivedBaselines
            
        } catch {
            logger.error("[VocalBaselineRepository] Failed to retrieve baseline history for user \(userId): \(error.localizedDescription)")
            throw VocalBaselineRepositoryError.retrievalFailed(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func baselineToDocumentData(_ baseline: VocalBaseline) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let baselineData = try encoder.encode(baseline)
        let baselineDict = try JSONSerialization.jsonObject(with: baselineData) as? [String: Any] ?? [:]
        
        return baselineDict.merging([
            "isArchived": false,
            "createdAt": Date(),
            "updatedAt": Date()
        ]) { _, new in new }
    }
    
    private func documentDataToBaseline(_ document: FirestoreDocument) throws -> VocalBaseline {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let documentData = try JSONSerialization.data(withJSONObject: document.data)
        return try decoder.decode(VocalBaseline.self, from: documentData)
    }
    
    private func archivedBaselineToDocumentData(_ archivedBaseline: ArchivedBaseline) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let archivedData = try encoder.encode(archivedBaseline)
        let archivedDict = try JSONSerialization.jsonObject(with: archivedData) as? [String: Any] ?? [:]
        
        return archivedDict.merging([
            "createdAt": Date(),
            "updatedAt": Date()
        ]) { _, new in new }
    }
    
    private func documentDataToArchivedBaseline(_ document: FirestoreDocument) throws -> ArchivedBaseline {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let documentData = try JSONSerialization.data(withJSONObject: document.data)
        return try decoder.decode(ArchivedBaseline.self, from: documentData)
    }
}

// MARK: - Repository Error Types

enum VocalBaselineRepositoryError: LocalizedError {
    case saveFailed(Error)
    case retrievalFailed(Error)
    case archiveFailed(Error)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save baseline: \(error.localizedDescription)"
        case .retrievalFailed(let error):
            return "Failed to retrieve baseline: \(error.localizedDescription)"
        case .archiveFailed(let error):
            return "Failed to archive baseline: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid baseline data"
        }
    }
}

// MARK: - Firestore Supporting Types

struct FirestoreQuery {
    let collection: String
    let filters: [FirestoreFilter]
    let orderBy: [FirestoreOrderBy]
    let limit: Int?
    
    init(collection: String, filters: [FirestoreFilter] = [], orderBy: [FirestoreOrderBy] = [], limit: Int? = nil) {
        self.collection = collection
        self.filters = filters
        self.orderBy = orderBy
        self.limit = limit
    }
}

struct FirestoreFilter {
    let field: String
    let `operator`: FirestoreOperator
    let value: Any
    
    init(field: String, operator: FirestoreOperator, value: Any) {
        self.field = field
        self.operator = `operator`
        self.value = value
    }
}

enum FirestoreOperator {
    case equal
    case greaterThan
    case lessThan
    case greaterThanOrEqual
    case lessThanOrEqual
}

struct FirestoreOrderBy {
    let field: String
    let direction: FirestoreDirection
    
    init(field: String, direction: FirestoreDirection) {
        self.field = field
        self.direction = direction
    }
}

enum FirestoreDirection {
    case ascending
    case descending
}

struct FirestoreDocument {
    let id: String
    let data: [String: Any]
}

// MARK: - Firestore Client Protocol

protocol FirestoreClientProtocol {
    func saveDocument(collection: String, documentId: String, data: [String: Any]) async throws
    func updateDocument(collection: String, documentId: String, data: [String: Any]) async throws
    func queryDocuments(_ query: FirestoreQuery) async throws -> [FirestoreDocument]
}

// MARK: - Mock Implementation

final class MockFirestoreClientProtocol: FirestoreClientProtocol {
    func saveDocument(collection: String, documentId: String, data: [String: Any]) async throws {
        // Mock implementation - do nothing
    }
    
    func updateDocument(collection: String, documentId: String, data: [String: Any]) async throws {
        // Mock implementation - do nothing
    }
    
    func queryDocuments(_ query: FirestoreQuery) async throws -> [FirestoreDocument] {
        // Mock implementation - return empty array
        return []
    }
} 