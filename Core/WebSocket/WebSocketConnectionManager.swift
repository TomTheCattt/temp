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
    func connect() async
    func disconnect() async
    func handleAuthStateChange(isAuthenticated: Bool)
}

// MARK: - WebSocketConnectionManager

/// Manages WebSocket connection lifecycle based on authentication state.
/// Connects to Neon Functions WebSocket endpoint after authentication.
@MainActor
final class WebSocketConnectionManager: WebSocketConnectionManagerProtocol, ObservableObject {

    private let webSocketService: WebSocketServiceProtocol
    private let authManager: AuthManagerProtocol
    private var cancellables = Set<AnyCancellable>()

    private var isConnecting = false
    private var currentAuthState = false

    var isConnected: Bool { webSocketService.isConnected }

    init(
        webSocketService: WebSocketServiceProtocol,
        authManager: AuthManagerProtocol
    ) {
        self.webSocketService = webSocketService
        self.authManager = authManager
        observeAuthState()
    }

    private func observeAuthState() {
        // Observe AuthManager's isAuthenticated property changes
        // Since AuthManager is @MainActor, we can observe it directly
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

        // Build WebSocket URL with token
        let wsEndpoint = WebSocketEndpoint.connect(token: accessToken)
        do {
            let urlRequest = try wsEndpoint.asURLRequest()
            guard let url = urlRequest.url else {
                AppLogger.network.error("Invalid WebSocket URL")
                return
            }

            var headers: [String: String] = [:]
            urlRequest.allHTTPHeaderFields?.forEach { headers[$0.key] = $0.value }

            AppLogger.network.info("Connecting WebSocket to \(url.absoluteString)")
            await webSocketService.connect(url: url, headers: headers)
        } catch {
            AppLogger.network.error("Failed to build WebSocket URL: \(error.localizedDescription)")
        }
    }

    func disconnect() async {
        AppLogger.network.info("Disconnecting WebSocket")
        await webSocketService.disconnect()
    }
}