//
//  CameraPreviewView.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import SwiftUI
import AVFoundation

// MARK: - CameraPreviewView

struct CameraPreviewView: UIViewRepresentable {

    let session: AVCaptureSession
    let isHardwareAvailable: Bool

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        if uiView.videoPreviewLayer.session != session {
            uiView.videoPreviewLayer.session = session
        }
        uiView.updateOrientation()
    }
}

// MARK: - CameraPreviewUIView

final class CameraPreviewUIView: UIView {

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupObservers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupObservers() {
        if #available(iOS 18.0, *) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleSessionChange),
                name: AVCaptureSession.didStartRunningNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleSessionChange),
                name: AVCaptureInput.Port.formatDescriptionDidChangeNotification,
                object: nil
            )
        }
    }

    @objc private func handleSessionChange() {
        DispatchQueue.main.async { [weak self] in
            self?.updateOrientation()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer.frame = bounds
        updateOrientation()
    }

    func updateOrientation() {
        guard let connection = videoPreviewLayer.connection else { return }

        if let device = (videoPreviewLayer.session?.inputs.first(where: { ($0 as? AVCaptureDeviceInput)?.device.hasMediaType(.video) == true }) as? AVCaptureDeviceInput)?.device {
            let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: videoPreviewLayer)
            let angle = coordinator.videoRotationAngleForHorizonLevelPreview
            if connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
        }
    }
}
