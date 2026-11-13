//
//  WebSocketConnectionManager.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Combine
import Alamofire

// MARK: - WebSocketConnectionManagerProtocol

protocol WebSocketConnectionManagerProtocol: AnyObject, Sendable {
    var isConnected: Bool { get }
    var connectionState: WebSocketConnectionState { get }
    func connect() async
    func disconnect() async
    func handleAuthStateChange(isAuthenticated: Bool)
    func joinCall(callId: String, roomId: String) async
    func leaveCall() async
    func updateCallState(_ state: CallConnectionState) async
    func setBackground(_ background: Bool) async
    func setNetworkType(_ type: NetworkType) async
}

// MARK: - WebSocketConnectionManager

/// Manages WebSocket connection lifecycle based on authentication state.
/// Connects to Neon Functions WebSocket endpoint after authentication.
/// Integrates with battery-optimized heartbeat and state machine.
@MainActor
final class WebSocketConnectionManager: WebSocketConnectionManagerProtocol, ObservableObject {

    private let webSocketService: WebSocketServiceProtocol
    private let authManager: AuthManagerProtocol
    private var cancellables = Set<AnyCancellable>()

    private var isConnecting = false
    private var currentAuthState = false
    private var currentCallId: String?
    private var currentRoomId: String?

    @Published var connectionState: WebSocketConnectionState = .disconnected

    var isConnected: Bool { webSocketService.isConnected }

    init(
        webSocketService: WebSocketServiceProtocol,
        authManager: AuthManagerProtocol
    ) {
        self.webSocketService = webSocketService
        self.authManager = authManager
        observeConnectionState()
        observeAuthState()
    }

    private func observeConnectionState() {
        webSocketService.eventPublisher
            .compactMap { event -> WebSocketConnectionState? in
                if case .stateChanged(let state) = event {
                    return state
                }
                return nil
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.connectionState = state
            }
            .store(in: &cancellables)
    }

    private func observeAuthState() {
        authManagerRefresh()
    }

    private func authManagerRefresh() {
        // Check auth state periodically or when notified
        // For now, we'll rely on explicit handleAuthStateChange calls
    }

    func handleAuthStateChange(isAuthenticated: Bool) {
        guard isAuthenticated != currentAuthState else { return }
        currentAuthState = isAuthenticated

        if isAuthenticated {
            Task { await connect() }
        } else {
            Task { await disconnect() }
        }
    }

    func connect() async {
        guard !isConnecting && !webSocketService.isConnected else { return }
        guard authManager.isAuthenticated else { return }
        guard let accessToken = authManager.accessToken else {
            AppLogger.network.notice("Cannot connect WebSocket: no access token")
            return
        }

        isConnecting = true
        defer { isConnecting = false }

        // Build WebSocket URL with token as query parameter (BE expects ?token=xxx)
        // Use dedicated wsBaseURL from AppConfig (separate port from API)
        let wsBaseURL = AppConfig.shared.wsBaseURL
        var components = URLComponents(string: wsBaseURL)!
        components.path = "/ws"
        components.queryItems = [URLQueryItem(name: "token", value: accessToken)]

        guard let url = components.url else {
            AppLogger.network.error("Invalid WebSocket URL")
            return
        }

        // Don't send token in headers - BE validates via query param
        let headers: [String: String] = [:]

        AppLogger.network.info("Connecting WebSocket to \(url.absoluteString)")
        await webSocketService.connect(url: url, headers: headers)

        // After connecting, if we have a pending call to join, join it
        if let callId = currentCallId, let roomId = currentRoomId {
            await joinCall(callId: callId, roomId: roomId)
        }
    }

    func disconnect() async {
        AppLogger.network.info("Disconnecting WebSocket")
        await webSocketService.disconnect()
        currentCallId = nil
        currentRoomId = nil
    }

    func joinCall(callId: String, roomId: String) async {
        currentCallId = callId
        currentRoomId = roomId

        if webSocketService.connectionState == .joined || webSocketService.connectionState == .authenticated {
            AppLogger.network.info("Joining call: \(callId), room: \(roomId)")
            await webSocketService.joinCall(callId: callId, roomId: roomId)
            await webSocketService.updateCallState(.joined)
        } else {
            AppLogger.network.info("Call join queued, waiting for connection: \(callId)")
        }
    }

    func leaveCall() async {
        guard let callId = currentCallId else { return }
        AppLogger.network.info("Leaving call: \(callId)")
        await webSocketService.leaveCall()
        await webSocketService.updateCallState(.authenticated)
        currentCallId = nil
        currentRoomId = nil
    }

    func updateCallState(_ state: CallConnectionState) async {
        await webSocketService.updateCallState(state)
    }

    func setBackground(_ background: Bool) async {
        await webSocketService.setBackground(background)
    }

    func setNetworkType(_ type: NetworkType) async {
        await webSocketService.setNetworkType(type)
    }
}