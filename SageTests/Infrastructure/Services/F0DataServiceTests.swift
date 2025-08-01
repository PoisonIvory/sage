import XCTest
import FirebaseFirestore
import FirebaseAuth
@testable import Sage

// MARK: - Mock Timer Handler for Testing

class MockTimerHandler: TimerHandler {
    var scheduledCallbacks: [() -> Void] = []
    var isCancelled = false
    
    func schedule(timeout: TimeInterval, callback: @escaping () -> Void) {
        scheduledCallbacks.append(callback)
        isCancelled = false
    }
    
    func cancel() {
        isCancelled = true
        scheduledCallbacks.removeAll()
    }
    
    func triggerTimeout() {
        guard !isCancelled else { return }
        for callback in scheduledCallbacks {
            callback()
        }
        scheduledCallbacks.removeAll()
    }
}

@MainActor
class F0DataServiceTests: XCTestCase {
    var f0DataService: F0DataService!
    var mockTimerHandler: MockTimerHandler!
    
    override func setUp() {
        super.setUp()
        mockTimerHandler = MockTimerHandler()
        f0DataService = F0DataService(timerHandler: mockTimerHandler)
    }
    
    override func tearDown() {
        f0DataService.stopListening()
        f0DataService = nil
        mockTimerHandler = nil
        super.tearDown()
    }
    
    // MARK: - User Flow Tests
    
    func testUserOpensVoiceDashboard() {
        // Given: User opens the voice dashboard
        // When: F0DataService is initialized
        // Then: Should show default processing state
        XCTAssertEqual(f0DataService.displayF0Value, "Still Processing...")
        XCTAssertEqual(f0DataService.f0Confidence, 0.0)
        XCTAssertFalse(f0DataService.isLoading)
        XCTAssertNil(f0DataService.errorMessage)
    }
    
    func testUserStopsListeningForUpdates() async {
        // Given: User is viewing voice analysis results
        
        // When: User stops listening for updates
        await f0DataService.stopListening()
        
        // Then: Should reset to default state and clean up resources
        XCTAssertEqual(f0DataService.displayF0Value, "Still Processing...")
        XCTAssertEqual(f0DataService.f0Confidence, 0.0)
        XCTAssertFalse(f0DataService.isLoading)
        XCTAssertNil(f0DataService.errorMessage)
        XCTAssertTrue(mockTimerHandler.isCancelled)
    }
    
    func testUserSeesProcessingTimeout() {
        // Given: User is waiting for voice analysis results
        
        // When: Processing takes longer than expected
        // Then: Should have reasonable timeout for Cloud Function processing
        XCTAssertGreaterThan(f0DataService.processingTimeout, 30.0) // At least 30 seconds
        XCTAssertLessThan(f0DataService.processingTimeout, 120.0) // No more than 2 minutes
    }
    
    func testUserReceivesTimerUpdates() {
        // Given: User is monitoring voice analysis progress
        let realTimerHandler = RealTimerHandler()
        
        // When: Timer is scheduled for processing updates
        var callbackCalled = false
        realTimerHandler.schedule(timeout: 0.1) {
            callbackCalled = true
        }
        
        // Then: Timer should be scheduled and fire correctly
        XCTAssertFalse(callbackCalled)
        
        let expectation = XCTestExpectation(description: "Timer callback")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.3)
        XCTAssertTrue(callbackCalled)
    }
    
    func testUserCancelsTimerUpdates() {
        // Given: User is monitoring voice analysis progress
        let realTimerHandler = RealTimerHandler()
        
        // When: User cancels timer before it fires
        var callbackCalled = false
        realTimerHandler.schedule(timeout: 0.1) {
            callbackCalled = true
        }
        realTimerHandler.cancel()
        
        // Then: Timer should be cancelled and not fire
        let expectation = XCTestExpectation(description: "Timer should not fire")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.3)
        XCTAssertFalse(callbackCalled)
    }
}

// MARK: - Mock Classes

class MockFirestore: Firestore {
    var mockQueryResponse: [MockDocumentSnapshot] = []
    var mockSnapshotListenerResponse: [MockDocumentSnapshot] = []
    var wasListenerRemoved = false
    
    func setupMockQueryResponse(documents: [MockDocumentSnapshot]) {
        mockQueryResponse = documents
    }
    
    func setupMockSnapshotListenerResponse(documents: [MockDocumentSnapshot]) {
        mockSnapshotListenerResponse = documents
    }
    
    func simulateSnapshotListenerUpdate(documents: [MockDocumentSnapshot]) {
        mockSnapshotListenerResponse = documents
        // In a real implementation, this would trigger the snapshot listener callback
    }
}

class MockAuth: Auth {
    var currentUser: MockUser?
    
    override var currentUser: User? {
        return currentUser
    }
}

class MockUser: User {
    let uid: String
    
    init(uid: String) {
        self.uid = uid
    }
}

// Mock document snapshot that doesn't subclass DocumentSnapshot
struct MockDocumentSnapshot {
    let documentID: String
    let data: [String: Any]
    
    init(documentID: String, data: [String: Any]) {
        self.documentID = documentID
        self.data = data
    }
    
    func data() -> [String: Any]? {
        return data
    }
} 