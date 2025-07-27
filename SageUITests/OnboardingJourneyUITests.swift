import XCTest

class OnboardingJourneyUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = ["-UITesting"]  
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Signup Screen Tests

    func testSignupOptionsAreVisible() {
        // Given launch of the app
        XCTAssertTrue(app.buttons["Get Started"].exists)
        XCTAssertTrue(app.buttons["I already have an account"].exists)
    }

    func testSelectingGetStartedShowsSignupMethodOptions() {
        // When tapping "Get Started"
        app.buttons["Get Started"].tap()

        // Then options appear
        XCTAssertTrue(app.buttons["Continue Anonymously"].exists)
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
    }

    // MARK: - Anonymous Signup Flow

    func testAnonymousSignupNavigationToExplainer() {
        app.buttons["Get Started"].tap()
        app.buttons["Continue Anonymously"].tap()

        XCTAssertTrue(app.staticTexts["Let's run some quick tests"].exists)
        XCTAssertTrue(app.buttons["Begin"].exists)
    }

    // MARK: - Email Signup Flow with Errors

    func testEmailSignupShowsErrorWhenEmailAlreadyInUse() {
        app.buttons["Get Started"].tap()
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]

        emailField.tap(); emailField.typeText("existing@example.com")
        passwordField.tap(); passwordField.typeText("password123")
        app.buttons["Sign Up"].tap()

        // Then error alert shown
        XCTAssertTrue(app.alerts["Error"].exists)
        XCTAssertTrue(app.alerts["Error"].staticTexts["This email is already registered. Try signing in instead."].exists)
        app.alerts["Error"].buttons["OK"].tap()
    }

    func testEmailSignupShowsNetworkErrorWhenOffline() {
        // Simulate offline: using launch arguments or mock
        app.launchArguments.append(contentsOf: ["-MockAuthNetworkError"])
        app.launch()

        app.buttons["Get Started"].tap()
        app.textFields["Email"].tap().typeText("test@example.com")
        app.secureTextFields["Password"].tap().typeText("password123")
        app.buttons["Sign Up"].tap()

        XCTAssertTrue(app.alerts["Error"].exists)
        XCTAssertTrue(app.alerts["Error"].staticTexts["Check your internet connection and try again."].exists)
        app.alerts["Error"].buttons["OK"].tap()
    }

    // MARK: - Explainer Screen

    func testBeginButtonAdvancesToVocalTest() {
        app.buttons["Get Started"].tap()
        app.buttons["Continue Anonymously"].tap()
        app.buttons["Begin"].tap()

        XCTAssertTrue(app.staticTexts["Please say 'ahh' for 10 seconds."].exists)
        XCTAssertTrue(app.buttons["Begin"].exists)
    }

    // MARK: - Microphone Permission Flow

    func testMicrophonePermissionDeniedShowsError() {
        app.launchArguments.append(contentsOf: ["-MockMicPermissionDenied"])
        app.launch()

        app.buttons["Get Started"].tap()
        app.buttons["Continue Anonymously"].tap()
        app.buttons["Begin"].tap()

        // On the vocal test screen, tap the Begin record button
        app.buttons["Begin"].tap()

        XCTAssertTrue(app.staticTexts["Microphone access is required. Enable it in Settings to continue."].exists)
    }

    // MARK: - Recording UI Indicators

    func testRecordingIndicatorsAppearAndUploadFlow() {
        app.launchArguments.append(contentsOf: ["-MockMicPermissionGranted"])
        app.launch()

        app.buttons["Get Started"].tap()
        app.buttons["Continue Anonymously"].tap()
        app.buttons["Begin"].tap()

        app.buttons["Begin"].tap() // start recording

        // Countdown, progress bar, and waveform should appear
        XCTAssertTrue(app.otherElements["CountdownTimer"].exists)
        XCTAssertTrue(app.otherElements["ProgressBar"].exists)
        XCTAssertTrue(app.otherElements["WaveformView"].exists)

        // Wait simulated duration
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 15))
        XCTAssertTrue(nextButton.exists)

        nextButton.tap()
        XCTAssertTrue(app.navigationBars["Reading Prompt"].exists)
    }

    // MARK: - Final Step Navigation

    func testFinishButtonNavigatesToHome() {
        app.launchArguments.append(contentsOf: ["-MockMicPermissionGranted"])
        app.launch()

        app.buttons["Get Started"].tap()
        app.buttons["Continue Anonymously"].tap()
        app.buttons["Begin"].tap()
        app.buttons["Begin"].tap()

        _ = app.buttons["Next"].waitForExistence(timeout: 15)
        app.buttons["Next"].tap()
        XCTAssertTrue(app.buttons["Finish"].exists)

        app.buttons["Finish"].tap()
        XCTAssertTrue(app.otherElements["HomeView"].exists) // replace with actual home view identifier
    }
}
