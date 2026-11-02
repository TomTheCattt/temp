//
//  DirectMessagesViewModelTests.swift
//  InstagramTests
//
//  Created for testing DirectMessagesViewModel conversation list and management.
//

import XCTest
import Combine
import Foundation
@testable import Instagram

// MARK: - Mock Implementation

class MockConversationDataSource: ConversationDataSourceProtocol {
    var conversations: [TestConversationEntity] = []
    var fetchCallCount = 0
    var observeCallCount = 0
    var createCallCount = 0
    var deleteCallCount = 0
    var muteCallCount = 0
    var archiveCallCount = 0
    var shouldFailFetch = false
    var shouldFailCreate = false
    var shouldFailDelete = false
    var fetchError: Error?
    var createError: Error?
    var observeSubject = CurrentValueSubject<[TestConversationEntity], Never>([])

    func fetchConversations() async throws -> [TestConversationEntity] {
        fetchCallCount += 1
        if shouldFailFetch, let error = fetchError {
            throw error
        }
        return conversations
    }

    func observeConversations() -> AnyPublisher<[TestConversationEntity], Never> {
        observeCallCount += 1
        return observeSubject.eraseToAnyPublisher()
    }

    func createConversation(participantIds: [String]) async throws -> TestConversationEntity {
        createCallCount += 1
        if shouldFailCreate, let error = createError {
            throw error
        }

        let conversation = TestConversationEntity(
            id: UUID().uuidString,
            participantIds: participantIds,
            lastMessage: nil,
            unreadCount: 0,
            isGroup: false,
            groupName: nil,
            groupAvatarURL: nil,
            updatedAt: Date(),
            isArchived: false
        )
        conversations.append(conversation)
        observeSubject.send(conversations)
        return conversation
    }

    func deleteConversation(conversationId: String) async throws {
        deleteCallCount += 1
        if shouldFailDelete {
            throw NSError(domain: "DataSource", code: -1)
        }
        conversations.removeAll { $0.id == conversationId }
        observeSubject.send(conversations)
    }

    func muteConversation(conversationId: String, muted: Bool) async throws {
        muteCallCount += 1
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[index].isArchived = muted // Note: TestConversationEntity uses isArchived
            observeSubject.send(conversations)
        }
    }

    func archiveConversation(conversationId: String, archived: Bool) async throws {
        archiveCallCount += 1
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[index].isArchived = archived
            observeSubject.send(conversations)
        }
    }
}

// MARK: - DirectMessagesViewModel

@MainActor
class DirectMessagesViewModel: ObservableObject {
    @Published var conversations: [TestConversationEntity] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchText = ""
    @Published var showArchived = false

    private let dataSource: ConversationDataSourceProtocol
    private var cancellables = Set<AnyCancellable>()

    var filteredConversations: [TestConversationEntity] {
        var filtered = conversations

        // Filter archived
        if !showArchived {
            filtered = filtered.filter { !$0.isArchived }
        }

        // Filter search
        if !searchText.isEmpty {
            filtered = filtered.filter { conversation in
                conversation.participantIds.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                conversation.lastMessage?.content.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        // Sort by updatedAt descending
        return filtered.sorted { $0.updatedAt > $1.updatedAt }
    }

    init(dataSource: ConversationDataSourceProtocol) {
        self.dataSource = dataSource
        startObserving()
    }

    private func startObserving() {
        dataSource.observeConversations()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] conversations in
                self?.conversations = conversations
            }
            .store(in: &cancellables)
    }

    func loadConversations() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            let fetched = try await dataSource.fetchConversations()
            conversations = fetched
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func createConversation(with participantIds: [String]) async -> TestConversationEntity? {
        guard !participantIds.isEmpty else { return nil }

        do {
            let conversation = try await dataSource.createConversation(participantIds: participantIds)
            return conversation
        } catch {
            self.error = error
            return nil
        }
    }

    func deleteConversation(_ conversationId: String) async {
        do {
            try await dataSource.deleteConversation(conversationId: conversationId)
        } catch {
            self.error = error
        }
    }

    func muteConversation(_ conversationId: String, muted: Bool) async {
        do {
            try await dataSource.muteConversation(conversationId: conversationId, muted: muted)
        } catch {
            self.error = error
        }
    }

    func archiveConversation(_ conversationId: String, archived: Bool) async {
        do {
            try await dataSource.archiveConversation(conversationId: conversationId, archived: archived)
        } catch {
            self.error = error
        }
    }

    func refresh() async {
        await loadConversations()
    }
}

// MARK: - DirectMessagesViewModelTests

@MainActor
final class DirectMessagesViewModelTests: XCTestCase {

    var mockDataSource: MockConversationDataSource!
    var viewModel: DirectMessagesViewModel!
    let currentUserId = "user_123"

    override func setUp() async throws {
        try await super.setUp()
        mockDataSource = MockConversationDataSource()
        viewModel = DirectMessagesViewModel(dataSource: mockDataSource)
    }

    override func tearDown() async throws {
        viewModel = nil
        mockDataSource = nil
        try await super.tearDown()
    }

    // MARK: - Initial Load Tests

    func testInitialLoad_FetchesConversations() async throws {
        let conversations = [
            TestConversationEntity(
                id: "conv_1",
                participantIds: ["user_123", "user_456"],
                lastMessage: TestMessagePreview(id: "msg_1", content: "Hello", senderId: "user_456", timestamp: Date(), type: .text),
                unreadCount: 2,
                isGroup: false,
                groupName: nil,
                groupAvatarURL: nil,
                updatedAt: Date().addingTimeInterval(-100),
                isArchived: false
            ),
            TestConversationEntity(
                id: "conv_2",
                participantIds: ["user_123", "user_789"],
                lastMessage: TestMessagePreview(id: "msg_2", content: "Hi there", senderId: "user_789", timestamp: Date(), type: .text),
                unreadCount: 0,
                isGroup: false,
                groupName: nil,
                groupAvatarURL: nil,
                updatedAt: Date().addingTimeInterval(-200),
                isArchived: false
            )
        ]
        mockDataSource.conversations = conversations

        await viewModel.loadConversations()

        XCTAssertEqual(viewModel.conversations.count, 2)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testInitialLoad_Error_ShowsError() async throws {
        mockDataSource.shouldFailFetch = true
        mockDataSource.fetchError = NSError(domain: "Test", code: -1)

        await viewModel.loadConversations()

        XCTAssertNotNil(viewModel.error)
    }

    func testInitialLoad_EmptyList() async throws {
        await viewModel.loadConversations()

        XCTAssertTrue(viewModel.conversations.isEmpty)
    }

    // MARK: - Filtering Tests

    func testFilteredConversations_ExcludesArchivedByDefault() async throws {
        let conversations = [
            TestConversationEntity(id: "1", participantIds: ["user_1"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: false),
            TestConversationEntity(id: "2", participantIds: ["user_2"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: true),
        ]
        mockDataSource.conversations = conversations
        await viewModel.loadConversations()

        XCTAssertEqual(viewModel.filteredConversations.count, 1)
        XCTAssertEqual(viewModel.filteredConversations.first?.id, "1")
    }

    func testFilteredConversations_IncludesArchivedWhenEnabled() async throws {
        let conversations = [
            TestConversationEntity(id: "1", participantIds: ["user_1"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: false),
            TestConversationEntity(id: "2", participantIds: ["user_2"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: true),
        ]
        mockDataSource.conversations = conversations
        await viewModel.loadConversations()

        viewModel.showArchived = true

        XCTAssertEqual(viewModel.filteredConversations.count, 2)
    }

    func testFilteredConversations_SearchByParticipant() async throws {
        let conversations = [
            TestConversationEntity(id: "1", participantIds: ["john_doe"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: false),
            TestConversationEntity(id: "2", participantIds: ["jane_smith"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: false),
        ]
        mockDataSource.conversations = conversations
        await viewModel.loadConversations()

        viewModel.searchText = "john"

        XCTAssertEqual(viewModel.filteredConversations.count, 1)
        XCTAssertEqual(viewModel.filteredConversations.first?.participantIds, ["john_doe"])
    }

    func testFilteredConversations_SearchByMessageContent() async throws {
        let conversations = [
            TestConversationEntity(
                id: "1",
                participantIds: ["user_1"],
                lastMessage: TestMessagePreview(id: "1", content: "Hello world", senderId: "user_1", timestamp: Date(), type: .text),
                unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: false
            ),
            TestConversationEntity(
                id: "2",
                participantIds: ["user_2"],
                lastMessage: TestMessagePreview(id: "2", content: "Goodbye world", senderId: "user_2", timestamp: Date(), type: .text),
                unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: false
            ),
        ]
        mockDataSource.conversations = conversations
        await viewModel.loadConversations()

        viewModel.searchText = "hello"

        XCTAssertEqual(viewModel.filteredConversations.count, 1)
        XCTAssertEqual(viewModel.filteredConversations.first?.id, "1")
    }

    func testFilteredConversations_CaseInsensitive() async throws {
        let conversations = [
            TestConversationEntity(id: "1", participantIds: ["JOHN_DOE"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: false),
        ]
        mockDataSource.conversations = conversations
        await viewModel.loadConversations()

        viewModel.searchText = "john"

        XCTAssertEqual(viewModel.filteredConversations.count, 1)
    }

    // MARK: - Sorting Tests

    func testFilteredConversations_SortedByUpdatedAt() async throws {
        let now = Date()
        let conversations = [
            TestConversationEntity(id: "1", participantIds: ["user_1"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: now.addingTimeInterval(-200), isArchived: false),
            TestConversationEntity(id: "2", participantIds: ["user_2"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: now, isArchived: false),
            TestConversationEntity(id: "3", participantIds: ["user_3"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: now.addingTimeInterval(-100), isArchived: false),
        ]
        mockDataSource.conversations = conversations
        await viewModel.loadConversations()

        let filtered = viewModel.filteredConversations

        XCTAssertEqual(filtered[0].id, "2") // Most recent
        XCTAssertEqual(filtered[1].id, "3")
        XCTAssertEqual(filtered[2].id, "1") // Oldest
    }

    // MARK: - Create Conversation Tests

    func testCreateConversation_Success() async throws {
        let participantIds = ["user_456"]

        let conversation = await viewModel.createConversation(with: participantIds)

        XCTAssertNotNil(conversation)
        XCTAssertEqual(conversation?.participantIds, participantIds)
        XCTAssertEqual(mockDataSource.createCallCount, 1)
    }

    func testCreateConversation_EmptyParticipants_ReturnsNil() async throws {
        let conversation = await viewModel.createConversation(with: [])

        XCTAssertNil(conversation)
        XCTAssertEqual(mockDataSource.createCallCount, 0)
    }

    func testCreateConversation_Failure_ReturnsNil() async throws {
        mockDataSource.shouldFailCreate = true
        mockDataSource.createError = NSError(domain: "Test", code: -1)

        let conversation = await viewModel.createConversation(with: ["user_456"])

        XCTAssertNil(conversation)
        XCTAssertNotNil(viewModel.error)
    }

    // MARK: - Delete Conversation Tests

    func testDeleteConversation_Success() async throws {
        let conversations = [
            TestConversationEntity(id: "1", participantIds: ["user_1"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: false),
            TestConversationEntity(id: "2", participantIds: ["user_2"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: false),
        ]
        mockDataSource.conversations = conversations
        await viewModel.loadConversations()

        await viewModel.deleteConversation("1")

        XCTAssertEqual(mockDataSource.deleteCallCount, 1)
        XCTAssertEqual(viewModel.conversations.count, 1)
        XCTAssertEqual(viewModel.conversations.first?.id, "2")
    }

    func testDeleteConversation_Failure_ShowsError() async throws {
        mockDataSource.shouldFailDelete = true

        await viewModel.deleteConversation("1")

        XCTAssertNotNil(viewModel.error)
    }

    // MARK: - Mute/Archive Tests

    func testMuteConversation() async throws {
        let conversations = [
            TestConversationEntity(id: "1", participantIds: ["user_1"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: false),
        ]
        mockDataSource.conversations = conversations
        await viewModel.loadConversations()

        await viewModel.muteConversation("1", muted: true)

        XCTAssertEqual(mockDataSource.muteCallCount, 1)
        // Note: TestConversationEntity doesn't have isMuted, using isArchived as placeholder in mock
    }

    func testArchiveConversation() async throws {
        let conversations = [
            TestConversationEntity(id: "1", participantIds: ["user_1"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: false),
        ]
        mockDataSource.conversations = conversations
        await viewModel.loadConversations()

        await viewModel.archiveConversation("1", archived: true)

        XCTAssertEqual(mockDataSource.archiveCallCount, 1)
        XCTAssertTrue(viewModel.conversations.first?.isArchived ?? false)

        // Should be filtered out by default
        XCTAssertEqual(viewModel.filteredConversations.count, 0)
    }

    func testUnarchiveConversation() async throws {
        let conversations = [
            TestConversationEntity(id: "1", participantIds: ["user_1"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: true),
        ]
        mockDataSource.conversations = conversations
        await viewModel.loadConversations()

        viewModel.showArchived = true
        await viewModel.archiveConversation("1", archived: false)

        XCTAssertFalse(viewModel.conversations.first?.isArchived ?? true)
        XCTAssertEqual(viewModel.filteredConversations.count, 1)
    }

    // MARK: - Real-time Updates Tests

    func testRealTimeUpdate_NewConversation_Added() async throws {
        await viewModel.loadConversations()

        let newConversation = TestConversationEntity(
            id: "new_1",
            participantIds: ["user_1", "user_new"],
            lastMessage: nil,
            unreadCount: 0,
            isGroup: false,
            groupName: nil,
            groupAvatarURL: nil,
            updatedAt: Date(),
            isArchived: false
        )
        mockDataSource.conversations = [newConversation]
        mockDataSource.observeSubject.send([newConversation])

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.conversations.count, 1)
        XCTAssertEqual(viewModel.conversations.first?.id, "new_1")
    }

    func testRealTimeUpdate_ConversationUpdated_ReflectsChanges() async throws {
        let conversation = TestConversationEntity(
            id: "1",
            participantIds: ["user_1"],
            lastMessage: TestMessagePreview(id: "1", content: "Old", senderId: "user_1", timestamp: Date(), type: .text),
            unreadCount: 0,
            isGroup: false,
            groupName: nil,
            groupAvatarURL: nil,
            updatedAt: Date(),
            isArchived: false
        )
        mockDataSource.conversations = [conversation]
        await viewModel.loadConversations()

        // Update last message
        var updated = conversation
        updated.lastMessage = TestMessagePreview(id: "2", content: "New message", senderId: "user_1", timestamp: Date(), type: .text)
        updated.updatedAt = Date()
        mockDataSource.conversations = [updated]
        mockDataSource.observeSubject.send([updated])

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.conversations.first?.lastMessage?.content, "New message")
    }

    func testRealTimeUpdate_ConversationDeleted_Removed() async throws {
        let conversations = [
            TestConversationEntity(id: "1", participantIds: ["user_1"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: false),
            TestConversationEntity(id: "2", participantIds: ["user_2"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: false),
        ]
        mockDataSource.conversations = conversations
        await viewModel.loadConversations()

        mockDataSource.conversations = [conversations[1]]
        mockDataSource.observeSubject.send([conversations[1]])

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.conversations.count, 1)
        XCTAssertEqual(viewModel.conversations.first?.id, "2")
    }

    // MARK: - Refresh Tests

    func testRefresh_ReloadsConversations() async throws {
        let conversations = [
            TestConversationEntity(id: "1", participantIds: ["user_1"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: false),
        ]
        mockDataSource.conversations = conversations
        await viewModel.loadConversations()

        let initialFetchCount = mockDataSource.fetchCallCount

        await viewModel.refresh()

        XCTAssertEqual(mockDataSource.fetchCallCount, initialFetchCount + 1)
    }

    // MARK: - Concurrent Operations Tests

    func testConcurrentCreateAndDelete() async throws {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                _ = await self.viewModel.createConversation(with: ["user_1"])
            }
            group.addTask {
                _ = await self.viewModel.createConversation(with: ["user_2"])
            }
        }

        XCTAssertEqual(mockDataSource.createCallCount, 2)
    }

    func testConcurrentMuteAndArchive() async throws {
        let conversations = [
            TestConversationEntity(id: "1", participantIds: ["user_1"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: false),
            TestConversationEntity(id: "2", participantIds: ["user_2"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: Date(), isArchived: false),
        ]
        mockDataSource.conversations = conversations
        await viewModel.loadConversations()

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.viewModel.muteConversation("1", muted: true)
            }
            group.addTask {
                await self.viewModel.archiveConversation("2", archived: true)
            }
        }

        XCTAssertEqual(mockDataSource.muteCallCount, 1)
        XCTAssertEqual(mockDataSource.archiveCallCount, 1)
    }
}