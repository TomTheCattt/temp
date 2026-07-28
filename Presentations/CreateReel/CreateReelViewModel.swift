//
//  CreateReelViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import PhotosUI

// MARK: - CreateReelViewModel

@MainActor
@Observable
final class CreateReelViewModel {

    // MARK: - State

    /// Video picker item.
    var videoPickerItem: PhotosPickerItem?

    /// Selected video data.
    var selectedVideoData: Data?

    /// Recording state (for camera capture).
    var isRecording = false
    var isFrontCamera = true

    /// Edit state.
    var caption: String = ""
    var selectedAudioName: String?

    /// Steps.
    var isShowingEditor = false

    /// Publishing.
    private(set) var isPublishing = false
    private(set) var isPublished = false
    private(set) var publishError: String?

    // MARK: - Dependencies

    private let reelRepository: ReelRepositoryProtocol

    // MARK: - Init

    init(reelRepository: ReelRepositoryProtocol) {
        self.reelRepository = reelRepository
    }

    // MARK: - Actions

    func loadVideoFromPicker() async {
        guard let item = videoPickerItem else { return }

        if let data = try? await item.loadTransferable(type: Data.self) {
            selectedVideoData = data
            isShowingEditor = true
        }
    }

    func startRecording() {
        isRecording = true
        // Real: start AVCaptureMovieFileOutput
    }

    func stopRecording() {
        isRecording = false
        selectedVideoData = Data() // Placeholder
        isShowingEditor = true
    }

    func toggleCamera() {
        isFrontCamera.toggle()
    }

    func publish() async {
        guard let videoData = selectedVideoData, !isPublishing else { return }
        isPublishing = true
        publishError = nil

        do {
            let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = try await reelRepository.createReel(
                videoData: videoData,
                caption: trimmedCaption.isEmpty ? nil : trimmedCaption,
                audioTrackId: nil
            )
            isPublished = true
        } catch {
            publishError = error.localizedDescription
        }

        isPublishing = false
    }

    func reset() {
        videoPickerItem = nil
        selectedVideoData = nil
        isRecording = false
        isShowingEditor = false
        caption = ""
        selectedAudioName = nil
        isPublished = false
        publishError = nil
    }
}
