//
//  CallMediaPipelineFactory.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//
//  Factory for creating the appropriate media pipeline implementation.
//  Allows switching between synthetic (testing) and WebRTC (production) pipelines.

import Foundation
import Combine
import CoreMedia
import AVFoundation

// MARK: - Pipeline Type

/// Type of media pipeline to use.
enum CallPipelineType: Sendable {
    /// Synthetic generator for testing/simulator
    case synthetic
    /// WebRTC with SFU (mediasoup) for production
    case webRTC
    /// Automatic: WebRTC on device, synthetic on simulator
    case automatic
}

// MARK: - CallMediaPipelineFactory

/// Factory for creating media pipeline instances.
@MainActor
final class CallMediaPipelineFactory: @unchecked Sendable {

    static let shared = CallMediaPipelineFactory()

    private var currentPipelineType: CallPipelineType = .automatic
    private var cachedSyntheticPipeline: DefaultCallMediaPipeline?
    #if canImport(WebRTC)
    private var cachedWebRTCPipeline: CallWebRTCMediaPipeline?
    #endif

    private init() {}

    /// Sets the pipeline type to use.
    func setPipelineType(_ type: CallPipelineType) {
        currentPipelineType = type
        // Clear caches when switching
        cachedSyntheticPipeline = nil
        #if canImport(WebRTC)
        cachedWebRTCPipeline = nil
        #endif
    }

    /// Gets the current pipeline type.
    var pipelineType: CallPipelineType {
        currentPipelineType
    }

    /// Creates or returns the appropriate media pipeline.
    func makePipeline() -> CallMediaPipelineProtocol {
        let effectiveType = resolveEffectiveType()

        switch effectiveType {
        case .synthetic:
            return makeSyntheticPipeline()
        case .webRTC:
            return makeWebRTCPipeline()
        default:
            // resolveEffectiveType() never returns .automatic, but Swift requires exhaustive switch
            return makeSyntheticPipeline()
        }
    }

    /// Creates the synthetic pipeline (default fallback).
    private func makeSyntheticPipeline() -> CallMediaPipelineProtocol {
        if let cached = cachedSyntheticPipeline {
            return cached
        }
        let pipeline = DefaultCallMediaPipeline()
        cachedSyntheticPipeline = pipeline
        return pipeline
    }

    /// Creates the WebRTC pipeline.
    #if canImport(WebRTC)
    private func makeWebRTCPipeline() -> CallMediaPipelineProtocol {
        if let cached = cachedWebRTCPipeline {
            return cached
        }
        let pipeline = CallWebRTCMediaPipeline.shared
        cachedWebRTCPipeline = pipeline
        return pipeline
    }
    #else
    private func makeWebRTCPipeline() -> CallMediaPipelineProtocol {
        // WebRTC not available, fall back to synthetic
        return makeSyntheticPipeline()
    }
    #endif

    /// Resolves the effective pipeline type based on platform.
    private func resolveEffectiveType() -> CallPipelineType {
        switch currentPipelineType {
        case .automatic:
            #if targetEnvironment(simulator)
            return .synthetic
            #else
            return .webRTC
            #endif
        case .synthetic, .webRTC:
            return currentPipelineType
        }
    }

    /// Resets the factory (for testing).
    func reset() {
        cachedSyntheticPipeline = nil
        #if canImport(WebRTC)
        cachedWebRTCPipeline = nil
        #endif
        currentPipelineType = .automatic
    }
}

// MARK: - WebRTC Pipeline Extensions (Conditional)

#if canImport(WebRTC)
import WebRTC

/// Extended protocol for WebRTC-specific pipeline features.
protocol CallWebRTCMediaPipelineProtocol: CallMediaPipelineProtocol {
    /// Creates and configures WebRTC peer connection for SFU transport.
    func createPeerConnection(
        callId: String,
        roomId: String,
        iceServers: [RTCIceServer],
        signalingHandler: CallSignalingHandlerProtocol
    ) async throws

    /// Sets the signaling handler for WebRTC negotiation.
    func setSignalingHandler(_ handler: CallSignalingHandlerProtocol)

    /// Gets the WebRTC peer connection (if available).
    var peerConnection: Any? { get }

    /// Gets the local audio track.
    var localAudioTrack: Any? { get }

    /// Gets the local video track.
    var localVideoTrack: Any? { get }
}
#endif