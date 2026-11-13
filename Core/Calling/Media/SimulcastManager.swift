//
//  SimulcastManager.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//
//  Manages simulcast layer selection and adaptation for WebRTC SFU (mediasoup).
//  Handles dynamic layer switching based on network conditions and receiver capabilities.

import Foundation
import Combine

#if canImport(WebRTC)
import WebRTC
#endif

// MARK: - SimulcastManager

/// Manages simulcast encoding layers and receiver-side layer selection.
/// Works with mediasoup SFU to provide adaptive video quality.
@MainActor
final class SimulcastManager: @unchecked Sendable {

    // MARK: - Configuration

    struct SimulcastLayer: Sendable, Identifiable {
        let id: String // RID: "high", "medium", "low"
        let width: Int
        let height: Int
        let maxBitrate: Int // bps
        let maxFramerate: Int
        let scaleResolutionDownBy: Double
        var isActive: Bool

        static let high = SimulcastLayer(
            id: "high",
            width: 1280,
            height: 720,
            maxBitrate: 2_500_000,
            maxFramerate: 30,
            scaleResolutionDownBy: 1.0,
            isActive: true
        )

        static let medium = SimulcastLayer(
            id: "medium",
            width: 640,
            height: 360,
            maxBitrate: 1_000_000,
            maxFramerate: 30,
            scaleResolutionDownBy: 2.0,
            isActive: true
        )

        static let low = SimulcastLayer(
            id: "low",
            width: 320,
            height: 180,
            maxBitrate: 300_000,
            maxFramerate: 15,
            scaleResolutionDownBy: 4.0,
            isActive: true
        )

        static let allLayers = [high, medium, low]
    }

    // MARK: - State

    private let layers: [SimulcastLayer] = SimulcastLayer.allLayers
    private var preferredLayerIndex: Int = 0 // 0 = high, 1 = medium, 2 = low
    private var currentLayerIndex: Int = 0
    private let logger = AppLogger.general

    // MARK: - Publishers

    private let layerChangeSubject = PassthroughSubject<SimulcastLayer, Never>()
    var layerChangePublisher: AnyPublisher<SimulcastLayer, Never> {
        layerChangeSubject.eraseToAnyPublisher()
    }

    private let bandwidthEstimateSubject = CurrentValueSubject<Double, Never>(0.0) // Mbps
    var bandwidthEstimatePublisher: AnyPublisher<Double, Never> {
        bandwidthEstimateSubject.eraseToAnyPublisher()
    }

    // MARK: - Public API

    /// Returns all available simulcast layers.
    var availableLayers: [SimulcastLayer] {
        layers
    }

    /// Returns the currently active layer.
    var currentLayer: SimulcastLayer {
        layers[currentLayerIndex]
    }

    /// Returns the preferred layer (may differ from current during transition).
    var preferredLayer: SimulcastLayer {
        layers[preferredLayerIndex]
    }

    /// Sets the preferred layer index (0=high, 1=medium, 2=low).
    /// Called by receiver to request specific quality.
    func setPreferredLayer(index: Int) {
        let clamped = max(0, min(index, layers.count - 1))
        guard clamped != preferredLayerIndex else { return }

        preferredLayerIndex = clamped
        logger.info("Preferred simulcast layer set to: \(layers[clamped].id)")

        // Apply immediately if we're the sender (sender-side adaptation)
        applyLayerSelection()
    }

    /// Sets the preferred layer by RID.
    func setPreferredLayer(rid: String) {
        if let index = layers.firstIndex(where: { $0.id == rid }) {
            setPreferredLayer(index: index)
        }
    }

    /// Updates bandwidth estimate for automatic layer adaptation.
    func updateBandwidthEstimate(_ mbps: Double) {
        bandwidthEstimateSubject.send(mbps)
        adaptLayerToBandwidth(mbps)
    }

    /// Gets encoding parameters for WebRTC sender configuration.
    /// Returns empty array when WebRTC is not available.
    func getEncodingParameters() -> [Any] {
        #if canImport(WebRTC)
        return layers.map { layer in
            let params = RTCRtpEncodingParameters()
            params.rid = layer.id
            params.active = layer.isActive
            params.maxBitrateBps = NSNumber(value: layer.maxBitrate)
            params.maxFramerate = NSNumber(value: layer.maxFramerate)
            params.scaleResolutionDownBy = NSNumber(value: layer.scaleResolutionDownBy)
            return params
        }
        #else
        return []
        #endif
    }

    // MARK: - Private: Bandwidth Adaptation

    private func adaptLayerToBandwidth(_ mbps: Double) {
        // Simple adaptation logic:
        // > 2.5 Mbps -> high
        // 1.0 - 2.5 Mbps -> medium
        // < 1.0 Mbps -> low

        let targetIndex: Int
        if mbps >= 2.5 {
            targetIndex = 0 // high
        } else if mbps >= 1.0 {
            targetIndex = 1 // medium
        } else {
            targetIndex = 2 // low
        }

        // Hysteresis: only change if significantly different
        let currentBandwidthForLayer = Double(layers[currentLayerIndex].maxBitrate) / 1_000_000
        let targetBandwidthForLayer = Double(layers[targetIndex].maxBitrate) / 1_000_000

        // Only switch if bandwidth difference is significant (> 30%)
        let ratio = targetBandwidthForLayer / currentBandwidthForLayer
        if ratio > 1.3 || ratio < 0.7 {
            setPreferredLayer(index: targetIndex)
        }
    }

    private func applyLayerSelection() {
        // On sender side: deactivate non-preferred layers
        // On receiver side: request preferred layer via REMB/PLI

        #if canImport(WebRTC)
        // This would be called when we have access to the RTCRtpSender
        // sender.parameters.encodings = getEncodingParameters()
        #endif

        if preferredLayerIndex != currentLayerIndex {
            currentLayerIndex = preferredLayerIndex
            layerChangeSubject.send(layers[currentLayerIndex])
            logger.info("Active simulcast layer changed to: \(layers[currentLayerIndex].id)")
        }
    }

    /// Called when network quality changes (from WebRTC stats).
    func handleNetworkQualityChange(quality: NetworkQuality) {
        switch quality {
        case .excellent:
            setPreferredLayer(index: 0)
        case .good:
            setPreferredLayer(index: 0)
        case .poor:
            setPreferredLayer(index: 1)
        case .veryPoor:
            setPreferredLayer(index: 2)
        }
    }

    /// Requests a keyframe for the current layer (for recovery).
    func requestKeyFrame() {
        logger.info("Keyframe requested for layer: \(currentLayer.id)")
        // This would trigger sender?.requestKeyFrame() on the WebRTC sender
    }
}

// MARK: - Network Quality

enum NetworkQuality: String, Sendable {
    case excellent = "excellent"
    case good = "good"
    case poor = "poor"
    case veryPoor = "veryPoor"

    init(from rtt: Double, packetLoss: Double, bandwidth: Double) {
        // Simple heuristic based on WebRTC stats
        if rtt < 100 && packetLoss < 0.01 && bandwidth > 2_500_000 {
            self = .excellent
        } else if rtt < 200 && packetLoss < 0.03 && bandwidth > 1_000_000 {
            self = .good
        } else if rtt < 400 && packetLoss < 0.1 && bandwidth > 300_000 {
            self = .poor
        } else {
            self = .veryPoor
        }
    }
}

// Note: AppLogger is imported from Core.Logging (same module, no import needed)