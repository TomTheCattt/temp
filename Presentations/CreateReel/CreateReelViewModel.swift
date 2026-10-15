//
//  CreateReelViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import PhotosUI
import Photos
import AVFoundation
import UIKit

// MARK: - Reel Duration Limit

enum ReelDurationLimit: Double, CaseIterable, Identifiable {
    case fifteen = 15.0
    case thirty = 30.0
    case sixty = 60.0
    case ninety = 90.0

    var id: Double { rawValue }
    var title: String { "\(Int(rawValue))s" }
}

// MARK: - Reel Speed

enum ReelSpeed: Double, CaseIterable, Identifiable {
    case slow3x = 0.3
    case slow5x = 0.5
    case normal = 1.0
    case fast2x = 2.0
    case fast3x = 3.0

    var id: Double { rawValue }
    var title: String {
        switch self {
        case .slow3x: return ".3x"
        case .slow5x: return ".5x"
        case .normal: return "1x"
        case .fast2x: return "2x"
        case .fast3x: return "3x"
        }
    }
}

// MARK: - Reel Timer Option

enum ReelTimerOption: Int, CaseIterable, Identifiable {
    case off = 0
    case threeSeconds = 3
    case tenSeconds = 10

    var id: Int { rawValue }
    var title: String {
        switch self {
        case .off: return "Tắt"
        case .threeSeconds: return "3s"
        case .tenSeconds: return "10s"
        }
    }
}

// MARK: - Reel Clip Model

struct ReelClip: Identifiable, Equatable {
    let id: UUID
    let url: URL
    let duration: Double
    let speed: Double
    let thumbnail: UIImage?

    init(id: UUID = UUID(), url: URL, duration: Double, speed: Double = 1.0, thumbnail: UIImage? = nil) {
        self.id = id
        self.url = url
        self.duration = duration
        self.speed = speed
        self.thumbnail = thumbnail
    }
}

// MARK: - CreateReelViewModel

@MainActor
@Observable
final class CreateReelViewModel {

    // MARK: - Recording Settings & Tools

    var selectedDurationLimit: ReelDurationLimit = .fifteen
    var selectedSpeed: ReelSpeed = .normal
    var selectedTimer: ReelTimerOption = .off
    var isGhostEnabled: Bool = false
    var ghostFrame: UIImage? = nil

    // MARK: - Multi-Clip State

    var recordedClips: [ReelClip] = []
    var isRecording = false
    var currentClipDuration: Double = 0.0
    private var recordingTask: Task<Void, Never>?
    private var recordingStartTime: Date?

    var totalRecordedDuration: Double {
        recordedClips.reduce(0.0) { $0 + $1.duration }
    }

    var remainingDuration: Double {
        max(0.0, selectedDurationLimit.rawValue - totalRecordedDuration)
    }

    // MARK: - Countdown State

    var isCountingDown = false
    var countdownRemaining: Int = 0
    private var countdownTask: Task<Void, Never>?

    // MARK: - Camera State

    var isFrontCamera = true
    var isFlashOn = false
    let cameraService: CameraService = .shared

    // MARK: - Gallery State

    var latestGalleryThumbnail: UIImage?
    var isShowingGalleryPicker = false
    var videoPickerItem: PhotosPickerItem?

    // MARK: - Navigation & Screen Steps

    var isShowingEditor = false
    var isShowingTrimmer = false
    var isShowingShareDetails = false

    // MARK: - Final Reel Asset State

    var finalVideoURL: URL?
    var finalVideoData: Data?
    var coverImage: UIImage?
    var caption: String = ""
    var selectedAudioName: String?
    var alsoShareToFeed: Bool = true

    // MARK: - Publishing State

    private(set) var isPublishing = false
    private(set) var isPublished = false

    // MARK: - Dependencies

    private let reelRepository: ReelRepositoryProtocol
    private let photoLibraryService: PhotoLibraryServiceProtocol

    // MARK: - Init

    init(
        reelRepository: ReelRepositoryProtocol,
        photoLibraryService: PhotoLibraryServiceProtocol? = nil
    ) {
        self.reelRepository = reelRepository
        self.photoLibraryService = photoLibraryService ?? DIContainer.shared.resolve(PhotoLibraryServiceProtocol.self)
    }

    // MARK: - Setup

    func setupCamera() async {
        if cameraService.isSessionConfigured {
            isFrontCamera = cameraService.isFrontFacing
        }
        _ = await cameraService.configureSession(isFront: isFrontCamera)
        cameraService.start()
        await loadLatestGalleryThumbnail()
    }

    func stopCamera() {
        stopRecordingTimer()
        cameraService.stop()
    }

    func loadLatestGalleryThumbnail() async {
        guard latestGalleryThumbnail == nil else { return }
        let authorized = await photoLibraryService.requestAuthorization()
        guard authorized else { return }

        let assets = await photoLibraryService.fetchAssets(in: nil, limit: 1)
        if let firstAsset = assets.first {
            latestGalleryThumbnail = await photoLibraryService.loadThumbnail(for: firstAsset.phAsset, targetSize: CGSize(width: 80, height: 80))
        }
    }

    // MARK: - Camera Toggles

    func toggleCamera() {
        isFrontCamera.toggle()
        cameraService.switchCamera(isFront: isFrontCamera)
    }

    func toggleFlash() {
        isFlashOn.toggle()
        cameraService.setTorch(on: isFlashOn)
    }

    func cycleDurationLimit() {
        guard let currentIndex = ReelDurationLimit.allCases.firstIndex(of: selectedDurationLimit) else { return }
        let nextIndex = (currentIndex + 1) % ReelDurationLimit.allCases.count
        selectedDurationLimit = ReelDurationLimit.allCases[nextIndex]
    }

    func cycleSpeed() {
        guard let currentIndex = ReelSpeed.allCases.firstIndex(of: selectedSpeed) else { return }
        let nextIndex = (currentIndex + 1) % ReelSpeed.allCases.count
        selectedSpeed = ReelSpeed.allCases[nextIndex]
    }

    func cycleTimer() {
        guard let currentIndex = ReelTimerOption.allCases.firstIndex(of: selectedTimer) else { return }
        let nextIndex = (currentIndex + 1) % ReelTimerOption.allCases.count
        selectedTimer = ReelTimerOption.allCases[nextIndex]
    }

    func toggleGhost() {
        isGhostEnabled.toggle()
    }

    // MARK: - Recording Actions

    func triggerRecord() {
        if isRecording {
            stopRecording()
            return
        }

        if remainingDuration <= 0.5 {
            HUDManager.shared.showInfo("Đã đạt thời lượng tối đa (\(Int(selectedDurationLimit.rawValue))s)")
            return
        }

        if selectedTimer != .off && !isCountingDown {
            startCountdown()
        } else {
            beginRecording()
        }
    }

    private func startCountdown() {
        isCountingDown = true
        countdownRemaining = selectedTimer.rawValue

        countdownTask?.cancel()
        countdownTask = Task { @MainActor [weak self] in
            while let self, self.isCountingDown, self.countdownRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                self.countdownRemaining -= 1
                if self.countdownRemaining <= 0 {
                    self.isCountingDown = false
                    self.beginRecording()
                    break
                }
            }
        }
    }

    private func beginRecording() {
        isRecording = true
        currentClipDuration = 0.0
        recordingStartTime = Date()
        cameraService.startRecording()

        recordingTask?.cancel()
        recordingTask = Task { @MainActor [weak self] in
            while let self, self.isRecording {
                try? await Task.sleep(nanoseconds: 50_000_000)
                guard !Task.isCancelled else { break }
                if let start = self.recordingStartTime {
                    self.currentClipDuration = Date().timeIntervalSince(start) * self.selectedSpeed.rawValue
                    if (self.totalRecordedDuration + self.currentClipDuration) >= self.selectedDurationLimit.rawValue {
                        self.stopRecording()
                        break
                    }
                }
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        stopRecordingTimer()

        Task {
            do {
                let recordedURL = try await cameraService.stopRecording()
                let clipDuration = max(self.currentClipDuration, 0.5)
                let thumbnail = await self.generateThumbnail(for: recordedURL)

                let clip = ReelClip(
                    url: recordedURL,
                    duration: clipDuration,
                    speed: self.selectedSpeed.rawValue,
                    thumbnail: thumbnail
                )

                self.recordedClips.append(clip)
                self.ghostFrame = thumbnail
                self.currentClipDuration = 0.0
            } catch {
                HUDManager.shared.showError(error.localizedDescription)
            }
        }
    }

    private func stopRecordingTimer() {
        recordingTask?.cancel()
        recordingTask = nil
        countdownTask?.cancel()
        countdownTask = nil
        isCountingDown = false
    }

    // MARK: - Clip Management

    func deleteLastClip() {
        guard !recordedClips.isEmpty else { return }
        recordedClips.removeLast()
        ghostFrame = recordedClips.last?.thumbnail
    }

    func deleteClip(at index: Int) {
        guard index >= 0 && index < recordedClips.count else { return }
        recordedClips.remove(at: index)
        ghostFrame = recordedClips.last?.thumbnail
        if recordedClips.isEmpty {
            isShowingTrimmer = false
        }
    }

    // MARK: - Picker Video Import

    func loadVideoFromPicker() async {
        guard let item = videoPickerItem else { return }

        if let movie = try? await item.loadTransferable(type: Data.self) {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("imported_\(UUID().uuidString).mp4")
            try? movie.write(to: tempURL)

            let asset = AVURLAsset(url: tempURL)
            let durationSeconds = (try? await asset.load(.duration).seconds) ?? 3.0
            let thumbnail = await generateThumbnail(for: tempURL)

            let clip = ReelClip(
                url: tempURL,
                duration: min(durationSeconds, selectedDurationLimit.rawValue),
                speed: 1.0,
                thumbnail: thumbnail
            )

            recordedClips.append(clip)
            ghostFrame = thumbnail
            await proceedToEditor()
        }
    }

    // MARK: - Editor & Merge Pipeline

    func proceedToEditor() async {
        guard !recordedClips.isEmpty else { return }

        HUDManager.shared.showLoading("Đang chuẩn bị video...")
        do {
            let mergedURL = try await mergeClips(recordedClips)
            finalVideoURL = mergedURL
            if let data = try? Data(contentsOf: mergedURL) {
                finalVideoData = data
            }
            coverImage = await generateThumbnail(for: mergedURL)
            HUDManager.shared.dismiss()
            isShowingEditor = true
        } catch {
            HUDManager.shared.showError("Không thể xử lý video: \(error.localizedDescription)")
        }
    }

    private func mergeClips(_ clips: [ReelClip]) async throws -> URL {
        if clips.count == 1, let single = clips.first {
            return single.url
        }

        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            return clips.first!.url
        }

        var currentTime = CMTime.zero

        for clip in clips {
            let asset = AVURLAsset(url: clip.url)
            let assetDuration = try await asset.load(.duration)
            let timeRange = CMTimeRange(start: .zero, duration: assetDuration)

            if let videoTrack = try? await asset.loadTracks(withMediaType: .video).first {
                try? compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: currentTime)
                if let preferredTransform = try? await videoTrack.load(.preferredTransform) {
                    compositionVideoTrack.preferredTransform = preferredTransform
                }
            }
            if let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first {
                try? compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: currentTime)
            }

            currentTime = CMTimeAdd(currentTime, assetDuration)
        }

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("merged_reel_\(UUID().uuidString).mp4")
        try? FileManager.default.removeItem(at: outputURL)

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            return clips.first!.url
        }

        if #available(iOS 18.0, *) {
            do {
                try await exportSession.export(to: outputURL, as: .mp4)
                return outputURL
            } catch {
                return clips.first!.url
            }
        } else {
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            exportSession.shouldOptimizeForNetworkUse = true
            await exportSession.export()
            if exportSession.status == .completed {
                return outputURL
            } else {
                return clips.first!.url
            }
        }
    }

    private func generateThumbnail(for url: URL, at time: CMTime = .zero) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 720, height: 1280)

        do {
            let (cgImage, _) = try await generator.image(at: time)
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
    }

    // MARK: - Publishing

    func publish() async {
        guard let videoData = finalVideoData, !isPublishing else { return }
        isPublishing = true
        HUDManager.shared.showLoading(L10n.HUD.publishing)

        do {
            let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = try await reelRepository.createReel(
                videoData: videoData,
                caption: trimmedCaption.isEmpty ? nil : trimmedCaption,
                audioTrackId: nil
            )
            isPublished = true
            HUDManager.shared.showSuccess(L10n.HUD.published)
        } catch {
            HUDManager.shared.showError(error.userMessage)
        }

        isPublishing = false
    }

    func reset() {
        stopRecordingTimer()
        recordedClips.removeAll()
        videoPickerItem = nil
        finalVideoData = nil
        finalVideoURL = nil
        coverImage = nil
        ghostFrame = nil
        isRecording = false
        isShowingEditor = false
        isShowingTrimmer = false
        isShowingShareDetails = false
        caption = ""
        selectedAudioName = nil
        isPublished = false
    }
}
