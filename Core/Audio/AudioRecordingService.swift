//
//  AudioRecordingService.swift
//  Instagram
//
//  Created by Antigravity on 22/10/26.
//

import Foundation
import AVFoundation

// MARK: - AudioRecordingError

public enum AudioRecordingError: LocalizedError, Sendable {
    case permissionDenied
    case callInProgress
    case recorderCreationFailed
    case recordingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Ứng dụng chưa được cấp quyền truy cập Microphone."
        case .callInProgress:
            return "Không thể ghi âm khi đang có cuộc gọi diễn ra."
        case .recorderCreationFailed:
            return "Không thể khởi tạo bộ ghi âm."
        case .recordingFailed(let reason):
            return "Ghi âm thất bại: \(reason)"
        }
    }
}

// MARK: - AudioRecordingServiceProtocol

public protocol AudioRecordingServiceProtocol: Sendable {
    func requestPermission() async -> Bool
    func startRecording() async throws -> URL
    func stopRecording() async throws -> (url: URL, duration: TimeInterval)?
    func cancelRecording() async
    func getRecordingDuration() async -> TimeInterval
    func isCurrentlyRecording() async -> Bool
}

// MARK: - AudioRecordingService

/// Background Actor managing AVAudioRecorder for voice messages.
/// Runs completely off the Main Thread for zero UI blocking.
public actor AudioRecordingService: AudioRecordingServiceProtocol {

    public static let shared = AudioRecordingService()

    private var audioRecorder: AVAudioRecorder?
    private var currentFileURL: URL?
    private var recordingStartTime: Date?

    public init() {}

    // MARK: - Permission

    public func requestPermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Recording Lifecycle

    public func startRecording() async throws -> URL {
        // Guard against active phone/video calls
        let callActive = await MainActor.run { CallManager.shared.hasActiveCall }
        guard !callActive else {
            throw AudioRecordingError.callInProgress
        }

        // Check or request microphone permission
        let hasPermission = await requestPermission()
        guard hasPermission else {
            throw AudioRecordingError.permissionDenied
        }

        // Configure Audio Session
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw AudioRecordingError.recordingFailed("Không thể cấu hình Audio Session: \(error.localizedDescription)")
        }

        // Prepare file URL in temporary directory
        let filename = "voice_\(UUID().uuidString).m4a"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        currentFileURL = fileURL

        // Settings: AAC, 44.1kHz, Mono, 64kbps (optimized size & high vocal fidelity)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 64000
        ]

        do {
            let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder.isMeteringEnabled = true
            guard recorder.record() else {
                throw AudioRecordingError.recorderCreationFailed
            }
            audioRecorder = recorder
            recordingStartTime = Date()
            return fileURL
        } catch {
            throw AudioRecordingError.recordingFailed(error.localizedDescription)
        }
    }

    public func stopRecording() async throws -> (url: URL, duration: TimeInterval)? {
        guard let recorder = audioRecorder, let fileURL = currentFileURL else {
            return nil
        }

        let calculatedDuration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0
        recorder.stop()
        audioRecorder = nil
        recordingStartTime = nil
        currentFileURL = nil

        // Deactivate Audio Session in background
        Task.detached(priority: .utility) {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }

        // Filter out accidental taps under 0.6 seconds
        guard calculatedDuration >= 0.6 else {
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }

        return (fileURL, calculatedDuration)
    }

    public func cancelRecording() async {
        if let recorder = audioRecorder {
            recorder.stop()
            audioRecorder = nil
        }
        if let fileURL = currentFileURL {
            try? FileManager.default.removeItem(at: fileURL)
            currentFileURL = nil
        }
        recordingStartTime = nil

        Task.detached(priority: .utility) {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    public func getRecordingDuration() async -> TimeInterval {
        guard let start = recordingStartTime else { return 0 }
        return Date().timeIntervalSince(start)
    }

    public func isCurrentlyRecording() async -> Bool {
        audioRecorder?.isRecording ?? false
    }
}
