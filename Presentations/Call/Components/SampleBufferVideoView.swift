//
//  SampleBufferVideoView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import AVFoundation
import CoreMedia
import Combine

// MARK: - SampleBufferContainerView

/// High-performance UIView hosting an AVSampleBufferDisplayLayer directly on GPU.
final class SampleBufferContainerView: UIView {

    override class var layerClass: AnyClass {
        AVSampleBufferDisplayLayer.self
    }

    var sampleBufferLayer: AVSampleBufferDisplayLayer {
        layer as! AVSampleBufferDisplayLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        backgroundColor = .black
        sampleBufferLayer.videoGravity = .resizeAspectFill
        sampleBufferLayer.preventsDisplaySleepDuringVideoPlayback = true
    }

    /// Safely enqueues a new video CMSampleBuffer to hardware display layer.
    func enqueue(_ sampleBuffer: CMSampleBuffer) {
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true) {
            let dict = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
            CFDictionarySetValue(
                dict,
                unsafeBitCast(kCMSampleAttachmentKey_DisplayImmediately, to: UnsafeRawPointer.self),
                unsafeBitCast(kCFBooleanTrue, to: UnsafeRawPointer.self)
            )
        }

        if #available(iOS 17.0, *) {
            let renderer = sampleBufferLayer.sampleBufferRenderer
            if renderer.status == .failed {
                renderer.flush()
            }
            if renderer.isReadyForMoreMediaData {
                renderer.enqueue(sampleBuffer)
            }
        } else {
            if sampleBufferLayer.status == .failed {
                sampleBufferLayer.flush()
            }
            if sampleBufferLayer.isReadyForMoreMediaData {
                sampleBufferLayer.enqueue(sampleBuffer)
            }
        }
    }

    /// Clears any queued image frames immediately.
    func flush() {
        if #available(iOS 17.0, *) {
            sampleBufferLayer.sampleBufferRenderer.flush()
        } else {
            sampleBufferLayer.flushAndRemoveImage()
        }
    }
}

// MARK: - SampleBufferVideoView

/// SwiftUI wrapper around AVSampleBufferDisplayLayer for hardware-accelerated zero-copy video rendering.
struct SampleBufferVideoView: UIViewRepresentable {

    private let publisher: AnyPublisher<CMSampleBuffer, Never>
    private let videoGravity: AVLayerVideoGravity

    init(
        publisher: AnyPublisher<CMSampleBuffer, Never>,
        videoGravity: AVLayerVideoGravity = .resizeAspectFill
    ) {
        self.publisher = publisher
        self.videoGravity = videoGravity
    }

    init(
        sampleBufferPublisher: AnyPublisher<CMSampleBuffer, Never>,
        videoGravity: AVLayerVideoGravity = .resizeAspectFill
    ) {
        self.publisher = sampleBufferPublisher
        self.videoGravity = videoGravity
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SampleBufferContainerView {
        let view = SampleBufferContainerView()
        view.sampleBufferLayer.videoGravity = videoGravity
        context.coordinator.subscribe(to: publisher, view: view)
        return view
    }

    func updateUIView(_ uiView: SampleBufferContainerView, context: Context) {
        if uiView.sampleBufferLayer.videoGravity != videoGravity {
            uiView.sampleBufferLayer.videoGravity = videoGravity
        }
    }

    static func dismantleUIView(_ uiView: SampleBufferContainerView, coordinator: Coordinator) {
        coordinator.cleanup()
        uiView.flush()
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject {
        private var cancellable: AnyCancellable?
        private weak var containerView: SampleBufferContainerView?

        func subscribe(
            to publisher: AnyPublisher<CMSampleBuffer, Never>,
            view: SampleBufferContainerView
        ) {
            self.containerView = view
            cancellable?.cancel()

            cancellable = publisher
                .receive(on: DispatchQueue.main)
                .sink { [weak view] sampleBuffer in
                    view?.enqueue(sampleBuffer)
                }
        }

        func cleanup() {
            cancellable?.cancel()
            cancellable = nil
            containerView?.flush()
        }
    }
}
