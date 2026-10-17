//
//  WebSocketCallSignalingHandler.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Combine

// MARK: - WebSocketCallSignalingHandler

/// Production WebRTC signaling transport bridging domain CallSignals with WebSocket frames.
final class WebSocketCallSignalingHandler: CallSignalingHandlerProtocol, @unchecked Sendable {

    // MARK: - State & Publishers

    private let incomingSignalSubject = PassthroughSubject<CallSignal, Never>()
    var incomingSignalPublisher: AnyPublisher<CallSignal, Never> {
        incomingSignalSubject.eraseToAnyPublisher()
    }

    private(set) var isConnected: Bool = true
    private let messageHandler: WebSocketMessageHandler
    private var cancellables = Set<AnyCancellable>()
    private let logger = AppLogger.network

    // MARK: - Init

    init(messageHandler: WebSocketMessageHandler) {
        self.messageHandler = messageHandler
        subscribeToMessageHandler()
    }

    // MARK: - Connection Lifecycle

    func connect() async throws {
        isConnected = true
        logger.info("WebSocketCallSignalingHandler connected.")
    }

    func disconnect() {
        isConnected = false
        logger.info("WebSocketCallSignalingHandler disconnected.")
    }

    // MARK: - Outgoing Signal

    func send(signal: CallSignal) async throws {
        let outgoing = mapToOutgoingMessage(signal)
        try await messageHandler.send(outgoing)
    }

    // MARK: - Signal Mapping

    private func mapToOutgoingMessage(_ signal: CallSignal) -> WebSocketOutgoingMessage {
        switch signal {
        case .callInitiate(let callId, let fromUserId, let toUserId, let callType):
            return .callInitiate(callId: callId, fromUserId: fromUserId, toUserId: toUserId, callType: callType)

        case .callIncoming(let callId, let fromUserId, let toUserId, let callType, _, _):
            return .callInitiate(callId: callId, fromUserId: fromUserId, toUserId: toUserId, callType: callType)

        case .callOffer(let callId, let fromUserId, let toUserId, let sdp):
            return .callOffer(callId: callId, fromUserId: fromUserId, toUserId: toUserId, sdp: sdp)

        case .callAnswer(let callId, let fromUserId, let toUserId, let sdp):
            return .callAnswer(callId: callId, fromUserId: fromUserId, toUserId: toUserId, sdp: sdp)

        case .callIceCandidate(let callId, let fromUserId, let toUserId, let candidate, let sdpMid, let sdpMLineIndex):
            return .callIceCandidate(
                callId: callId,
                fromUserId: fromUserId,
                toUserId: toUserId,
                candidate: candidate,
                sdpMid: sdpMid,
                sdpMLineIndex: sdpMLineIndex
            )

        case .callHangup(let callId, let fromUserId, let toUserId):
            return .callHangup(callId: callId, fromUserId: fromUserId, toUserId: toUserId)

        case .callReject(let callId, let fromUserId, let toUserId):
            return .callReject(callId: callId, fromUserId: fromUserId, toUserId: toUserId)

        case .callBusy(let callId, let fromUserId, let toUserId):
            return .callBusy(callId: callId, fromUserId: fromUserId, toUserId: toUserId)

        case .callRinging(let callId, let fromUserId, let toUserId):
            return .callRinging(callId: callId, fromUserId: fromUserId, toUserId: toUserId)
        }
    }

    // MARK: - Subscriptions

    private func subscribeToMessageHandler() {
        messageHandler.callSignalPublisher
            .sink { [weak self] signal in
                guard let self else { return }
                self.incomingSignalSubject.send(signal)
            }
            .store(in: &cancellables)
    }
}
