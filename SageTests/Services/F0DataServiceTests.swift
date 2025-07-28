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
    
    // MARK: - Snapshot Listener Tests
    
    func testUserSelectsVocalTest_WhenServiceInitialized_HasCorrectDefaults() {
        // Given: F0DataService is initialized
        // When: Checking initial state
        // Then: Should have correct defaults
        XCTAssertEqual(f0DataService.displayF0Value, "Still Processing...")
        XCTAssertEqual(f0DataService.f0Confidence, 0.0)
        XCTAssertFalse(f0DataService.isLoading)
        XCTAssertNil(f0DataService.errorMessage)
    }
    
    func testUserStopsListening_CleansUpResources() async {
        // Given: F0DataService is initialized
        
        // When: User stops listening
        await f0DataService.stopListening()
        
        // Then: Should clean up resources and reset state
        XCTAssertEqual(f0DataService.displayF0Value, "Still Processing...")
        XCTAssertEqual(f0DataService.f0Confidence, 0.0)
        XCTAssertFalse(f0DataService.isLoading)
        XCTAssertNil(f0DataService.errorMessage)
        
        // Verify timer was cancelled
        XCTAssertTrue(mockTimerHandler.isCancelled)
    }
    
    // MARK: - Constants and Configuration Tests
    
    func testF0AnalysisConstant_IsUsedConsistently() {
        // Given: F0DataService uses FirestoreKeys.f0Analysis constant
        // When: Processing F0 data
        // Then: Should use consistent constant value
        XCTAssertEqual(FirestoreKeys.f0Analysis, "f0_analysis")
    }
    
    func testProcessingTimeout_IsReasonable() {
        // Given: F0DataService has a processing timeout
        // When: Checking timeout value
        // Then: Should be reasonable for Cloud Function processing
        XCTAssertGreaterThan(f0DataService.processingTimeout, 30.0) // At least 30 seconds
        XCTAssertLessThan(f0DataService.processingTimeout, 120.0) // No more than 2 minutes
    }
    
    // MARK: - Timer Handler Tests
    
    func testRealTimerHandler_SchedulesAndCancelsCorrectly() {
        // Given: Real timer handler
        let realTimerHandler = RealTimerHandler()
        
        // When: Scheduling a timer
        var callbackCalled = false
        realTimerHandler.schedule(timeout: 0.1) {
            callbackCalled = true
        }
        
        // Then: Timer should be scheduled
        XCTAssertFalse(callbackCalled)
        
        // When: Waiting for timer to fire
        let expectation = XCTestExpectation(description: "Timer callback")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.3)
        
        // Then: Callback should have been called
        XCTAssertTrue(callbackCalled)
    }
    
    func testRealTimerHandler_CancelsCorrectly() {
        // Given: Real timer handler
        let realTimerHandler = RealTimerHandler()
        
        // When: Scheduling and immediately cancelling
        var callbackCalled = false
        realTimerHandler.schedule(timeout: 0.1) {
            callbackCalled = true
        }
        realTimerHandler.cancel()
        
        // When: Waiting longer than timeout
        let expectation = XCTestExpectation(description: "Timer should not fire")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.3)
        
        // Then: Callback should not have been called
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