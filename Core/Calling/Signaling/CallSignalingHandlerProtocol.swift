//
//  CallSignalingHandlerProtocol.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Combine

// MARK: - CallType Typealias

typealias CallType = CallSignal.CallType

// MARK: - CallSignal

/// Domain model representing WebRTC call signaling events exchanged across transports.
enum CallSignal: Sendable, Equatable {
    /// Media type for call signaling.
    enum CallType: String, Sendable, Codable, Equatable {
        case audio
        case video
    }

    case callInitiate(callId: String, fromUserId: String, toUserId: String, callType: CallType)
    case callIncoming(callId: String, fromUserId: String, toUserId: String, callType: CallType, callerName: String? = nil, avatarURL: URL? = nil)
    case callOffer(callId: String, fromUserId: String, toUserId: String, sdp: String)
    case callAnswer(callId: String, fromUserId: String, toUserId: String, sdp: String)
    case callIceCandidate(callId: String, fromUserId: String, toUserId: String, candidate: String, sdpMid: String?, sdpMLineIndex: Int?)
    case callHangup(callId: String, fromUserId: String, toUserId: String)
    case callReject(callId: String, fromUserId: String, toUserId: String)
    case callBusy(callId: String, fromUserId: String, toUserId: String)
    case callRinging(callId: String, fromUserId: String, toUserId: String)


    // MARK: - Convenience Accessors

    var callId: String {
        switch self {
        case .callInitiate(let id, _, _, _),
             .callIncoming(let id, _, _, _, _, _),
             .callOffer(let id, _, _, _),
             .callAnswer(let id, _, _, _),
             .callIceCandidate(let id, _, _, _, _, _),
             .callHangup(let id, _, _),
             .callReject(let id, _, _),
             .callBusy(let id, _, _),
             .callRinging(let id, _, _):
            return id
        }
    }

    var fromUserId: String {
        switch self {
        case .callInitiate(_, let from, _, _),
             .callIncoming(_, let from, _, _, _, _),
             .callOffer(_, let from, _, _),
             .callAnswer(_, let from, _, _),
             .callIceCandidate(_, let from, _, _, _, _),
             .callHangup(_, let from, _),
             .callReject(_, let from, _),
             .callBusy(_, let from, _),
             .callRinging(_, let from, _):
            return from
        }
    }

    var toUserId: String {
        switch self {
        case .callInitiate(_, _, let to, _),
             .callIncoming(_, _, let to, _, _, _),
             .callOffer(_, _, let to, _),
             .callAnswer(_, _, let to, _),
             .callIceCandidate(_, _, let to, _, _, _),
             .callHangup(_, _, let to),
             .callReject(_, _, let to),
             .callBusy(_, _, let to),
             .callRinging(_, _, let to):
            return to
        }
    }

    var callType: CallType? {
        switch self {
        case .callInitiate(_, _, _, let type),
             .callIncoming(_, _, _, let type, _, _):
            return type
        default:
            return nil
        }
    }

    var sdp: String? {
        switch self {
        case .callOffer(_, _, _, let sdp),
             .callAnswer(_, _, _, let sdp):
            return sdp
        default:
            return nil
        }
    }

    // MARK: - Legacy Compatibility Initializer

    init(
        callId: String,
        fromUserId: String,
        toUserId: String,
        callType: CallType,
        sdp: String? = nil,
        iceCandidate: String? = nil,
        iceSdpMid: String? = nil,
        iceSdpMLineIndex: Int? = nil,
        timestamp: Date = Date()
    ) {
        if let candidate = iceCandidate {
            self = .callIceCandidate(
                callId: callId,
                fromUserId: fromUserId,
                toUserId: toUserId,
                candidate: candidate,
                sdpMid: iceSdpMid,
                sdpMLineIndex: iceSdpMLineIndex
            )
        } else if let sdp = sdp {
            self = .callOffer(
                callId: callId,
                fromUserId: fromUserId,
                toUserId: toUserId,
                sdp: sdp
            )
        } else {
            self = .callIncoming(
                callId: callId,
                fromUserId: fromUserId,
                toUserId: toUserId,
                callType: callType,
                callerName: nil,
                avatarURL: nil
            )
        }
    }
}

// MARK: - CallSignalingHandlerProtocol

/// Protocol abstracting call signaling transport (Firebase, WebSocket, etc.).
protocol CallSignalingHandlerProtocol: AnyObject, Sendable {
    func connect() async throws
    func disconnect()
    func send(signal: CallSignal) async throws
    var incomingSignalPublisher: AnyPublisher<CallSignal, Never> { get }
    var isConnected: Bool { get }
}

extension CallSignalingHandlerProtocol {
    func send(_ signal: CallSignal) async throws {
        try await send(signal: signal)
    }
}

