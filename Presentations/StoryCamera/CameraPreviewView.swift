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
    var isFrontFacing: Bool = CameraService.shared.isFrontFacing

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.updateOrientation(isFrontFacing: isFrontFacing)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        if uiView.videoPreviewLayer.session != session {
            uiView.videoPreviewLayer.session = session
        }
        uiView.updateOrientation(isFrontFacing: isFrontFacing)
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

    private var currentFrontFacing: Bool = false

    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer.frame = bounds
        updateOrientation(isFrontFacing: currentFrontFacing)
    }

    func updateOrientation(isFrontFacing: Bool) {
        self.currentFrontFacing = isFrontFacing
        guard let connection = videoPreviewLayer.connection else { return }

        // Upright portrait angle: Front camera sensor is mounted at 270°, Back camera at 90°
        let targetAngle: CGFloat = isFrontFacing ? 270 : 90

        if connection.isVideoRotationAngleSupported(targetAngle) {
            if connection.videoRotationAngle != targetAngle {
                connection.videoRotationAngle = targetAngle
            }
        }
    }
}

