//
//  SampleBufferVideoView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import AVFoundation
import CoreMedia
import CoreImage
import Combine

// MARK: - SampleBufferContainerView

/// High-performance Hybrid GPU video view hosting an AVSampleBufferDisplayLayer on hardware
/// and falling back seamlessly to direct CGImage GPU rendering on Simulator or if decoding fails.
final class SampleBufferContainerView: UIView {

    override class var layerClass: AnyClass {
        AVSampleBufferDisplayLayer.self
    }

    var sampleBufferLayer: AVSampleBufferDisplayLayer {
        layer as! AVSampleBufferDisplayLayer
    }

    private static let callCIContext = CIContext(options: [
        .workingColorSpace: CGColorSpaceCreateDeviceRGB(),
        .useSoftwareRenderer: false,
        .cacheIntermediates: false
    ])

    private let imageLayer: CALayer = {
        let layer = CALayer()
        layer.masksToBounds = true
        layer.contentsGravity = .resizeAspectFill
        return layer
    }()

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
        layer.masksToBounds = true
        sampleBufferLayer.videoGravity = .resizeAspectFill
        sampleBufferLayer.preventsDisplaySleepDuringVideoPlayback = true
        imageLayer.frame = bounds
        layer.addSublayer(imageLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        imageLayer.frame = bounds
        CATransaction.commit()
    }

    /// Updates videoGravity for both hardware display layer and fallback image layer.
    func updateGravity(_ videoGravity: AVLayerVideoGravity) {
        if sampleBufferLayer.videoGravity != videoGravity {
            sampleBufferLayer.videoGravity = videoGravity
        }
        let gravity: CALayerContentsGravity = (videoGravity == .resizeAspect) ? .resizeAspect : (videoGravity == .resize ? .resize : .resizeAspectFill)
        layer.contentsGravity = gravity
        imageLayer.contentsGravity = gravity
    }

    /// Safely enqueues a new video CMSampleBuffer using Hybrid GPU rendering.
    func enqueue(_ sampleBuffer: CMSampleBuffer) {
        #if targetEnvironment(simulator)
        renderViaCGImage(sampleBuffer)
        #else
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
                renderViaCGImage(sampleBuffer)
            } else if renderer.isReadyForMoreMediaData {
                renderer.enqueue(sampleBuffer)
            } else {
                renderViaCGImage(sampleBuffer)
            }
        } else {
            if sampleBufferLayer.status == .failed {
                sampleBufferLayer.flush()
                renderViaCGImage(sampleBuffer)
            } else if sampleBufferLayer.isReadyForMoreMediaData {
                sampleBufferLayer.enqueue(sampleBuffer)
            } else {
                renderViaCGImage(sampleBuffer)
            }
        }
        #endif
    }

    /// Fallback GPU direct rendering: converts CVPixelBuffer into CGImage via dedicated call CIContext and assigns to imageLayer.
    private func renderViaCGImage(_ sampleBuffer: CMSampleBuffer) {
        autoreleasepool {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            guard let cgImage = Self.callCIContext.createCGImage(ciImage, from: ciImage.extent) else { return }

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            imageLayer.contents = cgImage
            CATransaction.commit()
        }
    }

    /// Clears any queued image frames immediately.
    func flush() {
        #if !targetEnvironment(simulator)
        if #available(iOS 17.0, *) {
            sampleBufferLayer.sampleBufferRenderer.flush()
        } else {
            sampleBufferLayer.flushAndRemoveImage()
        }
        #endif
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.contents = nil
        imageLayer.contents = nil
        CATransaction.commit()
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
        view.updateGravity(videoGravity)
        context.coordinator.subscribe(to: publisher, view: view)
        return view
    }

    func updateUIView(_ uiView: SampleBufferContainerView, context: Context) {
        uiView.updateGravity(videoGravity)
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

            #if targetEnvironment(simulator)
            cancellable = publisher
                .receive(on: DispatchQueue.main)
                .sink { [weak view] sampleBuffer in
                    view?.enqueue(sampleBuffer)
                }
            #else
            // On hardware device, AVSampleBufferDisplayLayer enqueue is thread-safe; do not flood main thread (VIDEO-07)
            cancellable = publisher
                .sink { [weak view] sampleBuffer in
                    view?.enqueue(sampleBuffer)
                }
            #endif
        }

        func cleanup() {
            cancellable?.cancel()
            cancellable = nil
            containerView?.flush()
        }
    }
}
