//
//  SageUITests.swift
//  SageUITests
//
//  Created by Ivy Hamilton on 24/7/2025.
//

import XCTest

final class SageUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testOnboardingHeroScreen() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for onboarding hero screen to appear
        let title = app.staticTexts["Stop explaining your symptoms."]
        let subtitle = app.staticTexts["Start proving them."]
        let nextButton = app.buttons["Continue to next onboarding screen"]

        XCTAssertTrue(title.waitForExistence(timeout: 3), "Hero title should appear")
        XCTAssertTrue(subtitle.exists, "Hero subtitle should appear")
        XCTAssertTrue(nextButton.exists, "Next button should appear")

        // VoiceOver: Check accessibility labels
        XCTAssertEqual(title.label, "Stop explaining your symptoms.")
        XCTAssertEqual(subtitle.label, "Start proving them.")
        XCTAssertEqual(nextButton.label, "Continue to next onboarding screen")

        // Tap Next and verify navigation
        nextButton.tap()
        let entryTitle = app.staticTexts["Start Your First Entry"]
        XCTAssertTrue(entryTitle.waitForExistence(timeout: 2), "Should navigate to onboarding step 2")
    }

    @MainActor
    func testEndToEnd_AcousticFeatureExtraction() throws {
        let app = XCUIApplication()
        app.launch()

        // 1. Navigate to the recording screen
        app.tabBars.buttons["Record"].tap()

        // 2. Start and stop a recording (simulate ~5s sustained vowel)
        let startButton = app.buttons["Start Recording"]
        let stopButton = app.buttons["Stop Recording"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3), "Start Recording button should exist")
        startButton.tap()
        sleep(5) // Simulate 5 seconds of audio
        XCTAssertTrue(stopButton.exists, "Stop Recording button should exist")
        stopButton.tap()

        // 3. Confirm upload if prompted
        if app.alerts["Upload"].exists {
            app.alerts["Upload"].buttons["OK"].tap()
        }

        // 4. Wait for backend processing (poll for insights)
        // We'll check for the presence of all required features in the UI
        let featureLabels = [
            // Fundamental Frequency (F0) – §3.2.1
            "F0_mean", "F0_min", "F0_max", "F0_sd",
            // Jitter – §3.2.2
            "jitter_local_pct", "jitter_rap_pct",
            // Shimmer – §3.2.3
            "shimmer_local_dB",
            // HNR – §3.2.4
            "HNR_dB",
            // Formants – §3.2.5
            "formant1_mean", "formant2_mean", "formant3_mean", "formant4_mean",
            // MFCCs – §3.2.6
            "MFCC1", "MFCC2", "MFCC3", "MFCC4", "MFCC5", "MFCC6", "MFCC7", "MFCC8", "MFCC9", "MFCC10", "MFCC11", "MFCC12", "MFCC13",
            // Intensity – §3.2.7
            "intensity_mean", "intensity_sd",
            // Speaking Rate – §3.2.8
            "speaking_rate",
            // Voice Breaks – §3.2.9
            "voice_breaks_ratio",
            // Spectral Centroid – §3.2.10
            "spectral_centroid_mean",
            // Band Energies – §3.2.11
            "band_energy_low", "band_energy_mid", "band_energy_high",
            // Task-specific – §3.2.12
            "max_phonation_time"
        ]

        for label in featureLabels {
            let feature = app.staticTexts[label]
            let exists = NSPredicate(format: "exists == true && label.length > 0")
            expectation(for: exists, evaluatedWith: feature, handler: nil)
        }
        waitForExpectations(timeout: 90) // Wait up to 90 seconds for all features

        // 5. Assert plausible scientific ranges for a few key features
        let f0Mean = Double(app.staticTexts["F0_mean"].label) ?? 0
        XCTAssertTrue(f0Mean >= 75 && f0Mean <= 500, "F0_mean should be in 75–500 Hz range (see DATA_STANDARDS.md §3.2.1)")
        let jitter = Double(app.staticTexts["jitter_local_pct"].label) ?? 0
        XCTAssertTrue(jitter >= 0 && jitter < 5, "Jitter should be plausible (see DATA_STANDARDS.md §3.2.2)")
        let shimmer = Double(app.staticTexts["shimmer_local_dB"].label) ?? 0
        XCTAssertTrue(shimmer >= 0 && shimmer < 2, "Shimmer should be plausible (see DATA_STANDARDS.md §3.2.3)")
        let hnr = Double(app.staticTexts["HNR_dB"].label) ?? 0
        XCTAssertTrue(hnr >= 0 && hnr <= 40, "HNR should be plausible (see DATA_STANDARDS.md §3.2.4)")

        // 6. (Optional) Check analytics event for feature extraction
        // This would require exposing analytics logs or a test hook in the app
        // e.g., XCTAssertTrue(app.staticTexts["AnalyticsEvent_feature_extracted"].exists)
    }
}
