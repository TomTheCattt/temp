//
//  WebSocketMessageHandler.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Combine

// MARK: - WebSocketIncomingMessage

/// Typed incoming messages from the WebSocket server.
enum WebSocketIncomingMessage: Sendable {
    // Chat
    case newMessage(Message)
    case typing(conversationId: String, userId: String)
    case stopTyping(conversationId: String, userId: String)
    case messageRead(conversationId: String, userId: String)
    case messageDeleted(conversationId: String, messageId: String)

    // Presence
    case userOnline(userId: String)
    case userOffline(userId: String)

    // Notifications
    case notification(AppNotification)

    // Call signaling
    case callIncoming(CallSignal)
    case callOffer(CallSignal)
    case callAnswer(CallSignal)
    case callIceCandidate(CallSignal)
    case callHangup(callId: String, userId: String)
    case callReject(callId: String, userId: String)
    case callBusy(callId: String, userId: String)
    case callRinging(callId: String, userId: String)

    // Fallback
    case unknown(String)
}

// MARK: - CallSignal

/// WebRTC signaling data exchanged via WebSocket.
struct CallSignal: Sendable {
    let callId: String
    let fromUserId: String
    let toUserId: String
    let callType: CallType
    let sdp: String?             // SDP offer/answer
    let iceCandidate: String?    // ICE candidate JSON
    let iceSdpMid: String?
    let iceSdpMLineIndex: Int?
    let timestamp: Date

    enum CallType: String, Sendable {
        case audio
        case video
    }
}

// MARK: - WebSocketOutgoingMessage

/// Typed outgoing messages to the WebSocket server.
enum WebSocketOutgoingMessage: Sendable {
    // Chat
    case sendMessage(conversationId: String, content: String, type: String = "text")
    case startTyping(conversationId: String)
    case stopTyping(conversationId: String)
    case markRead(conversationId: String)
    case deleteMessage(conversationId: String, messageId: String)

    // Call signaling
    case callInitiate(callId: String, toUserId: String, callType: CallSignal.CallType)
    case callOffer(callId: String, toUserId: String, sdp: String)
    case callAnswer(callId: String, toUserId: String, sdp: String)
    case callIceCandidate(callId: String, toUserId: String, candidate: String, sdpMid: String?, sdpMLineIndex: Int?)
    case callHangup(callId: String, toUserId: String)
    case callReject(callId: String, toUserId: String)
    case callBusy(callId: String, toUserId: String)
    case callRinging(callId: String, toUserId: String)

    // Subscription
    case subscribe(channel: String)
    case unsubscribe(channel: String)

    var jsonData: Data {
        let dict = buildDictionary()
        return (try? JSONSerialization.data(withJSONObject: dict)) ?? Data()
    }

    var jsonString: String {
        String(data: jsonData, encoding: .utf8) ?? "{}"
    }

    private func buildDictionary() -> [String: Any] {
        switch self {
        // Chat
        case .sendMessage(let convId, let content, let type):
            return ["type": "send_message", "conversation_id": convId, "content": content, "content_type": type]
        case .startTyping(let convId):
            return ["type": "typing_start", "conversation_id": convId]
        case .stopTyping(let convId):
            return ["type": "typing_stop", "conversation_id": convId]
        case .markRead(let convId):
            return ["type": "mark_read", "conversation_id": convId]
        case .deleteMessage(let convId, let msgId):
            return ["type": "delete_message", "conversation_id": convId, "message_id": msgId]

        // Call signaling
        case .callInitiate(let callId, let toUserId, let callType):
            return ["type": "call_initiate", "call_id": callId, "to_user_id": toUserId, "call_type": callType.rawValue]
        case .callOffer(let callId, let toUserId, let sdp):
            return ["type": "call_offer", "call_id": callId, "to_user_id": toUserId, "sdp": sdp]
        case .callAnswer(let callId, let toUserId, let sdp):
            return ["type": "call_answer", "call_id": callId, "to_user_id": toUserId, "sdp": sdp]
        case .callIceCandidate(let callId, let toUserId, let candidate, let sdpMid, let sdpMLineIndex):
            var dict: [String: Any] = [
                "type": "call_ice_candidate",
                "call_id": callId,
                "to_user_id": toUserId,
                "candidate": candidate
            ]
            if let sdpMid { dict["sdp_mid"] = sdpMid }
            if let sdpMLineIndex { dict["sdp_mline_index"] = sdpMLineIndex }
            return dict
        case .callHangup(let callId, let toUserId):
            return ["type": "call_hangup", "call_id": callId, "to_user_id": toUserId]
        case .callReject(let callId, let toUserId):
            return ["type": "call_reject", "call_id": callId, "to_user_id": toUserId]
        case .callBusy(let callId, let toUserId):
            return ["type": "call_busy", "call_id": callId, "to_user_id": toUserId]
        case .callRinging(let callId, let toUserId):
            return ["type": "call_ringing", "call_id": callId, "to_user_id": toUserId]

        // Subscription
        case .subscribe(let channel):
            return ["type": "subscribe", "channel": channel]
        case .unsubscribe(let channel):
            return ["type": "unsubscribe", "channel": channel]
        }
    }
}

// MARK: - WebSocketMessageHandler

/// Handles parsing incoming WebSocket messages and routing them to typed publishers.
final class WebSocketMessageHandler: @unchecked Sendable {

    private let webSocketService: WebSocketServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    private let incomingSubject = PassthroughSubject<WebSocketIncomingMessage, Never>()
    private let connectionSubject = PassthroughSubject<WebSocketConnectionState, Never>()
    private let logger = AppLogger.network

    /// Typed stream of incoming messages.
    var incomingMessages: AnyPublisher<WebSocketIncomingMessage, Never> {
        incomingSubject.eraseToAnyPublisher()
    }

    /// Connection state changes.
    var connectionState: AnyPublisher<WebSocketConnectionState, Never> {
        connectionSubject.eraseToAnyPublisher()
    }

    /// Filtered stream: only call signaling messages.
    var callSignaling: AnyPublisher<WebSocketIncomingMessage, Never> {
        incomingMessages
            .filter { message in
                switch message {
                case .callIncoming, .callOffer, .callAnswer,
                     .callIceCandidate, .callHangup, .callReject,
                     .callBusy, .callRinging:
                    return true
                default:
                    return false
                }
            }
            .eraseToAnyPublisher()
    }

    /// Filtered stream: only chat messages.
    var chatMessages: AnyPublisher<WebSocketIncomingMessage, Never> {
        incomingMessages
            .filter { message in
                switch message {
                case .newMessage, .typing, .stopTyping, .messageRead, .messageDeleted:
                    return true
                default:
                    return false
                }
            }
            .eraseToAnyPublisher()
    }

    init(webSocketService: WebSocketServiceProtocol) {
        self.webSocketService = webSocketService
        subscribeToEvents()
    }

    // MARK: - Send

    func send(_ message: WebSocketOutgoingMessage) async throws {
        try await webSocketService.send(text: message.jsonString)
    }

    // MARK: - Private

    private func subscribeToEvents() {
        webSocketService.eventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .message(let wsMessage):
                    self.handleMessage(wsMessage)
                case .stateChanged(let state):
                    self.connectionSubject.send(state)
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func handleMessage(_ message: WebSocketMessage) {
        let text: String
        switch message {
        case .text(let t):
            text = t
        case .data(let data):
            guard let t = String(data: data, encoding: .utf8) else { return }
            text = t
        }
        parseTextMessage(text)
    }

    private func parseTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            incomingSubject.send(.unknown(text))
            return
        }

        switch type {
        // MARK: Chat
        case "new_message":
            // TODO: Full Message parsing when backend contract is finalized
            incomingSubject.send(.unknown(text))

        case "typing", "typing_start":
            if let convId = json["conversation_id"] as? String,
               let userId = json["user_id"] as? String {
                incomingSubject.send(.typing(conversationId: convId, userId: userId))
            }

        case "typing_stop":
            if let convId = json["conversation_id"] as? String,
               let userId = json["user_id"] as? String {
                incomingSubject.send(.stopTyping(conversationId: convId, userId: userId))
            }

        case "message_read":
            if let convId = json["conversation_id"] as? String,
               let userId = json["user_id"] as? String {
                incomingSubject.send(.messageRead(conversationId: convId, userId: userId))
            }

        case "message_deleted":
            if let convId = json["conversation_id"] as? String,
               let msgId = json["message_id"] as? String {
                incomingSubject.send(.messageDeleted(conversationId: convId, messageId: msgId))
            }

        // MARK: Presence
        case "user_online":
            if let userId = json["user_id"] as? String {
                incomingSubject.send(.userOnline(userId: userId))
            }

        case "user_offline":
            if let userId = json["user_id"] as? String {
                incomingSubject.send(.userOffline(userId: userId))
            }

        // MARK: Call Signaling
        case "call_incoming", "call_initiate":
            if let signal = parseCallSignal(from: json) {
                incomingSubject.send(.callIncoming(signal))
            }

        case "call_offer":
            if let signal = parseCallSignal(from: json) {
                incomingSubject.send(.callOffer(signal))
            }

        case "call_answer":
            if let signal = parseCallSignal(from: json) {
                incomingSubject.send(.callAnswer(signal))
            }

        case "call_ice_candidate":
            if let signal = parseCallSignal(from: json) {
                incomingSubject.send(.callIceCandidate(signal))
            }

        case "call_hangup":
            if let callId = json["call_id"] as? String,
               let userId = json["from_user_id"] as? String ?? json["user_id"] as? String {
                incomingSubject.send(.callHangup(callId: callId, userId: userId))
            }

        case "call_reject":
            if let callId = json["call_id"] as? String,
               let userId = json["from_user_id"] as? String ?? json["user_id"] as? String {
                incomingSubject.send(.callReject(callId: callId, userId: userId))
            }

        case "call_busy":
            if let callId = json["call_id"] as? String,
               let userId = json["from_user_id"] as? String ?? json["user_id"] as? String {
                incomingSubject.send(.callBusy(callId: callId, userId: userId))
            }

        case "call_ringing":
            if let callId = json["call_id"] as? String,
               let userId = json["from_user_id"] as? String ?? json["user_id"] as? String {
                incomingSubject.send(.callRinging(callId: callId, userId: userId))
            }

        default:
            incomingSubject.send(.unknown(text))
        }
    }

    // MARK: - Call Signal Parsing

    private func parseCallSignal(from json: [String: Any]) -> CallSignal? {
        guard let callId = json["call_id"] as? String,
              let fromUserId = json["from_user_id"] as? String else {
            return nil
        }

        let toUserId = json["to_user_id"] as? String ?? ""
        let callTypeRaw = json["call_type"] as? String ?? "audio"
        let callType = CallSignal.CallType(rawValue: callTypeRaw) ?? .audio

        return CallSignal(
            callId: callId,
            fromUserId: fromUserId,
            toUserId: toUserId,
            callType: callType,
            sdp: json["sdp"] as? String,
            iceCandidate: json["candidate"] as? String,
            iceSdpMid: json["sdp_mid"] as? String,
            iceSdpMLineIndex: json["sdp_mline_index"] as? Int,
            timestamp: Date()
        )
    }
}
