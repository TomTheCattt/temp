// MARK: - Shared Test Models
//
// Common test-only model types shared across test files to avoid
// duplicate type definitions in the same test target.

import Foundation
import Combine

// MARK: - Message Status

enum TestMessageStatus: Codable, Equatable, Sendable {
    case sending
    case sent
    case delivered
    case read
    case failed(Error?)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let statusString = try container.decode(String.self)
        switch statusString {
        case "sending": self = .sending
        case "sent": self = .sent
        case "delivered": self = .delivered
        case "read": self = .read
        case "failed": self = .failed(nil)
        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid TestMessageStatus: \(statusString)"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.firestoreValue)
    }

    static func == (lhs: TestMessageStatus, rhs: TestMessageStatus) -> Bool {
        switch (lhs, rhs) {
        case (.sending, .sending), (.sent, .sent), (.delivered, .delivered), (.read, .read):
            return true
        case (.failed, .failed):
            // For testing, consider failed equal regardless of error
            return true
        default:
            return false
        }
    }
}

// For testing convenience - all cases without associated values
extension TestMessageStatus {
    static var allTestCases: [TestMessageStatus] {
        return [.sending, .sent, .delivered, .read, .failed(nil)]
    }

    var firestoreValue: String {
        switch self {
        case .sending: return "sending"
        case .sent: return "sent"
        case .delivered: return "delivered"
        case .read: return "read"
        case .failed: return "failed"
        }
    }

    static func fromFirestoreValue(_ value: String) -> TestMessageStatus? {
        switch value {
        case "sending": return .sending
        case "sent": return .sent
        case "delivered": return .delivered
        case "read": return .read
        case "failed": return .failed(nil)
        default: return nil
        }
    }
}

// MARK: - Message Type

enum TestMessageType: String, Codable, Sendable, CaseIterable {
    case text
    case image
    case video
    case audio
    case file
    case system
}

// MARK: - Attachment

struct TestAttachment: Codable, Equatable, Sendable {
    let id: String
    let url: String
    let type: TestAttachmentType
    let size: Int64
    let thumbnailUrl: String?

    init(id: String = UUID().uuidString,
         url: String,
         type: TestAttachmentType,
         size: Int64,
         thumbnailUrl: String? = nil) {
        self.id = id
        self.url = url
        self.type = type
        self.size = size
        self.thumbnailUrl = thumbnailUrl
    }

    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "url": url,
            "type": type.rawValue,
            "size": size,
            "thumbnailUrl": thumbnailUrl as Any
        ]
    }

    static func fromFirestoreData(_ data: [String: Any]) -> TestAttachment? {
        guard let id = data["id"] as? String,
              let url = data["url"] as? String,
              let typeRaw = data["type"] as? String,
              let type = TestAttachmentType(rawValue: typeRaw) else {
            return nil
        }
        // Handle size as Int or Int64
        let size: Int64
        if let sizeInt64 = data["size"] as? Int64 {
            size = sizeInt64
        } else if let sizeInt = data["size"] as? Int {
            size = Int64(sizeInt)
        } else {
            return nil
        }
        let thumbnailUrl = data["thumbnailUrl"] as? String
        return TestAttachment(id: id, url: url, type: type, size: size, thumbnailUrl: thumbnailUrl)
    }
}

enum TestAttachmentType: String, Codable, Sendable, CaseIterable {
    case image, video, audio, file
}

// MARK: - Message Entity

struct TestMessageEntity: Identifiable, Equatable, Sendable, Codable {
    var id: String
    let conversationId: String
    let senderId: String
    let content: String
    let type: TestMessageType
    var timestamp: Date
    var status: TestMessageStatus
    var replyToMessageId: String?
    var attachments: [TestAttachment]
    var readBy: [String]

    init(id: String = UUID().uuidString,
         conversationId: String,
         senderId: String,
         content: String,
         type: TestMessageType = .text,
         timestamp: Date = Date(),
         status: TestMessageStatus = .sending,
         replyToMessageId: String? = nil,
         attachments: [TestAttachment] = [],
         readBy: [String] = []) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.content = content
        self.type = type
        self.timestamp = timestamp
        self.status = status
        self.replyToMessageId = replyToMessageId
        self.attachments = attachments
        self.readBy = readBy
    }

    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "conversationId": conversationId,
            "senderId": senderId,
            "content": content,
            "type": type.rawValue,
            "timestamp": timestamp,
            "status": status.firestoreValue,
            "readBy": readBy
        ]
        if let replyTo = replyToMessageId {
            data["replyToMessageId"] = replyTo
        }
        if !attachments.isEmpty {
            data["attachments"] = attachments.map { $0.toFirestoreData() }
        }
        return data
    }

    static func fromFirestoreData(_ data: [String: Any], id: String) -> TestMessageEntity? {
        guard let conversationId = data["conversationId"] as? String,
              let senderId = data["senderId"] as? String,
              let content = data["content"] as? String,
              let typeRaw = data["type"] as? String,
              let type = TestMessageType(rawValue: typeRaw),
              let timestamp = (data["timestamp"] as? Date) ?? (data["timestamp"] as? Timestamp)?.dateValue(),
              let statusRaw = data["status"] as? String,
              let status = TestMessageStatus.fromFirestoreValue(statusRaw) else {
            return nil
        }

        let replyToMessageId = data["replyToMessageId"] as? String
        let attachments = (data["attachments"] as? [[String: Any]])?.compactMap { TestAttachment.fromFirestoreData($0) } ?? []
        let readBy = data["readBy"] as? [String] ?? []

        return TestMessageEntity(
            id: id,
            conversationId: conversationId,
            senderId: senderId,
            content: content,
            type: type,
            timestamp: timestamp,
            status: status,
            replyToMessageId: replyToMessageId,
            attachments: attachments,
            readBy: readBy
        )
    }
}

// MARK: - Conversation Entity

struct TestConversationEntity: Identifiable, Equatable, Sendable {
    let id: String
    let participantIds: [String]
    var lastMessage: TestMessagePreview?
    let unreadCount: Int
    let isGroup: Bool
    let groupName: String?
    let groupAvatarURL: URL?
    var updatedAt: Date
    var isArchived: Bool = false

    init(id: String = UUID().uuidString,
         participantIds: [String],
         lastMessage: TestMessagePreview? = nil,
         unreadCount: Int = 0,
         isGroup: Bool = false,
         groupName: String? = nil,
         groupAvatarURL: URL? = nil,
         updatedAt: Date = Date(),
         isArchived: Bool = false) {
        self.id = id
        self.participantIds = participantIds
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
        self.isGroup = isGroup
        self.groupName = groupName
        self.groupAvatarURL = groupAvatarURL
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }
}

// MARK: - Message Preview

struct TestMessagePreview: Equatable, Sendable {
    let id: String
    let content: String
    let senderId: String
    let timestamp: Date
    let type: TestMessageType

    init(id: String = UUID().uuidString,
         content: String,
         senderId: String,
         timestamp: Date = Date(),
         type: TestMessageType = .text) {
        self.id = id
        self.content = content
        self.senderId = senderId
        self.timestamp = timestamp
        self.type = type
    }
}

// MARK: - Network Connection Type

enum TestNetworkConnectionType: Equatable, Sendable {
    case wifi
    case cellular
    case none
}

// MARK: - Mock Network Monitor

@MainActor
final class TestMockNetworkMonitor: Sendable {
    var isConnected = true
    var connectionType: TestNetworkConnectionType = .wifi
    let subject = CurrentValueSubject<Bool, Never>(true)

    var isConnectedPublisher: AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    func simulateConnectionChange(_ connected: Bool, type: TestNetworkConnectionType = .wifi) {
        isConnected = connected
        connectionType = type
        subject.send(connected)
    }
}

// MARK: - Shared Test Protocols

protocol MessageDataSourceProtocol {
    func fetchMessages(conversationId: String, limit: Int, before: Date?) async throws -> [TestMessageEntity]
    func sendMessage(_ message: TestMessageEntity) async throws -> TestMessageEntity
    func observeMessages(conversationId: String) -> AnyPublisher<[TestMessageEntity], Never>
    func markAsRead(conversationId: String, messageId: String) async throws
    func deleteMessage(messageId: String) async throws
}

protocol ConversationDataSourceProtocol {
    func fetchConversations() async throws -> [TestConversationEntity]
    func observeConversations() -> AnyPublisher<[TestConversationEntity], Never>
    func createConversation(participantIds: [String]) async throws -> TestConversationEntity
    func deleteConversation(conversationId: String) async throws
    func muteConversation(conversationId: String, muted: Bool) async throws
    func archiveConversation(conversationId: String, archived: Bool) async throws
}

// MARK: - Timestamp Helper (for Firestore compatibility)

struct Timestamp {
    let seconds: Int64
    let nanoseconds: Int32

    init(date: Date) {
        let interval = date.timeIntervalSince1970
        self.seconds = Int64(interval)
        self.nanoseconds = Int32((interval - Double(seconds)) * 1_000_000_000)
    }

    func dateValue() -> Date {
        return Date(timeIntervalSince1970: Double(seconds) + Double(nanoseconds) / 1_000_000_000)
    }
}