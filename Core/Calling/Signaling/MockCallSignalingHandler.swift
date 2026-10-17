//
//  MockCallSignalingHandler.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation
import Combine

// MARK: - MockCallSignalingHandler

/// High-fidelity mock call signaling handler simulating WebRTC peer handshakes and network delays.
final class MockCallSignalingHandler: CallSignalingHandlerProtocol, @unchecked Sendable {

    // MARK: - Singleton

    static let shared = MockCallSignalingHandler()

    // MARK: - State & Publishers

    private let incomingSignalSubject = PassthroughSubject<CallSignal, Never>()
    var incomingSignalPublisher: AnyPublisher<CallSignal, Never> {
        incomingSignalSubject.eraseToAnyPublisher()
    }

    private(set) var isConnected: Bool = true
    private let logger = AppLogger.general

    // Synchronized pending auto-response task
    private let lock = NSLock()
    private var pendingCallTask: Task<Void, Never>?

    // MARK: - Init

    init() {}

    // MARK: - Lifecycle

    func connect() async throws {
        updateConnectedState(true)
        logger.info("MockCallSignalingHandler connected.")
    }

    func disconnect() {
        updateConnectedState(false)
        cancelPendingSimulatedTasks()
        logger.info("MockCallSignalingHandler disconnected.")
    }

    // MARK: - Send Signal

    func send(signal: CallSignal) async throws {
        logger.info("MockCallSignalingHandler sent signal: \(String(describing: signal))")

        switch signal {
        case .callInitiate(let callId, let fromUserId, let toUserId, _):
            scheduleSimulatedRemoteAnswer(callId: callId, remoteUserId: toUserId, localUserId: fromUserId)

        case .callHangup(let callId, let fromUserId, let toUserId),
             .callReject(let callId, let fromUserId, let toUserId):
            cancelPendingSimulatedTasks()
            // Confirm hangup acknowledge after minimal simulated latency
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard let self else { return }
                self.incomingSignalSubject.send(
                    .callHangup(callId: callId, fromUserId: toUserId, toUserId: fromUserId)
                )
            }

        default:
            break
        }
    }

    // MARK: - Simulation Utilities

    /// Simulates an incoming call from a remote user, immediately emitting into incomingSignalPublisher.
    func simulateIncomingCall(fromUserId: String, name: String, hasVideo: Bool, toUserId: String? = nil) {
        let callId = UUID().uuidString
        let recipientId: String
        if let toUserId, !toUserId.isEmpty {
            recipientId = toUserId
        } else if Thread.isMainThread {
            recipientId = MainActor.assumeIsolated { SessionStore.shared.currentUserId }
        } else {
            recipientId = "current_user"
        }
        let signal = CallSignal.callIncoming(
            callId: callId,
            fromUserId: fromUserId,
            toUserId: recipientId,
            callType: hasVideo ? .video : .audio,
            callerName: name,
            avatarURL: nil
        )
        logger.info("MockCallSignalingHandler simulating incoming call \(callId) from \(name) (\(fromUserId))")
        incomingSignalSubject.send(signal)
    }

    // MARK: - Synchronous Lock Helpers

    private func updateConnectedState(_ connected: Bool) {
        lock.lock()
        defer { lock.unlock() }
        isConnected = connected
    }

    private func storePendingTask(_ task: Task<Void, Never>?) {
        lock.lock()
        defer { lock.unlock() }
        pendingCallTask?.cancel()
        pendingCallTask = task
    }

    private func cancelPendingSimulatedTasks() {
        lock.lock()
        defer { lock.unlock() }
        pendingCallTask?.cancel()
        pendingCallTask = nil
    }

    // MARK: - Private Helpers

    private func scheduleSimulatedRemoteAnswer(callId: String, remoteUserId: String, localUserId: String) {
        cancelPendingSimulatedTasks()

        let task = Task { [weak self] in
            // 1. After 500ms, simulate remote phone ringing
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled, let self else { return }

            self.logger.info("MockCallSignalingHandler: remote party is ringing for call \(callId)")
            self.incomingSignalSubject.send(
                .callRinging(callId: callId, fromUserId: remoteUserId, toUserId: localUserId)
            )

            // 2. Ringing duration: 2.5s (total 3.0s), then simulate peer answering
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }

            self.logger.info("MockCallSignalingHandler: remote party answered call \(callId)")
            self.incomingSignalSubject.send(
                .callAnswer(
                    callId: callId,
                    fromUserId: remoteUserId,
                    toUserId: localUserId,
                    sdp: "mock_sdp_answer"
                )
            )
        }

        storePendingTask(task)
    }
}
