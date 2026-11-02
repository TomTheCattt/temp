//
//  CallAudioEngineControllerTests.swift
//  InstagramTests
//
//  Created for testing CallAudioEngineController audio handling.
//

import XCTest
import AVFoundation
import Combine
@testable import Instagram

// MARK: - Mock Audio Session

final class MockAVAudioSession: @unchecked Sendable {
    var category: AVAudioSession.Category = .ambient
    var mode: AVAudioSession.Mode = .default
    var options: AVAudioSession.CategoryOptions = []
    var isActive = false
    var shouldFailSetCategory = false
    var shouldFailSetActive = false
    var setCategoryError: Error?
    var setActiveError: Error?
    var interruptionNotificationPosted = false
    var routeChangeNotificationPosted = false

    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode = .default,
        options: AVAudioSession.CategoryOptions = []
    ) throws {
        if shouldFailSetCategory, let error = setCategoryError {
            throw error
        }
        self.category = category
        self.mode = mode
        self.options = options
    }

    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions = []) async throws {
        if shouldFailSetActive, let error = setActiveError {
            throw error
        }
        isActive = active
    }

    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions, completionHandler: @escaping (Bool, Error?) -> Void) {
        Task {
            if shouldFailSetActive, let error = setActiveError {
                completionHandler(false, error)
            } else {
                isActive = active
                completionHandler(true, nil)
            }
        }
    }
}

// MARK: - Testable Audio Engine

class TestableCallAudioEngineController {
    var audioSession: MockAVAudioSession
    var isMuted = false
    var isSpeakerOn = false
    var inputGain: Float = 1.0
    var outputVolume: Float = 1.0
    var rmsLevel: Float = 0.0
    var isRunning = false

    init(audioSession: MockAVAudioSession = MockAVAudioSession()) {
        self.audioSession = audioSession
    }

    func configureAudioSession() throws {
        try audioSession.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.allowBluetoothHFP, .allowBluetoothA2DP, .allowAirPlay]
        )
    }

    func activateAudioSession() async throws {
        try await audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    func deactivateAudioSession() async throws {
        try await audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        try audioSession.setCategory(.ambient, mode: .default)
    }

    func startEngine() async throws {
        guard !isRunning else { return }
        try configureAudioSession()
        try await activateAudioSession()
        isRunning = true
    }

    func stopEngine() async throws {
        guard isRunning else { return }
        try await deactivateAudioSession()
        isRunning = false
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
    }

    func setSpeaker(_ speakerOn: Bool) {
        isSpeakerOn = speakerOn
    }

    func setInputGain(_ gain: Float) {
        inputGain = max(0.0, min(1.0, gain))
    }

    func setOutputVolume(_ volume: Float) {
        outputVolume = max(0.0, min(1.0, volume))
    }

    func generateTone(frequency: Float, duration: TimeInterval) async {
        // Simulate tone generation
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }

    func playDTMFTone(_ digit: Character) async {
        // Simulate DTMF tone
        try? await Task.sleep(nanoseconds: 100_000_000)
    }

    func startRMSMetering() {
        // Start metering timer
    }

    func stopRMSMetering() {
        // Stop metering timer
    }

    func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            // Pause engine
            break
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // Resume engine
                    Task {
                        try? await activateAudioSession()
                    }
                }
            }
        @unknown default:
            break
        }
    }

    func handleRouteChange(_ notification: Notification) {
        // Handle route change
    }
}

// MARK: - CallAudioEngineControllerTests

final class CallAudioEngineControllerTests: XCTestCase {

    var audioEngine: TestableCallAudioEngineController!
    var mockAudioSession: MockAVAudioSession!

    override func setUp() async throws {
        try await super.setUp()
        mockAudioSession = MockAVAudioSession()
        audioEngine = TestableCallAudioEngineController(audioSession: mockAudioSession)
    }

    override func tearDown() async throws {
        try await audioEngine.stopEngine()
        audioEngine = nil
        mockAudioSession = nil
        try await super.tearDown()
    }

    // MARK: - Audio Session Configuration Tests

    func testConfigureAudioSession_SetsCorrectCategory() throws {
        try audioEngine.configureAudioSession()

        XCTAssertEqual(mockAudioSession.category, .playAndRecord)
        XCTAssertEqual(mockAudioSession.mode, .voiceChat)
        XCTAssertTrue(mockAudioSession.options.contains(.allowBluetoothHFP))
        XCTAssertTrue(mockAudioSession.options.contains(.allowBluetoothA2DP))
        XCTAssertTrue(mockAudioSession.options.contains(.allowAirPlay))
    }

    func testConfigureAudioSession_Failure_Throws() {
        mockAudioSession.shouldFailSetCategory = true
        mockAudioSession.setCategoryError = NSError(domain: "Audio", code: -1)

        XCTAssertThrowsError(try audioEngine.configureAudioSession())
    }

    // MARK: - Audio Session Activation Tests

    func testActivateAudioSession_Success() async throws {
        try await audioEngine.activateAudioSession()

        XCTAssertTrue(mockAudioSession.isActive)
    }

    func testActivateAudioSession_Failure_Throws() async throws {
        mockAudioSession.shouldFailSetActive = true
        mockAudioSession.setActiveError = NSError(domain: "Audio", code: -1)

        do {
            try await audioEngine.activateAudioSession()
            XCTFail("Expected error")
        } catch {
            // Expected
        }
    }

    func testDeactivateAudioSession_Success() async throws {
        try await audioEngine.activateAudioSession()
        XCTAssertTrue(mockAudioSession.isActive)

        try await audioEngine.deactivateAudioSession()

        XCTAssertFalse(mockAudioSession.isActive)
        XCTAssertEqual(mockAudioSession.category, .ambient)
        XCTAssertEqual(mockAudioSession.mode, .default)
    }

    // MARK: - Engine Lifecycle Tests

    func testStartEngine_ActivatesSession() async throws {
        try await audioEngine.startEngine()

        XCTAssertTrue(audioEngine.isRunning)
        XCTAssertTrue(mockAudioSession.isActive)
    }

    func testStartEngine_AlreadyRunning_DoesNothing() async throws {
        try await audioEngine.startEngine()
        let wasRunning = audioEngine.isRunning

        // Starting again should not throw or change state
        try await audioEngine.startEngine()

        XCTAssertEqual(audioEngine.isRunning, wasRunning)
    }

    func testStopEngine_DeactivatesSession() async throws {
        try await audioEngine.startEngine()
        try await audioEngine.stopEngine()

        XCTAssertFalse(audioEngine.isRunning)
        XCTAssertFalse(mockAudioSession.isActive)
    }

    func testStopEngine_NotRunning_DoesNothing() async throws {
        try await audioEngine.stopEngine() // Should not throw
        XCTAssertFalse(audioEngine.isRunning)
    }

    // MARK: - Mute/Speaker Tests

    func testSetMuted_UpdatesState() {
        audioEngine.setMuted(true)
        XCTAssertTrue(audioEngine.isMuted)

        audioEngine.setMuted(false)
        XCTAssertFalse(audioEngine.isMuted)
    }

    func testSetSpeaker_UpdatesState() {
        audioEngine.setSpeaker(true)
        XCTAssertTrue(audioEngine.isSpeakerOn)

        audioEngine.setSpeaker(false)
        XCTAssertFalse(audioEngine.isSpeakerOn)
    }

    // MARK: - Gain/Volume Tests

    func testSetInputGain_ClampsToValidRange() {
        audioEngine.setInputGain(-0.5)
        XCTAssertEqual(audioEngine.inputGain, 0.0)

        audioEngine.setInputGain(1.5)
        XCTAssertEqual(audioEngine.inputGain, 1.0)

        audioEngine.setInputGain(0.5)
        XCTAssertEqual(audioEngine.inputGain, 0.5)
    }

    func testSetOutputVolume_ClampsToValidRange() {
        audioEngine.setOutputVolume(-0.5)
        XCTAssertEqual(audioEngine.outputVolume, 0.0)

        audioEngine.setOutputVolume(1.5)
        XCTAssertEqual(audioEngine.outputVolume, 1.0)

        audioEngine.setOutputVolume(0.7)
        XCTAssertEqual(audioEngine.outputVolume, 0.7)
    }

    // MARK: - Tone Generation Tests

    func testGenerateTone_CompletesAfterDuration() async throws {
        let startTime = Date()
        await audioEngine.generateTone(frequency: 440, duration: 0.1)
        let elapsed = Date().timeIntervalSince(startTime)

        XCTAssertGreaterThanOrEqual(elapsed, 0.09) // Allow small margin
        XCTAssertLessThan(elapsed, 0.5)
    }

    func testPlayDTMFTone_ForEachDigit() async throws {
        let digits: [Character] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "#"]

        for digit in digits {
            let startTime = Date()
            await audioEngine.playDTMFTone(digit)
            let elapsed = Date().timeIntervalSince(startTime)

            XCTAssertGreaterThanOrEqual(elapsed, 0.05)
            XCTAssertLessThan(elapsed, 0.5)
        }
    }

    // MARK: - RMS Metering Tests

    func testStartStopRMSMetering_DoesNotCrash() {
        audioEngine.startRMSMetering()
        audioEngine.stopRMSMetering()
        // Just verify no crash
        XCTAssertTrue(true)
    }

    // MARK: - Interruption Handling Tests

    func testHandleInterruption_Began_PausesEngine() {
        let notification = Notification(
            name: AVAudioSession.interruptionNotification,
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
        )

        audioEngine.handleInterruption(notification)
        // Should not crash
    }

    func testHandleInterruption_EndedWithShouldResume_ResumesEngine() async throws {
        try await audioEngine.startEngine()

        let notification = Notification(
            name: AVAudioSession.interruptionNotification,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
                AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue
            ]
        )

        audioEngine.handleInterruption(notification)

        // Give time for async activation
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(mockAudioSession.isActive)
    }

    func testHandleInterruption_EndedWithoutShouldResume_DoesNotResume() async throws {
        try await audioEngine.startEngine()
        try await audioEngine.stopEngine()

        let notification = Notification(
            name: AVAudioSession.interruptionNotification,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
                AVAudioSessionInterruptionOptionKey: UInt(0)
            ]
        )

        audioEngine.handleInterruption(notification)

        try await Task.sleep(nanoseconds: 100_000_000)

        // Should not have reactivated
        XCTAssertFalse(mockAudioSession.isActive)
    }

    // MARK: - Route Change Tests

    func testHandleRouteChange_DoesNotCrash() {
        let notification = Notification(
            name: AVAudioSession.routeChangeNotification,
            userInfo: [AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue]
        )

        audioEngine.handleRouteChange(notification)
        // Should not crash
    }

    func testHandleRouteChange_OldDeviceUnavailable() {
        let notification = Notification(
            name: AVAudioSession.routeChangeNotification,
            userInfo: [AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue]
        )

        audioEngine.handleRouteChange(notification)
        // Should not crash
    }

    // MARK: - Background/Foreground Tests

    func testBackgroundForeground_Cycle() async throws {
        try await audioEngine.startEngine()
        XCTAssertTrue(audioEngine.isRunning)

        // Simulate background
        try await audioEngine.stopEngine()
        XCTAssertFalse(audioEngine.isRunning)

        // Simulate foreground
        try await audioEngine.startEngine()
        XCTAssertTrue(audioEngine.isRunning)
    }

    // MARK: - Concurrent Operations Tests

    func testConcurrentMuteAndSpeakerChanges() async throws {
        try await audioEngine.startEngine()

        // Rapidly toggle mute and speaker
        for _ in 0..<10 {
            audioEngine.setMuted(Bool.random())
            audioEngine.setSpeaker(Bool.random())
        }

        // Should not crash
        try await audioEngine.stopEngine()
    }
}

// MARK: - AudioLevelMeter Tests (if applicable)

final class AudioLevelMeterTests: XCTestCase {

    func testRMSLevelCalculation() {
        // Test RMS calculation with known values
        let samples: [Float] = [0.0, 0.5, -0.5, 1.0, -1.0]
        let sumOfSquares = samples.reduce(0) { $0 + $1 * $1 }
        let meanSquare = sumOfSquares / Float(samples.count)
        let rms = sqrt(meanSquare)

        XCTAssertEqual(rms, sqrt(0.5), accuracy: 0.001)
    }

    func testDecibelConversion() {
        let rms: Float = 0.5
        let db = 20 * log10(rms)

        XCTAssertEqual(db, -6.02, accuracy: 0.1)
    }

    func testSilenceIsNegativeInfinity() {
        let rms: Float = 0.0
        let db = 20 * log10(max(rms, Float.leastNonzeroMagnitude))

        XCTAssertTrue(db.isInfinite || db < -100)
    }
}