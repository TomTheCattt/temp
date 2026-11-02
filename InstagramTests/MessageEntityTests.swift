//
//  MessageEntityTests.swift
//  InstagramTests
//
//  Created for testing MessageEntity and related value types.
//

import XCTest
import Foundation
@testable import Instagram

// MARK: - MessageEntity Tests

final class MessageEntityTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_WithAllParameters() {
        let id = "msg_123"
        let conversationId = "conv_456"
        let senderId = "user_789"
        let content = "Hello World"
        let type = TestMessageType.image
        let timestamp = Date()
        let status = TestMessageStatus.sent
        let replyToMessageId = "msg_001"
        let attachments = [TestAttachment(id: "att_1", url: "https://example.com/img.jpg", type: .image, size: 1024, thumbnailUrl: "https://example.com/thumb.jpg")]
        let readBy = ["user_1", "user_2"]

        let message = TestMessageEntity(
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

        XCTAssertEqual(message.id, id)
        XCTAssertEqual(message.conversationId, conversationId)
        XCTAssertEqual(message.senderId, senderId)
        XCTAssertEqual(message.content, content)
        XCTAssertEqual(message.type, type)
        XCTAssertEqual(message.timestamp, timestamp)
        XCTAssertEqual(message.status, status)
        XCTAssertEqual(message.replyToMessageId, replyToMessageId)
        XCTAssertEqual(message.attachments, attachments)
        XCTAssertEqual(message.readBy, readBy)
    }

    func testInit_WithDefaults() {
        let message = TestMessageEntity(
            conversationId: "conv_1",
            senderId: "user_1",
            content: "Test"
        )

        XCTAssertFalse(message.id.isEmpty)
        XCTAssertEqual(message.conversationId, "conv_1")
        XCTAssertEqual(message.senderId, "user_1")
        XCTAssertEqual(message.content, "Test")
        XCTAssertEqual(message.type, .text)
        XCTAssertNotNil(message.timestamp)
        XCTAssertEqual(message.status, .sending)
        XCTAssertNil(message.replyToMessageId)
        XCTAssertTrue(message.attachments.isEmpty)
        XCTAssertTrue(message.readBy.isEmpty)
    }

    // MARK: - Equality Tests

    func testEquality_SameValues_ReturnsTrue() {
        let date = Date()
        let msg1 = TestMessageEntity(id: "1", conversationId: "c1", senderId: "u1", content: "Hi", timestamp: date, status: .sent)
        let msg2 = TestMessageEntity(id: "1", conversationId: "c1", senderId: "u1", content: "Hi", timestamp: date, status: .sent)

        XCTAssertEqual(msg1, msg2)
    }

    func testEquality_DifferentId_ReturnsFalse() {
        let date = Date()
        let msg1 = TestMessageEntity(id: "1", conversationId: "c1", senderId: "u1", content: "Hi", timestamp: date, status: .sent)
        let msg2 = TestMessageEntity(id: "2", conversationId: "c1", senderId: "u1", content: "Hi", timestamp: date, status: .sent)

        XCTAssertNotEqual(msg1, msg2)
    }

    func testEquality_DifferentContent_ReturnsFalse() {
        let date = Date()
        let msg1 = TestMessageEntity(id: "1", conversationId: "c1", senderId: "u1", content: "Hi", timestamp: date, status: .sent)
        let msg2 = TestMessageEntity(id: "1", conversationId: "c1", senderId: "u1", content: "Hello", timestamp: date, status: .sent)

        XCTAssertNotEqual(msg1, msg2)
    }

    func testEquality_DifferentStatus_ReturnsFalse() {
        let date = Date()
        let msg1 = TestMessageEntity(id: "1", conversationId: "c1", senderId: "u1", content: "Hi", timestamp: date, status: .sent)
        let msg2 = TestMessageEntity(id: "1", conversationId: "c1", senderId: "u1", content: "Hi", timestamp: date, status: .read)

        XCTAssertNotEqual(msg1, msg2)
    }

    func testEquality_DifferentAttachments_ReturnsFalse() {
        let date = Date()
        let att = TestAttachment(id: "a1", url: "https://example.com/img.jpg", type: .image, size: 1024, thumbnailUrl: nil)
        let msg1 = TestMessageEntity(id: "1", conversationId: "c1", senderId: "u1", content: "Hi", timestamp: date, status: .sent, attachments: [att])
        let msg2 = TestMessageEntity(id: "1", conversationId: "c1", senderId: "u1", content: "Hi", timestamp: date, status: .sent, attachments: [])

        XCTAssertNotEqual(msg1, msg2)
    }

    // MARK: - Codable Tests

    func testEncoding_Decoding_RoundTrip() throws {
        let original = TestMessageEntity(
            id: "msg_123",
            conversationId: "conv_456",
            senderId: "user_789",
            content: "Hello World",
            type: .video,
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            status: .delivered,
            replyToMessageId: "msg_001",
            attachments: [
                TestAttachment(id: "att_1", url: "https://example.com/video.mp4", type: .video, size: 10_000_000, thumbnailUrl: "https://example.com/thumb.jpg")
            ],
            readBy: ["user_1", "user_2"]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TestMessageEntity.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testEncoding_WithMinimalFields() throws {
        let original = TestMessageEntity(
            conversationId: "conv_1",
            senderId: "user_1",
            content: "Simple message"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TestMessageEntity.self, from: data)

        XCTAssertEqual(decoded.conversationId, "conv_1")
        XCTAssertEqual(decoded.senderId, "user_1")
        XCTAssertEqual(decoded.content, "Simple message")
        XCTAssertEqual(decoded.type, .text)
        XCTAssertEqual(decoded.status, .sending)
    }

    func testDecoding_FromJSONString() throws {
        let json = """
        {
            "id": "msg_123",
            "conversationId": "conv_456",
            "senderId": "user_789",
            "content": "Test message",
            "type": "image",
            "timestamp": "2024-01-15T10:30:00Z",
            "status": "read",
            "replyToMessageId": "msg_001",
            "attachments": [
                {
                    "id": "att_1",
                    "url": "https://example.com/img.jpg",
                    "type": "image",
                    "size": 2048,
                    "thumbnailUrl": "https://example.com/thumb.jpg"
                }
            ],
            "readBy": ["user_1", "user_2"]
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let message = try decoder.decode(TestMessageEntity.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(message.id, "msg_123")
        XCTAssertEqual(message.type, .image)
        XCTAssertEqual(message.status, .read)
        XCTAssertEqual(message.attachments.count, 1)
        XCTAssertEqual(message.readBy.count, 2)
    }

    // MARK: - Firestore Conversion Tests

    func testToFirestoreData_IncludesAllFields() {
        let message = TestMessageEntity(
            id: "msg_123",
            conversationId: "conv_456",
            senderId: "user_789",
            content: "Test",
            type: .audio,
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            status: .sent,
            replyToMessageId: "msg_001",
            attachments: [
                TestAttachment(id: "att_1", url: "https://example.com/audio.m4a", type: .audio, size: 500_000, thumbnailUrl: nil)
            ],
            readBy: ["user_1"]
        )

        let data = message.toFirestoreData()

        XCTAssertEqual(data["id"] as? String, "msg_123")
        XCTAssertEqual(data["conversationId"] as? String, "conv_456")
        XCTAssertEqual(data["senderId"] as? String, "user_789")
        XCTAssertEqual(data["content"] as? String, "Test")
        XCTAssertEqual(data["type"] as? String, "audio")
        XCTAssertNotNil(data["timestamp"])
        XCTAssertEqual(data["status"] as? String, "sent")
        XCTAssertEqual(data["replyToMessageId"] as? String, "msg_001")
        XCTAssertEqual(data["readBy"] as? [String], ["user_1"])

        let attachments = data["attachments"] as? [[String: Any]]
        XCTAssertNotNil(attachments)
        XCTAssertEqual(attachments?.count, 1)
        XCTAssertEqual(attachments?.first?["id"] as? String, "att_1")
    }

    func testFromFirestoreData_ValidData_ReturnsMessage() {
        let data: [String: Any] = [
            "id": "msg_123",
            "conversationId": "conv_456",
            "senderId": "user_789",
            "content": "From Firestore",
            "type": "file",
            "timestamp": Timestamp(date: Date(timeIntervalSince1970: 1_700_000_000)),
            "status": "delivered",
            "replyToMessageId": "msg_001",
            "attachments": [
                [
                    "id": "att_1",
                    "url": "https://example.com/file.pdf",
                    "type": "file",
                    "size": 1_000_000,
                    "thumbnailUrl": NSNull()
                ]
            ],
            "readBy": ["user_1", "user_2"]
        ]

        let message = TestMessageEntity.fromFirestoreData(data, id: "msg_123")

        XCTAssertNotNil(message)
        XCTAssertEqual(message?.id, "msg_123")
        XCTAssertEqual(message?.content, "From Firestore")
        XCTAssertEqual(message?.type, .file)
        XCTAssertEqual(message?.status, .delivered)
        XCTAssertEqual(message?.replyToMessageId, "msg_001")
        XCTAssertEqual(message?.attachments.count, 1)
        XCTAssertEqual(message?.readBy.count, 2)
    }

    func testFromFirestoreData_MissingRequiredFields_ReturnsNil() {
        let data: [String: Any] = [
            "conversationId": "conv_456",
            "senderId": "user_789",
            "content": "Incomplete"
            // Missing type, timestamp, status
        ]

        let message = TestMessageEntity.fromFirestoreData(data, id: "msg_123")

        XCTAssertNil(message)
    }

    func testFromFirestoreData_InvalidType_ReturnsNil() {
        let data: [String: Any] = [
            "conversationId": "conv_456",
            "senderId": "user_789",
            "content": "Test",
            "type": "invalid_type",
            "timestamp": Timestamp(date: Date()),
            "status": "sent"
        ]

        let message = TestMessageEntity.fromFirestoreData(data, id: "msg_123")

        XCTAssertNil(message)
    }

    func testFromFirestoreData_InvalidStatus_ReturnsNil() {
        let data: [String: Any] = [
            "conversationId": "conv_456",
            "senderId": "user_789",
            "content": "Test",
            "type": "text",
            "timestamp": Timestamp(date: Date()),
            "status": "invalid_status"
        ]

        let message = TestMessageEntity.fromFirestoreData(data, id: "msg_123")

        XCTAssertNil(message)
    }

    func testFromFirestoreData_DateAsDateObject() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let data: [String: Any] = [
            "conversationId": "conv_456",
            "senderId": "user_789",
            "content": "Test",
            "type": "text",
            "timestamp": date,
            "status": "sent"
        ]

        let message = TestMessageEntity.fromFirestoreData(data, id: "msg_123")

        XCTAssertNotNil(message)
        XCTAssertEqual(message?.timestamp, date)
    }

    // MARK: - MessageType Tests

    func testMessageType_AllCases() {
        let types: [TestMessageType] = [.text, .image, .video, .audio, .file, .system]

        for type in types {
            XCTAssertNotNil(type.rawValue)
            XCTAssertFalse(type.rawValue.isEmpty)
        }
    }

    func testMessageType_RawValueRoundTrip() {
        for type in TestMessageType.allCases {
            let decoded = TestMessageType(rawValue: type.rawValue)
            XCTAssertEqual(decoded, type)
        }
    }

    // MARK: - MessageStatus Tests

    func testMessageStatus_AllCases() {
        let statuses = TestMessageStatus.allTestCases

        for status in statuses {
            XCTAssertNotNil(status.firestoreValue)
            XCTAssertFalse(status.firestoreValue.isEmpty)
        }
    }

    func testMessageStatus_FirestoreValueRoundTrip() {
        for status in TestMessageStatus.allTestCases {
            let decoded = TestMessageStatus.fromFirestoreValue(status.firestoreValue)
            XCTAssertEqual(decoded, status)
        }
    }

    func testMessageStatus_Equality() {
        XCTAssertEqual(TestMessageStatus.sent, TestMessageStatus.sent)
        XCTAssertEqual(TestMessageStatus.failed(nil), TestMessageStatus.failed(nil))
        XCTAssertNotEqual(TestMessageStatus.sent, TestMessageStatus.read)
    }

    // MARK: - Attachment Tests

    func testAttachment_Init() {
        let attachment = TestAttachment(
            id: "att_1",
            url: "https://example.com/img.jpg",
            type: .image,
            size: 1024,
            thumbnailUrl: "https://example.com/thumb.jpg"
        )

        XCTAssertEqual(attachment.id, "att_1")
        XCTAssertEqual(attachment.url, "https://example.com/img.jpg")
        XCTAssertEqual(attachment.type, .image)
        XCTAssertEqual(attachment.size, 1024)
        XCTAssertEqual(attachment.thumbnailUrl, "https://example.com/thumb.jpg")
    }

    func testAttachment_Equality() {
        let att1 = TestAttachment(id: "1", url: "url", type: .image, size: 100, thumbnailUrl: nil)
        let att2 = TestAttachment(id: "1", url: "url", type: .image, size: 100, thumbnailUrl: nil)
        let att3 = TestAttachment(id: "2", url: "url", type: .image, size: 100, thumbnailUrl: nil)

        XCTAssertEqual(att1, att2)
        XCTAssertNotEqual(att1, att3)
    }

    func testAttachment_Codable() throws {
        let original = TestAttachment(id: "att_1", url: "https://example.com/vid.mp4", type: .video, size: 5_000_000, thumbnailUrl: "https://example.com/thumb.jpg")

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TestAttachment.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testAttachment_FirestoreConversion() {
        let attachment = TestAttachment(
            id: "att_1",
            url: "https://example.com/audio.m4a",
            type: .audio,
            size: 2_000_000,
            thumbnailUrl: nil
        )

        let data = attachment.toFirestoreData()

        XCTAssertEqual(data["id"] as? String, "att_1")
        XCTAssertEqual(data["url"] as? String, "https://example.com/audio.m4a")
        XCTAssertEqual(data["type"] as? String, "audio")
        XCTAssertEqual(data["size"] as? Int64, 2_000_000)
        XCTAssertNil(data["thumbnailUrl"] as? String)
    }

    func testAttachment_FromFirestoreData() {
        let data: [String: Any] = [
            "id": "att_1",
            "url": "https://example.com/img.jpg",
            "type": "image",
            "size": 1024,
            "thumbnailUrl": "https://example.com/thumb.jpg"
        ]

        let attachment = TestAttachment.fromFirestoreData(data)

        XCTAssertNotNil(attachment)
        XCTAssertEqual(attachment?.id, "att_1")
        XCTAssertEqual(attachment?.type, .image)
    }

    func testAttachment_FromFirestoreData_MissingFields_ReturnsNil() {
        let data: [String: Any] = [
            "id": "att_1",
            "url": "https://example.com/img.jpg"
            // Missing type, size
        ]

        let attachment = TestAttachment.fromFirestoreData(data)

        XCTAssertNil(attachment)
    }

    // MARK: - AttachmentType Tests

    func testAttachmentType_AllCases() {
        let types: [TestAttachmentType] = [.image, .video, .audio, .file]

        for type in types {
            XCTAssertNotNil(type.rawValue)
            XCTAssertFalse(type.rawValue.isEmpty)
        }
    }

    // MARK: - MessagePreview Tests

    func testMessagePreview_Init() {
        let preview = TestMessagePreview(
            id: "msg_1",
            content: "Preview content",
            senderId: "user_1",
            timestamp: Date(),
            type: .text
        )

        XCTAssertEqual(preview.id, "msg_1")
        XCTAssertEqual(preview.content, "Preview content")
        XCTAssertEqual(preview.senderId, "user_1")
        XCTAssertEqual(preview.type, .text)
    }

    func testMessagePreview_Equality() {
        let date = Date()
        let p1 = TestMessagePreview(id: "1", content: "Hi", senderId: "u1", timestamp: date, type: .text)
        let p2 = TestMessagePreview(id: "1", content: "Hi", senderId: "u1", timestamp: date, type: .text)
        let p3 = TestMessagePreview(id: "2", content: "Hi", senderId: "u1", timestamp: date, type: .text)

        XCTAssertEqual(p1, p2)
        XCTAssertNotEqual(p1, p3)
    }

    // MARK: - ConversationEntity Tests

    func testConversationEntity_Init() {
        let conversation = TestConversationEntity(
            id: "conv_1",
            participantIds: ["user_1", "user_2"],
            lastMessage: TestMessagePreview(id: "msg_1", content: "Last msg", senderId: "user_2", timestamp: Date(), type: .text),
            unreadCount: 5,
            isGroup: false,
            groupName: nil,
            groupAvatarURL: nil,
            updatedAt: Date(),
            isArchived: false
        )

        XCTAssertEqual(conversation.id, "conv_1")
        XCTAssertEqual(conversation.participantIds, ["user_1", "user_2"])
        XCTAssertEqual(conversation.unreadCount, 5)
        XCTAssertFalse(conversation.isArchived)
    }

    func testConversationEntity_Equality() {
        let date = Date()
        let c1 = TestConversationEntity(id: "1", participantIds: ["u1"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: date, isArchived: false)
        let c2 = TestConversationEntity(id: "1", participantIds: ["u1"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: date, isArchived: false)
        let c3 = TestConversationEntity(id: "2", participantIds: ["u1"], lastMessage: nil, unreadCount: 0, isGroup: false, groupName: nil, groupAvatarURL: nil, updatedAt: date, isArchived: false)

        XCTAssertEqual(c1, c2)
        XCTAssertNotEqual(c1, c3)
    }

    // MARK: - Timestamp Tests

    func testTimestamp_RoundTrip() {
        let originalDate = Date(timeIntervalSince1970: 1_700_000_000.123456)
        let timestamp = Timestamp(date: originalDate)
        let decodedDate = timestamp.dateValue()

        XCTAssertEqual(decodedDate.timeIntervalSince1970, originalDate.timeIntervalSince1970, accuracy: 0.001)
    }

    func testTimestamp_SecondsAndNanoseconds() {
        let date = Date(timeIntervalSince1970: 1_700_000_000.5)
        let timestamp = Timestamp(date: date)

        XCTAssertEqual(timestamp.seconds, 1_700_000_000)
        XCTAssertEqual(timestamp.nanoseconds, 500_000_000)
    }

    // MARK: - Edge Cases Tests

    func testMessageEntity_VeryLongContent() {
        let longContent = String(repeating: "A", count: 10_000)
        let message = TestMessageEntity(conversationId: "c1", senderId: "u1", content: longContent)

        XCTAssertEqual(message.content.count, 10_000)
    }

    func testMessageEntity_ManyAttachments() {
        let attachments = (0..<20).map { i in
            TestAttachment(id: "att_\(i)", url: "https://example.com/\(i).jpg", type: .image, size: 1024, thumbnailUrl: nil)
        }
        let message = TestMessageEntity(conversationId: "c1", senderId: "u1", content: "Many images", attachments: attachments)

        XCTAssertEqual(message.attachments.count, 20)
    }

    func testMessageEntity_ManyReadBy() {
        let readBy = (0..<100).map { "user_\($0)" }
        let message = TestMessageEntity(conversationId: "c1", senderId: "u1", content: "Read by many", readBy: readBy)

        XCTAssertEqual(message.readBy.count, 100)
    }

    func testMessageEntity_UnicodeContent() {
        let unicodeContent = "Hello 🌍 你好 🇯🇵 مرحبا"
        let message = TestMessageEntity(conversationId: "c1", senderId: "u1", content: unicodeContent)

        XCTAssertEqual(message.content, unicodeContent)
    }

    func testMessageEntity_EmptyStrings() {
        let message = TestMessageEntity(
            id: "",
            conversationId: "",
            senderId: "",
            content: "",
            type: .text,
            timestamp: Date(),
            status: .sending,
            replyToMessageId: "",
            attachments: [],
            readBy: []
        )

        XCTAssertEqual(message.id, "")
        XCTAssertEqual(message.conversationId, "")
        XCTAssertEqual(message.senderId, "")
        XCTAssertEqual(message.content, "")
        XCTAssertEqual(message.replyToMessageId, "")
    }

    // MARK: - Value Type Semantics Tests

    func testMessageEntity_IsValueType() {
        let msg1 = TestMessageEntity(id: "1", conversationId: "c1", senderId: "u1", content: "Original", timestamp: Date(), status: .sent)
        var msg2 = msg1

        msg2 = TestMessageEntity(id: "2", conversationId: "c1", senderId: "u1", content: "Modified", timestamp: Date(), status: .sent)

        XCTAssertEqual(msg1.content, "Original")
        XCTAssertEqual(msg2.content, "Modified")
    }

    func testAttachment_IsValueType() {
        let att1 = TestAttachment(id: "1", url: "url1", type: .image, size: 100, thumbnailUrl: nil)
        var att2 = att1

        att2 = TestAttachment(id: "2", url: "url2", type: .video, size: 200, thumbnailUrl: nil)

        XCTAssertEqual(att1.id, "1")
        XCTAssertEqual(att2.id, "2")
    }
}