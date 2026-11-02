//
//  OfflineMessageQueue.swift
//  Instagram
//
//  Created on 28/10/26.
//

import Foundation
import Combine

// MARK: - OfflineMessageQueue

/// Persistent queue for messages that need to be sent when device is offline.
/// Uses file-based storage for durability across app restarts.
@MainActor
final class OfflineMessageQueue: ObservableObject {

    // MARK: - Singleton

    static let shared = OfflineMessageQueue()

    // MARK: - State

    @Published private(set) var pendingCount: Int = 0
    @Published private(set) var isProcessing: Bool = false

    // MARK: - Send Handler

    /// Closure to execute the actual send operation.
    /// Must be set by the view model before processing queue.
    var sendHandler: ((QueuedMessage) async throws -> Void)?

    // MARK: - Private

    private let queueURL: URL
    private var queue: [QueuedMessage] = []
    private let fileManager = FileManager.default
    private let networkMonitor = NetworkMonitor.shared

    // MARK: - Init

    private init() {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        queueURL = documents.appendingPathComponent("offline_message_queue.json")
        loadQueue()
        observeNetwork()
    }

    // MARK: - Public API

    /// Enqueue a message for later delivery
    func enqueue(_ message: QueuedMessage) {
        queue.append(message)
        saveQueue()
        updatePendingCount()

        // Try to process immediately if online
        if networkMonitor.isConnected {
            Task { await processQueue() }
        }
    }

    /// Process all pending messages
    func processQueue() async {
        guard !isProcessing, !queue.isEmpty, networkMonitor.isConnected else { return }

        guard let sendHandler = sendHandler else {
            print("OfflineMessageQueue: sendHandler not set, cannot process queue")
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        var remaining: [QueuedMessage] = []

        for var queued in queue {
            if queued.retryCount >= 5 {
                // Max retries exceeded - move to failed
                remaining.append(queued)
                continue
            }

            do {
                try await sendHandler(queued)
                // Success - don't re-add to queue
            } catch {
                // Failed - increment retry count and re-queue
                queued.retryCount += 1
                queued.lastError = error.localizedDescription
                remaining.append(queued)
            }
        }

        queue = remaining
        saveQueue()
        updatePendingCount()
    }

    /// Get all pending messages for UI display
    func getPendingMessages() -> [QueuedMessage] {
        return queue
    }

    /// Clear all pending messages (e.g., on logout)
    func clear() {
        queue.removeAll()
        saveQueue()
        updatePendingCount()
    }

    /// Remove a specific message from queue
    func remove(id: String) {
        queue.removeAll { $0.id == id }
        saveQueue()
        updatePendingCount()
    }

    // MARK: - Private

    private func loadQueue() {
        guard fileManager.fileExists(atPath: queueURL.path) else { return }

        do {
            let data = try Data(contentsOf: queueURL)
            queue = try JSONDecoder().decode([QueuedMessage].self, from: data)
            updatePendingCount()
        } catch {
            print("Failed to load offline message queue: \(error)")
        }
    }

    private func saveQueue() {
        do {
            let data = try JSONEncoder().encode(queue)
            try data.write(to: queueURL, options: .atomic)
        } catch {
            print("Failed to save offline message queue: \(error)")
        }
    }

    private func updatePendingCount() {
        pendingCount = queue.count
    }

    private func observeNetwork() {
        // NetworkMonitor publishes isConnected changes
        // We'll check periodically or use a more sophisticated approach
        Task {
            for await _ in networkMonitor.connectionChanges {
                if networkMonitor.isConnected && !queue.isEmpty {
                    await processQueue()
                }
            }
        }
    }
}

// MARK: - QueuedMessage

struct QueuedMessage: Codable, Identifiable {
    let id: String
    let conversationId: String
    let content: MessageContent
    let replyToId: String?
    let replyToSnippet: String?
    let createdAt: Date
    var retryCount: Int = 0
    var lastError: String?
    var sendActionData: SendActionData

    init(
        id: String = UUID().uuidString,
        conversationId: String,
        content: MessageContent,
        replyToId: String? = nil,
        replyToSnippet: String? = nil,
        createdAt: Date = Date(),
        sendActionData: SendActionData
    ) {
        self.id = id
        self.conversationId = conversationId
        self.content = content
        self.replyToId = replyToId
        self.replyToSnippet = replyToSnippet
        self.createdAt = createdAt
        self.sendActionData = sendActionData
    }
}

struct SendActionData: Codable {
    let type: String  // "text", "image", "video", "audio", "like"
    let text: String?
    let mediaURL: String?
    let thumbnailURL: String?
    let duration: TimeInterval?

    static func text(_ text: String, replyToId: String?) -> SendActionData {
        SendActionData(type: "text", text: text, mediaURL: nil, thumbnailURL: nil, duration: nil)
    }

    static func image(_ url: URL, replyToId: String?) -> SendActionData {
        SendActionData(type: "image", text: nil, mediaURL: url.absoluteString, thumbnailURL: nil, duration: nil)
    }

    static func video(_ url: URL, thumbnailURL: URL?, replyToId: String?) -> SendActionData {
        SendActionData(type: "video", text: nil, mediaURL: url.absoluteString, thumbnailURL: thumbnailURL?.absoluteString, duration: nil)
    }

    static func audio(_ url: URL, duration: TimeInterval, replyToId: String?) -> SendActionData {
        SendActionData(type: "audio", text: nil, mediaURL: url.absoluteString, thumbnailURL: nil, duration: duration)
    }

    static func like(_ replyToId: String?) -> SendActionData {
        SendActionData(type: "like", text: nil, mediaURL: nil, thumbnailURL: nil, duration: nil)
    }
}

enum QueuedMessageError: Error {
    case notImplemented
    case invalidData
}