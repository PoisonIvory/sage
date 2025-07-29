//
//  VoiceAnalysisRepository.swift
//  Sage
//
//  Repository pattern for voice analysis following DDD principles
//  Reference: DATA_STANDARDS.md §3.2, CONTRIBUTING.md
//

import Foundation
import Combine

// MARK: - Repository Protocol
protocol VoiceAnalysisRepositoryProtocol {
    func saveRecording(_ recording: Recording) async -> DomainResult<Recording>
    func getRecordings(for userId: String) async -> DomainResult<[Recording]>
    func getRecording(by id: String) async -> DomainResult<Recording>
    func deleteRecording(_ recording: Recording) async -> DomainResult<Void>
    func saveAnalysisResult(_ result: VocalBiomarkers) async -> DomainResult<VocalBiomarkers>
    func getAnalysisResults(for userId: String) async -> DomainResult<[VocalBiomarkers]>
    func getLatestAnalysis(for userId: String) async -> DomainResult<VocalBiomarkers?>
}

// MARK: - Repository Implementation
final class VoiceAnalysisRepository: VoiceAnalysisRepositoryProtocol {
    
    // MARK: - Dependencies
    private let localStorage: LocalStorageProtocol
    private let cloudStorage: CloudStorageProtocol
    private let networkMonitor: NetworkMonitorProtocol
    
    // MARK: - Initialization
    init(localStorage: LocalStorageProtocol = LocalStorage(),
         cloudStorage: CloudStorageProtocol = CloudStorage(),
         networkMonitor: NetworkMonitorProtocol = NetworkMonitor()) {
        self.localStorage = localStorage
        self.cloudStorage = cloudStorage
        self.networkMonitor = networkMonitor
    }
    
    // MARK: - Recording Operations
    func saveRecording(_ recording: Recording) async -> DomainResult<Recording> {
        Logger.debug("Saving recording: \(recording.id)")
        
        // Always save locally first
        let localResult = await localStorage.saveRecording(recording)
        if localResult.isFailure {
            return localResult
        }
        
        // Try to sync to cloud if network available
        if networkMonitor.isConnected {
            let cloudResult = await cloudStorage.saveRecording(recording)
            if cloudResult.isFailure {
                Logger.warning("Cloud sync failed for recording \(recording.id), but local save succeeded")
                // Don't fail the operation if cloud sync fails
            }
        }
        
        return .success(recording)
    }
    
    func getRecordings(for userId: String) async -> DomainResult<[Recording]> {
        Logger.debug("Fetching recordings for user: \(userId)")
        
        // Try local first for performance
        let localResult = await localStorage.getRecordings(for: userId)
        if localResult.isSuccess {
            return localResult
        }
        
        // Fall back to cloud if local fails
        if networkMonitor.isConnected {
            let cloudResult = await cloudStorage.getRecordings(for: userId)
            if cloudResult.isSuccess {
                // Cache the results locally
                for recording in cloudResult.value ?? [] {
                    _ = await localStorage.saveRecording(recording)
                }
                return cloudResult
            }
        }
        
        return localResult
    }
    
    func getRecording(by id: String) async -> DomainResult<Recording> {
        Logger.debug("Fetching recording: \(id)")
        
        // Try local first
        let localResult = await localStorage.getRecording(by: id)
        if localResult.isSuccess {
            return localResult
        }
        
        // Fall back to cloud
        if networkMonitor.isConnected {
            let cloudResult = await cloudStorage.getRecording(by: id)
            if cloudResult.isSuccess, let recording = cloudResult.value {
                // Cache locally
                _ = await localStorage.saveRecording(recording)
                return cloudResult
            }
        }
        
        return localResult
    }
    
    func deleteRecording(_ recording: Recording) async -> DomainResult<Void> {
        Logger.debug("Deleting recording: \(recording.id)")
        
        // Delete from both local and cloud
        let localResult = await localStorage.deleteRecording(recording)
        let cloudResult = await cloudStorage.deleteRecording(recording)
        
        // Return success if local deletion succeeded
        if localResult.isSuccess {
            return .success(())
        }
        
        return localResult
    }
    
    // MARK: - Analysis Results Operations
    func saveAnalysisResult(_ result: VocalBiomarkers) async -> DomainResult<VocalBiomarkers> {
        Logger.debug("Saving analysis result for recording")
        
        // Always save locally first
        let localResult = await localStorage.saveAnalysisResult(result)
        if localResult.isFailure {
            return localResult
        }
        
        // Sync to cloud if network available
        if networkMonitor.isConnected {
            let cloudResult = await cloudStorage.saveAnalysisResult(result)
            if cloudResult.isFailure {
                Logger.warning("Cloud sync failed for analysis result, but local save succeeded")
            }
        }
        
        return .success(result)
    }
    
    func getAnalysisResults(for userId: String) async -> DomainResult<[VocalBiomarkers]> {
        Logger.debug("Fetching analysis results for user: \(userId)")
        
        // Try local first
        let localResult = await localStorage.getAnalysisResults(for: userId)
        if localResult.isSuccess {
            return localResult
        }
        
        // Fall back to cloud
        if networkMonitor.isConnected {
            let cloudResult = await cloudStorage.getAnalysisResults(for: userId)
            if cloudResult.isSuccess {
                // Cache results locally
                for result in cloudResult.value ?? [] {
                    _ = await localStorage.saveAnalysisResult(result)
                }
                return cloudResult
            }
        }
        
        return localResult
    }
    
    func getLatestAnalysis(for userId: String) async -> DomainResult<VocalBiomarkers?> {
        Logger.debug("Fetching latest analysis for user: \(userId)")
        
        // Try local first
        let localResult = await localStorage.getLatestAnalysis(for: userId)
        if localResult.isSuccess {
            return localResult
        }
        
        // Fall back to cloud
        if networkMonitor.isConnected {
            let cloudResult = await cloudStorage.getLatestAnalysis(for: userId)
            if cloudResult.isSuccess, let result = cloudResult.value {
                // Cache locally
                _ = await localStorage.saveAnalysisResult(result!)
                return cloudResult
            // No additional processing needed
        }
        }
        
        return localResult
    }
}

// MARK: - Storage Protocols
protocol LocalStorageProtocol {
    func saveRecording(_ recording: Recording) async -> DomainResult<Recording>
    func getRecordings(for userId: String) async -> DomainResult<[Recording]>
    func getRecording(by id: String) async -> DomainResult<Recording>
    func deleteRecording(_ recording: Recording) async -> DomainResult<Void>
    func saveAnalysisResult(_ result: VocalBiomarkers) async -> DomainResult<VocalBiomarkers>
    func getAnalysisResults(for userId: String) async -> DomainResult<[VocalBiomarkers]>
    func getLatestAnalysis(for userId: String) async -> DomainResult<VocalBiomarkers?>
}

protocol CloudStorageProtocol {
    func saveRecording(_ recording: Recording) async -> DomainResult<Recording>
    func getRecordings(for userId: String) async -> DomainResult<[Recording]>
    func getRecording(by id: String) async -> DomainResult<Recording>
    func deleteRecording(_ recording: Recording) async -> DomainResult<Void>
    func saveAnalysisResult(_ result: VocalBiomarkers) async -> DomainResult<VocalBiomarkers>
    func getAnalysisResults(for userId: String) async -> DomainResult<[VocalBiomarkers]>
    func getLatestAnalysis(for userId: String) async -> DomainResult<VocalBiomarkers?>
}

protocol NetworkMonitorProtocol {
    var isConnected: Bool { get }
}

// MARK: - Concrete Implementations
final class LocalStorage: LocalStorageProtocol {
    // Implementation using Core Data or UserDefaults
    func saveRecording(_ recording: Recording) async -> DomainResult<Recording> {
        // TODO: Implement local storage
        return .success(recording)
    }
    
    func getRecordings(for userId: String) async -> DomainResult<[Recording]> {
        // TODO: Implement local storage
        return .success([])
    }
    
    func getRecording(by id: String) async -> DomainResult<Recording> {
        // TODO: Implement local storage
        return .failure(VoiceAnalysisError.unknown)
    }
    
    func deleteRecording(_ recording: Recording) async -> DomainResult<Void> {
        // TODO: Implement local storage
        return .success(())
    }
    
    func saveAnalysisResult(_ result: VocalBiomarkers) async -> DomainResult<VocalBiomarkers> {
        // TODO: Implement local storage
        return .success(result)
    }
    
    func getAnalysisResults(for userId: String) async -> DomainResult<[VocalBiomarkers]> {
        // TODO: Implement local storage
        return .success([])
    }
    
    func getLatestAnalysis(for userId: String) async -> DomainResult<VocalBiomarkers?> {
        // TODO: Implement local storage
        return .success(nil)
    }
}

final class CloudStorage: CloudStorageProtocol {
    // Implementation using Firebase Firestore
    func saveRecording(_ recording: Recording) async -> DomainResult<Recording> {
        // TODO: Implement cloud storage
        return .success(recording)
    }
    
    func getRecordings(for userId: String) async -> DomainResult<[Recording]> {
        // TODO: Implement cloud storage
        return .success([])
    }
    
    func getRecording(by id: String) async -> DomainResult<Recording> {
        // TODO: Implement cloud storage
        return .failure(VoiceAnalysisError.unknown)
    }
    
    func deleteRecording(_ recording: Recording) async -> DomainResult<Void> {
        // TODO: Implement cloud storage
        return .success(())
    }
    
    func saveAnalysisResult(_ result: VocalBiomarkers) async -> DomainResult<VocalBiomarkers> {
        // TODO: Implement cloud storage
        return .success(result)
    }
    
    func getAnalysisResults(for userId: String) async -> DomainResult<[VocalBiomarkers]> {
        // TODO: Implement cloud storage
        return .success([])
    }
    
    func getLatestAnalysis(for userId: String) async -> DomainResult<VocalBiomarkers?> {
        // TODO: Implement cloud storage
        return .success(nil)
    }
}

final class NetworkMonitor: NetworkMonitorProtocol {
    var isConnected: Bool {
        // TODO: Implement network monitoring
        return true
    }
} 