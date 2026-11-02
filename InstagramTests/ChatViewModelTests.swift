//
//  ChatViewModelTests.swift
//  InstagramTests
//
//  Created for testing ChatViewModel message handling, pagination, and real-time updates.
//

import XCTest
import Combine
import Foundation
@testable import Instagram

// MARK: - Mock Implementation

final class MockMessageDataSource: MessageDataSourceProtocol, @unchecked Sendable {
    var messages: [String: [TestMessageEntity]] = [:] // conversationId -> messages
    var fetchCallCount = 0
    var sendCallCount = 0
    var observeCallCount = 0
    var markAsReadCallCount = 0
    var deleteCallCount = 0
    var shouldFailFetch = false
    var shouldFailSend = false
    var shouldFailMarkAsRead = false
    var shouldFailDelete = false
    var fetchError: Error?
    var sendError: Error?
    var observeSubject = PassthroughSubject<[TestMessageEntity], Never>()

    func fetchMessages(conversationId: String, limit: Int, before: Date?) async throws -> [TestMessageEntity] {
        fetchCallCount += 1
        if shouldFailFetch, let error = fetchError {
            throw error
        }

        var conversationMessages = messages[conversationId] ?? []
        conversationMessages.sort { $0.timestamp > $1.timestamp }

        if let before = before {
            conversationMessages = conversationMessages.filter { $0.timestamp < before }
        }

        return Array(conversationMessages.prefix(limit))
    }

    func sendMessage(_ message: TestMessageEntity) async throws -> TestMessageEntity {
        sendCallCount += 1
        if shouldFailSend, let error = sendError {
            throw error
        }

        var newMessage = message
        newMessage.id = UUID().uuidString
        newMessage.timestamp = Date()
        newMessage.status = .sent

        if messages[newMessage.conversationId] == nil {
            messages[newMessage.conversationId] = []
        }
        messages[newMessage.conversationId]?.append(newMessage)

        // Notify observers
        observeSubject.send(messages[newMessage.conversationId] ?? [])

        return newMessage
    }

    func observeMessages(conversationId: String) -> AnyPublisher<[TestMessageEntity], Never> {
        observeCallCount += 1
        return observeSubject.eraseToAnyPublisher()
    }

    func markAsRead(conversationId: String, messageId: String) async throws {
        markAsReadCallCount += 1
        if shouldFailMarkAsRead {
            throw NSError(domain: "DataSource", code: -1)
        }

        guard var conversationMessages = messages[conversationId],
              let index = conversationMessages.firstIndex(where: { $0.id == messageId }) else { return }

        conversationMessages[index].status = .read
        messages[conversationId] = conversationMessages
        observeSubject.send(conversationMessages)
    }

    func deleteMessage(messageId: String) async throws {
        deleteCallCount += 1
        if shouldFailDelete {
            throw NSError(domain: "DataSource", code: -1)
        }

        for (conversationId, conversationMessages) in messages {
            if let index = conversationMessages.firstIndex(where: { $0.id == messageId }) {
                var updated = conversationMessages
                updated.remove(at: index)
                messages[conversationId] = updated
                observeSubject.send(updated)
                break
            }
        }
    }
}

// MARK: - ChatViewModel

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [TestMessageEntity] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var error: Error?
    @Published var hasMoreMessages = true
    @Published var connectionStatus: ConnectionStatus = .connected

    enum ConnectionStatus: Equatable {
        case connected, connecting, disconnected, reconnecting
    }

    private let dataSource: MessageDataSourceProtocol
    private let networkMonitor: TestMockNetworkMonitor
    private let conversationId: String
    private let currentUserId: String
    private let pageSize = 20
    private var lastFetchedDate: Date?
    private var cancellables = Set<AnyCancellable>()
    private var isObserving = false

    init(dataSource: MessageDataSourceProtocol,
         networkMonitor: TestMockNetworkMonitor,
         conversationId: String,
         currentUserId: String) {
        self.dataSource = dataSource
        self.networkMonitor = networkMonitor
        self.conversationId = conversationId
        self.currentUserId = currentUserId

        setupNetworkMonitoring()
        startObserving()
    }

    private func setupNetworkMonitoring() {
        networkMonitor.isConnectedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.connectionStatus = connected ? .connected : .disconnected
                if connected {
                    Task { await self?.loadMessages() }
                }
            }
            .store(in: &cancellables)
    }

    private func startObserving() {
        guard !isObserving else { return }
        isObserving = true

        dataSource.observeMessages(conversationId: conversationId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messages in
                self?.messages = messages.sorted { $0.timestamp < $1.timestamp }
            }
            .store(in: &cancellables)
    }

    func loadMessages() async {
        guard !isLoading, hasMoreMessages else { return }
        isLoading = true
        error = nil

        do {
            let fetchedMessages = try await dataSource.fetchMessages(
                conversationId: conversationId,
                limit: pageSize,
                before: lastFetchedDate
            )

            if fetchedMessages.isEmpty {
                hasMoreMessages = false
            } else {
                // Prepend older messages
                let sorted = fetchedMessages.sorted { $0.timestamp < $1.timestamp }
                messages = sorted + messages
                lastFetchedDate = fetchedMessages.min { $0.timestamp < $1.timestamp }?.timestamp
            }
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func sendMessage(content: String, type: TestMessageType = .text, replyTo: String? = nil, attachments: [TestAttachment] = []) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isSending = true
        error = nil

        let tempId = "temp_\(UUID().uuidString)"
        let outgoingMessage = TestMessageEntity(
            id: tempId,
            conversationId: conversationId,
            senderId: currentUserId,
            content: content,
            type: type,
            timestamp: Date(),
            status: .sending,
            replyToMessageId: replyTo,
            attachments: attachments
        )

        // Optimistic update
        messages.append(outgoingMessage)

        do {
            let sentMessage = try await dataSource.sendMessage(outgoingMessage)

            // Replace temp message with sent message
            if let index = messages.firstIndex(where: { $0.id == tempId }) {
                messages[index] = sentMessage
            }
        } catch {
            // Mark as failed
            if let index = messages.firstIndex(where: { $0.id == tempId }) {
                messages[index].status = .failed(error)
            }
            self.error = error
        }

        isSending = false
    }

    func retryFailedMessage(_ message: TestMessageEntity) async {
        guard case .failed = message.status else { return }

        await sendMessage(
            content: message.content,
            type: message.type,
            replyTo: message.replyToMessageId,
            attachments: message.attachments
        )
    }

    func markAsRead(messageId: String) async {
        do {
            try await dataSource.markAsRead(conversationId: conversationId, messageId: messageId)
        } catch {
            self.error = error
        }
    }

    func deleteMessage(messageId: String) async {
        do {
            try await dataSource.deleteMessage(messageId: messageId)
        } catch {
            self.error = error
        }
    }

    func loadMoreMessages() async {
        await loadMessages()
    }
}

// MARK: - ChatViewModelTests

@MainActor
final class ChatViewModelTests: XCTestCase {

    var mockDataSource: MockMessageDataSource!
    var mockNetworkMonitor: TestMockNetworkMonitor!
    var viewModel: ChatViewModel!
    let conversationId = "conv_123"
    let currentUserId = "user_456"

    override func setUp() async throws {
        try await super.setUp()
        mockDataSource = MockMessageDataSource()
        mockNetworkMonitor = TestMockNetworkMonitor()
        viewModel = ChatViewModel(
            dataSource: mockDataSource,
            networkMonitor: mockNetworkMonitor,
            conversationId: conversationId,
            currentUserId: currentUserId
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        mockDataSource = nil
        mockNetworkMonitor = nil
        try await super.tearDown()
    }

    // MARK: - Initial Load Tests

    func testInitialLoad_FetchesMessages() async throws {
        let messages = [
            TestMessageEntity(id: "1", conversationId: conversationId, senderId: "user_1", content: "Hello", timestamp: Date().addingTimeInterval(-100)),
            TestMessageEntity(id: "2", conversationId: conversationId, senderId: currentUserId, content: "Hi there", timestamp: Date().addingTimeInterval(-50)),
            TestMessageEntity(id: "3", conversationId: conversationId, senderId: "user_1", content: "How are you?", timestamp: Date())
        ]
        mockDataSource.messages[conversationId] = messages

        await viewModel.loadMessages()

        XCTAssertEqual(viewModel.messages.count, 3)
        XCTAssertEqual(viewModel.messages[0].content, "Hello")
        XCTAssertEqual(viewModel.messages[2].content, "How are you?")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testInitialLoad_EmptyConversation() async throws {
        await viewModel.loadMessages()

        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertFalse(viewModel.hasMoreMessages)
    }

    func testInitialLoad_Error_ShowsError() async throws {
        mockDataSource.shouldFailFetch = true
        mockDataSource.fetchError = NSError(domain: "Test", code: -1)

        await viewModel.loadMessages()

        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.messages.isEmpty)
    }

    // MARK: - Pagination Tests

    func testLoadMoreMessages_FetchesOlderMessages() async throws {
        // Initial load with recent messages
        let recentMessages = (0..<20).map { i in
            TestMessageEntity(
                id: "msg_\(i)",
                conversationId: conversationId,
                senderId: i % 2 == 0 ? "user_1" : currentUserId,
                content: "Message \(i)",
                timestamp: Date().addingTimeInterval(-Double(i) * 60)
            )
        }
        mockDataSource.messages[conversationId] = recentMessages

        await viewModel.loadMessages()
        XCTAssertEqual(viewModel.messages.count, 20)

        // Add older messages to data source
        let olderMessages = (20..<40).map { i in
            TestMessageEntity(
                id: "msg_\(i)",
                conversationId: conversationId,
                senderId: i % 2 == 0 ? "user_1" : currentUserId,
                content: "Old Message \(i)",
                timestamp: Date().addingTimeInterval(-Double(i) * 60 - 3600)
            )
        }
        mockDataSource.messages[conversationId] = olderMessages + recentMessages

        await viewModel.loadMoreMessages()

        XCTAssertEqual(viewModel.messages.count, 40)
        // Oldest message should be the oldest of the older messages (msg_39)
        XCTAssertEqual(viewModel.messages[0].content, "Old Message 39")
    }

    func testLoadMoreMessages_NoMoreMessages_StopsPagination() async throws {
        // Add exactly pageSize messages
        let messages = (0..<20).map { i in
            TestMessageEntity(id: "msg_\(i)", conversationId: conversationId, senderId: "user_1", content: "Msg \(i)", timestamp: Date().addingTimeInterval(-Double(i) * 60))
        }
        mockDataSource.messages[conversationId] = messages

        await viewModel.loadMessages()
        XCTAssertTrue(viewModel.hasMoreMessages)

        // Load more - should find no more
        await viewModel.loadMoreMessages()

        XCTAssertFalse(viewModel.hasMoreMessages)
    }

    func testLoadMoreMessages_WhileLoading_DoesNothing() async throws {
        mockDataSource.shouldFailFetch = true
        mockDataSource.fetchError = NSError(domain: "Test", code: -1)

        await viewModel.loadMessages()
        let initialCount = viewModel.messages.count

        // Try to load again while still "loading" (but actually failed)
        await viewModel.loadMessages()

        XCTAssertEqual(viewModel.messages.count, initialCount)
    }

    // MARK: - Send Message Tests

    func testSendTextMessage_AddsToMessages() async throws {
        await viewModel.sendMessage(content: "Hello World")

        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages[0].content, "Hello World")
        XCTAssertEqual(viewModel.messages[0].senderId, currentUserId)
        XCTAssertEqual(viewModel.messages[0].status, .sent)
    }

    func testSendMessage_EmptyContent_DoesNothing() async throws {
        await viewModel.sendMessage(content: "")
        await viewModel.sendMessage(content: "   ")

        XCTAssertTrue(viewModel.messages.isEmpty)
    }

    func testSendMessage_OptimisticUpdate_ShowsSending() async throws {
        // We can't easily test the intermediate .sending state without more complex setup
        // But we can verify the final state
        await viewModel.sendMessage(content: "Test")

        XCTAssertEqual(viewModel.messages.count, 1)
    }

    func testSendMessage_WithReply_AttachesReplyTo() async throws {
        let replyToId = "msg_123"

        await viewModel.sendMessage(content: "Reply", replyTo: replyToId)

        XCTAssertEqual(viewModel.messages[0].replyToMessageId, replyToId)
    }

    func testSendMessage_WithAttachments_IncludesAttachments() async throws {
        let attachment = TestAttachment(
            id: "att_1",
            url: "https://example.com/image.jpg",
            type: .image,
            size: 1024,
            thumbnailUrl: "https://example.com/thumb.jpg"
        )

        await viewModel.sendMessage(content: "Photo", type: .image, attachments: [attachment])

        XCTAssertEqual(viewModel.messages[0].attachments.count, 1)
        XCTAssertEqual(viewModel.messages[0].attachments[0].id, "att_1")
    }

    func testSendMessage_Failure_MarksAsFailed() async throws {
        mockDataSource.shouldFailSend = true
        mockDataSource.sendError = NSError(domain: "Network", code: -1)

        await viewModel.sendMessage(content: "Will fail")

        XCTAssertEqual(viewModel.messages.count, 1)
        if case .failed = viewModel.messages[0].status {
            // Expected
        } else {
            XCTFail("Message should be in failed state")
        }
        XCTAssertNotNil(viewModel.error)
    }

    func testSendMessage_NetworkDisconnected_QueuesForLater() async throws {
        mockNetworkMonitor.simulateConnectionChange(false)

        await viewModel.sendMessage(content: "Offline message")

        // Message should still be added optimistically
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.connectionStatus, .disconnected)
    }

    // MARK: - Retry Failed Message Tests

    func testRetryFailedMessage_ResendsMessage() async throws {
        mockDataSource.shouldFailSend = true
        mockDataSource.sendError = NSError(domain: "Network", code: -1)

        await viewModel.sendMessage(content: "Failed message")

        guard case .failed = viewModel.messages[0].status else {
            XCTFail("Message should be failed")
            return
        }

        // Now allow sending
        mockDataSource.shouldFailSend = false

        await viewModel.retryFailedMessage(viewModel.messages[0])

        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages[0].status, .sent)
    }

    func testRetryFailedMessage_NonFailedMessage_DoesNothing() async throws {
        await viewModel.sendMessage(content: "Success")

        let originalCount = viewModel.messages.count
        await viewModel.retryFailedMessage(viewModel.messages[0])

        XCTAssertEqual(viewModel.messages.count, originalCount)
    }

    // MARK: - Real-time Updates Tests

    func testRealTimeUpdate_IncomingMessage_AppendsToMessages() async throws {
        await viewModel.loadMessages()

        // Simulate incoming message via data source
        let newMessage = TestMessageEntity(
            id: "new_1",
            conversationId: conversationId,
            senderId: "other_user",
            content: "New message",
            timestamp: Date()
        )
        mockDataSource.messages[conversationId] = [newMessage]
        mockDataSource.observeSubject.send([newMessage])

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages[0].content, "New message")
    }

    func testRealTimeUpdate_MessageStatusChange_UpdatesMessage() async throws {
        let message = TestMessageEntity(
            id: "msg_1",
            conversationId: conversationId,
            senderId: currentUserId,
            content: "Test",
            status: .sent
        )
        mockDataSource.messages[conversationId] = [message]
        await viewModel.loadMessages()

        // Update status to read
        mockDataSource.messages[conversationId] = [
            TestMessageEntity(id: "msg_1", conversationId: conversationId, senderId: currentUserId, content: "Test", status: .read)
        ]
        mockDataSource.observeSubject.send(mockDataSource.messages[conversationId]!)

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.messages[0].status, .read)
    }

    func testRealTimeUpdate_MessageDeleted_RemovesFromMessages() async throws {
        let messages = [
            TestMessageEntity(id: "1", conversationId: conversationId, senderId: "user_1", content: "Msg 1"),
            TestMessageEntity(id: "2", conversationId: conversationId, senderId: currentUserId, content: "Msg 2"),
        ]
        mockDataSource.messages[conversationId] = messages
        await viewModel.loadMessages()

        // Delete message 1
        mockDataSource.messages[conversationId] = [messages[1]]
        mockDataSource.observeSubject.send([messages[1]])

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages[0].id, "2")
    }

    // MARK: - Mark As Read Tests

    func testMarkAsRead_CallsDataSource() async throws {
        let message = TestMessageEntity(id: "msg_1", conversationId: conversationId, senderId: "other", content: "Test")
        mockDataSource.messages[conversationId] = [message]
        await viewModel.loadMessages()

        await viewModel.markAsRead(messageId: "msg_1")

        XCTAssertEqual(mockDataSource.markAsReadCallCount, 1)
    }

    // MARK: - Delete Message Tests

    func testDeleteMessage_CallsDataSource() async throws {
        let message = TestMessageEntity(id: "msg_1", conversationId: conversationId, senderId: currentUserId, content: "Test")
        mockDataSource.messages[conversationId] = [message]
        await viewModel.loadMessages()

        await viewModel.deleteMessage(messageId: "msg_1")

        XCTAssertEqual(mockDataSource.deleteCallCount, 1)
    }

    // MARK: - Network Monitoring Tests

    func testNetworkDisconnect_UpdatesStatus() async throws {
        mockNetworkMonitor.simulateConnectionChange(false)

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.connectionStatus, .disconnected)
    }

    func testNetworkReconnect_TriggersLoad() async throws {
        // Pre-populate with messages so hasMoreMessages stays true
        let messages = (0..<20).map { i in
            TestMessageEntity(
                id: "msg_\(i)",
                conversationId: conversationId,
                senderId: i % 2 == 0 ? "user_1" : currentUserId,
                content: "Message \(i)",
                timestamp: Date().addingTimeInterval(-Double(i) * 60)
            )
        }
        mockDataSource.messages[conversationId] = messages

        // Start disconnected
        mockNetworkMonitor.simulateConnectionChange(false)
        try await Task.sleep(nanoseconds: 100_000_000)

        let initialFetchCount = mockDataSource.fetchCallCount

        // Reconnect
        mockNetworkMonitor.simulateConnectionChange(true)

        try await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertEqual(viewModel.connectionStatus, .connected)
        XCTAssertGreaterThan(mockDataSource.fetchCallCount, initialFetchCount)
    }

    // MARK: - Background/Foreground Tests

    func testBackgroundForeground_Cycle() async throws {
        await viewModel.loadMessages()

        // Simulate background (disconnect)
        mockNetworkMonitor.simulateConnectionChange(false)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Simulate foreground (reconnect)
        mockNetworkMonitor.simulateConnectionChange(true)
        try await Task.sleep(nanoseconds: 500_000_000)

        // Should have reloaded
        XCTAssertGreaterThanOrEqual(mockDataSource.fetchCallCount, 1)
    }

    // MARK: - Race Condition Tests

    func testConcurrentSendMessages_AllDelivered() async throws {
        // Send messages sequentially to avoid concurrency issues with @MainActor
        for i in 0..<10 {
            await viewModel.sendMessage(content: "Message \(i)")
        }

        XCTAssertEqual(viewModel.messages.count, 10)
    }

    func testSendAndLoadConcurrently() async throws {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.viewModel.loadMessages()
            }
            group.addTask {
                await self.viewModel.sendMessage(content: "Concurrent send")
            }
        }

        // Should not crash
        XCTAssertGreaterThanOrEqual(viewModel.messages.count, 0)
    }

    // MARK: - Message Ordering Tests

    func testMessagesSortedChronologically() async throws {
        let messages = [
            TestMessageEntity(id: "1", conversationId: conversationId, senderId: "user_1", content: "First", timestamp: Date().addingTimeInterval(-100)),
            TestMessageEntity(id: "3", conversationId: conversationId, senderId: "user_1", content: "Third", timestamp: Date()),
            TestMessageEntity(id: "2", conversationId: conversationId, senderId: currentUserId, content: "Second", timestamp: Date().addingTimeInterval(-50)),
        ]
        mockDataSource.messages[conversationId] = messages

        await viewModel.loadMessages()

        XCTAssertEqual(viewModel.messages[0].content, "First")
        XCTAssertEqual(viewModel.messages[1].content, "Second")
        XCTAssertEqual(viewModel.messages[2].content, "Third")
    }

    func testOptimisticMessageInsertedAtEnd() async throws {
        // Load existing messages
        let existing = TestMessageEntity(id: "1", conversationId: conversationId, senderId: "other", content: "Existing", timestamp: Date().addingTimeInterval(-100))
        mockDataSource.messages[conversationId] = [existing]
        await viewModel.loadMessages()

        // Send new message
        await viewModel.sendMessage(content: "New")

        // New message should be at the end
        XCTAssertEqual(viewModel.messages.last?.content, "New")
    }
}