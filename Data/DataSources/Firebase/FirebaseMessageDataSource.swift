//
//  FirebaseMessageDataSource.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation
import FirebaseFirestore
import Combine

// MARK: - FirebaseMessageDataSource

/// Production implementation of MessageRepositoryProtocol backed by Firebase Firestore.
/// Provides real-time synchronization for conversations and messages.
actor FirebaseMessageDataSource: MessageRepositoryProtocol {

    static let shared = FirebaseMessageDataSource()

    // MARK: - Private State

    // Use nonisolated(unsafe) since Firestore.firestore() is not Sendable but we only access it from this actor
    nonisolated(unsafe) let db = Firestore.firestore()
    private var conversationListener: ListenerRegistration?
    private var messageListeners: [String: ListenerRegistration] = [:]
    private var notesListener: ListenerRegistration?

    // In-memory caches for real-time updates
    private var cachedConversations: [Conversation] = []
    private var cachedMessages: [String: [Message]] = [:]
    private var cachedNotes: [InstagramNote] = []
    private var currentUserId: String = ""

    // Continuations for async bridging
    private var conversationsContinuation: AsyncStream<[Conversation]>.Continuation?
    private var notesContinuation: AsyncStream<[InstagramNote]>.Continuation?

    // Published streams for real-time updates
    nonisolated let conversationsStream: AsyncStream<[Conversation]>
    nonisolated let notesStream: AsyncStream<[InstagramNote]>

    private init() {
        var conversationsCont: AsyncStream<[Conversation]>.Continuation?
        var notesCont: AsyncStream<[InstagramNote]>.Continuation?

        self.conversationsStream = AsyncStream<[Conversation]> { continuation in
            conversationsCont = continuation
        }

        self.notesStream = AsyncStream<[InstagramNote]> { continuation in
            notesCont = continuation
        }

        self.conversationsContinuation = conversationsCont
        self.notesContinuation = notesCont

        // Setup Firestore settings in a nonisolated context
        let settings = db.settings
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited))
        db.settings = settings
    }

    // MARK: - Session Management

    private func updateCurrentUserId() async {
        currentUserId = await SessionStore.shared.currentUserId
    }

    // MARK: - Public Interface - Conversations

    func fetchConversations(page: Int, perPage: Int) async throws -> [Conversation] {
        await updateCurrentUserId()

        if page == 1 {
            // Start real-time listener on first page load
            try await startConversationsListener()
            // Return cached data immediately
            return Array(cachedConversations.prefix(perPage))
        }

        // For pagination, fetch from cache or paginated query
        let startAfterIndex = (page - 1) * perPage
        let startAfter = startAfterIndex < cachedConversations.count ? cachedConversations[startAfterIndex] : nil
        let query = buildConversationsQuery(perPage: perPage, startAfter: startAfter)

        let snapshot = try await query.getDocuments()
        let conversations = try snapshot.documents.compactMap { try Self.mapConversation($0) }
        return conversations
    }

    private func startConversationsListener() async throws {
        // Remove existing listener
        conversationListener?.remove()

        let query = db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .order(by: "updatedAt", descending: true)
            .limit(to: 50)

        conversationListener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("Conversations listener error: \(error)")
                return
            }

            guard let snapshot = snapshot else { return }

            let conversations = snapshot.documents.compactMap { (doc: QueryDocumentSnapshot) -> Conversation? in
                try? Self.mapConversation(doc)
            }

            Task { [weak self] in
                await self?.updateCachedConversations(conversations)
            }
        }
    }

    private func updateCachedConversations(_ conversations: [Conversation]) async {
        self.cachedConversations = conversations
        self.conversationsContinuation?.yield(conversations)
    }

    private func buildConversationsQuery(perPage: Int, startAfter: Conversation?) -> Query {
        var query = db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .order(by: "updatedAt", descending: true)
            .limit(to: perPage)

        if let startAfter = startAfter {
            query = query.start(after: [startAfter.updatedAt])
        }

        return query
    }

    // Non-isolated mapping function for use in snapshot listeners
    nonisolated static func mapConversation(_ document: QueryDocumentSnapshot) throws -> Conversation {
        let data = document.data()

        let id = document.documentID
        let participantsData = data["participants"] as? [[String: Any]] ?? []
        let participants = participantsData.compactMap { mapUser($0) }
        let lastMessageData = data["lastMessage"] as? [String: Any]
        let lastMessage = lastMessageData.flatMap { try? mapMessageFromDict($0, conversationId: id) }
        let unreadCount = data["unreadCount"] as? Int ?? 0
        let isGroup = data["isGroup"] as? Bool ?? false
        let groupName = data["groupName"] as? String
        let groupAvatarURLString = data["groupAvatarURL"] as? String
        let groupAvatarURL = groupAvatarURLString.flatMap { URL(string: $0) }
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
        let isMuted = data["isMuted"] as? Bool ?? false

        return Conversation(
            id: id,
            participants: participants,
            lastMessage: lastMessage,
            unreadCount: unreadCount,
            isGroup: isGroup,
            groupName: groupName,
            groupAvatarURL: groupAvatarURL,
            updatedAt: updatedAt,
            isMuted: isMuted
        )
    }

    // Non-isolated mapping function for embedded message dictionaries (e.g., lastMessage in conversation)
    nonisolated static func mapMessageFromDict(_ data: [String: Any], conversationId: String) throws -> Message {
        let id = data["id"] as? String ?? UUID().uuidString
        let senderData = data["sender"] as? [String: Any] ?? [:]
        let sender = mapUser(senderData) ?? placeholderUser(id: "unknown")
        let contentData = data["content"] as? [String: Any] ?? [:]
        let content = try mapMessageContent(contentData)
        let statusRaw = data["status"] as? String ?? "sent"
        let status = MessageStatus(rawValue: statusRaw) ?? .sent
        let replyToId = data["replyToId"] as? String
        let replyToSnippet = data["replyToSnippet"] as? String
        let reactionsData = data["reactions"] as? [String: String] ?? [:]
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        return Message(
            id: id,
            conversationId: conversationId,
            sender: sender,
            content: content,
            status: status,
            replyToId: replyToId,
            replyToSnippet: replyToSnippet,
            reactions: reactionsData,
            createdAt: createdAt
        )
    }

    // MARK: - Public Interface - Messages

    func fetchMessages(conversationId: String, page: Int, perPage: Int) async throws -> [Message] {
        if page == 1 {
            // Start real-time listener on first page load
            try await startMessagesListener(conversationId: conversationId)
            return Array((cachedMessages[conversationId] ?? []).prefix(perPage))
        }

        let messages = cachedMessages[conversationId] ?? []
        let startAfterIndex = (page - 1) * perPage
        let startAfter = startAfterIndex < messages.count ? messages[startAfterIndex] : nil
        let query = buildMessagesQuery(conversationId: conversationId, perPage: perPage, startAfter: startAfter)

        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { try Self.mapMessage($0, conversationId: conversationId) }
    }

    private func startMessagesListener(conversationId: String) async throws {
        messageListeners[conversationId]?.remove()

        let query = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .limit(to: 50)

        messageListeners[conversationId] = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("Messages listener error for \(conversationId): \(error)")
                return
            }

            guard let snapshot = snapshot else { return }

            let messages = snapshot.documents.compactMap { (doc: QueryDocumentSnapshot) -> Message? in
                try? Self.mapMessage(doc, conversationId: conversationId)
            }

            Task { [weak self] in
                await self?.updateCachedMessages(conversationId: conversationId, messages: messages)
            }
        }
    }

    private func updateCachedMessages(conversationId: String, messages: [Message]) async {
        self.cachedMessages[conversationId] = messages
    }

    private func buildMessagesQuery(conversationId: String, perPage: Int, startAfter: Message?) -> Query {
        var query = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .limit(to: perPage)

        if let startAfter = startAfter {
            query = query.start(after: [startAfter.createdAt])
        }

        return query
    }

    // Non-isolated mapping function for use in snapshot listeners
    nonisolated static func mapMessage(_ document: QueryDocumentSnapshot, conversationId: String) throws -> Message {
        let data = document.data()

        let id = document.documentID
        let senderData = data["sender"] as? [String: Any] ?? [:]
        let sender = mapUser(senderData) ?? placeholderUser(id: "unknown")
        let contentData = data["content"] as? [String: Any] ?? [:]
        let content = try mapMessageContent(contentData)
        let statusRaw = data["status"] as? String ?? "sent"
        let status = MessageStatus(rawValue: statusRaw) ?? .sent
        let replyToId = data["replyToId"] as? String
        let replyToSnippet = data["replyToSnippet"] as? String
        let reactionsData = data["reactions"] as? [String: String] ?? [:]
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        return Message(
            id: id,
            conversationId: conversationId,
            sender: sender,
            content: content,
            status: status,
            replyToId: replyToId,
            replyToSnippet: replyToSnippet,
            reactions: reactionsData,
            createdAt: createdAt
        )
    }

    nonisolated static func mapMessageContent(_ data: [String: Any]) throws -> MessageContent {
        let type = data["type"] as? String ?? "text"

        switch type {
        case "text":
            let text = data["text"] as? String ?? ""
            return .text(text)
        case "image":
            let urlString = data["url"] as? String ?? ""
            guard let url = URL(string: urlString) else { throw MappingError.invalidURL }
            return .image(url)
        case "video":
            let urlString = data["url"] as? String ?? ""
            let thumbnailString = data["thumbnailURL"] as? String
            guard let url = URL(string: urlString) else { throw MappingError.invalidURL }
            let thumbnailURL = thumbnailString.flatMap { URL(string: $0) }
            return .video(url, thumbnailURL: thumbnailURL)
        case "audio":
            let urlString = data["url"] as? String ?? ""
            let duration = data["duration"] as? TimeInterval ?? 0
            guard let url = URL(string: urlString) else { throw MappingError.invalidURL }
            return .audio(url, duration: duration)
        case "post":
            let postId = data["postId"] as? String ?? ""
            return .post(postId: postId)
        case "story":
            let storyId = data["storyId"] as? String ?? ""
            return .story(storyId: storyId)
        case "reel":
            let reelId = data["reelId"] as? String ?? ""
            return .reel(reelId: reelId)
        case "like":
            return .like
        default:
            return .text(data["text"] as? String ?? "")
        }
    }

    nonisolated static func mapUser(_ data: [String: Any]) -> User? {
        guard let id = data["id"] as? String,
              let username = data["username"] as? String,
              let fullName = data["fullName"] as? String else {
            return nil
        }

        return User(
            id: id,
            username: username,
            fullName: fullName,
            email: data["email"] as? String,
            phone: data["phone"] as? String,
            avatarURL: (data["avatarURL"] as? String).flatMap { URL(string: $0) },
            bio: data["bio"] as? String,
            website: data["website"] as? String,
            isVerified: data["isVerified"] as? Bool ?? false,
            isPrivate: data["isPrivate"] as? Bool ?? false,
            followersCount: data["followersCount"] as? Int ?? 0,
            followingCount: data["followingCount"] as? Int ?? 0,
            postsCount: data["postsCount"] as? Int ?? 0,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            isFollowing: data["isFollowing"] as? Bool ?? false,
            isFollowedBy: data["isFollowedBy"] as? Bool ?? false,
            isBlocked: data["isBlocked"] as? Bool ?? false
        )
    }

    // Non-isolated placeholder user
    nonisolated static func placeholderUser(id: String) -> User {
        User(
            id: id,
            username: "user",
            fullName: "User",
            email: nil,
            phone: nil,
            avatarURL: nil,
            bio: nil,
            website: nil,
            isVerified: false,
            isPrivate: false,
            followersCount: 0,
            followingCount: 0,
            postsCount: 0,
            createdAt: .now,
            isFollowing: false,
            isFollowedBy: false,
            isBlocked: false
        )
    }

    // MARK: - Public Interface - Write Operations

    func sendMessage(conversationId: String, content: MessageContent) async throws -> Message {
        await updateCurrentUserId()

        let messageRef = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document()

        let messageId = messageRef.documentID
        let now = Date()

        let messageData: [String: Any] = try buildMessageData(
            id: messageId,
            conversationId: conversationId,
            senderId: currentUserId,
            content: content,
            status: .sending,
            createdAt: now
        )

        try await messageRef.setData(messageData)

        // Update conversation lastMessage and updatedAt
        try await db.collection("conversations").document(conversationId).updateData([
            "lastMessage": messageData["content"] as Any,
            "updatedAt": Timestamp(date: now),
            "unreadCount": FieldValue.increment(Int64(1))
        ])

        // Return optimistic message
        let sender = Self.placeholderUser(id: currentUserId)
        return Message(
            id: messageId,
            conversationId: conversationId,
            sender: sender,
            content: content,
            status: .sending,
            replyToId: nil,
            replyToSnippet: nil,
            reactions: [:],
            createdAt: now
        )
    }

    private func buildMessageData(
        id: String,
        conversationId: String,
        senderId: String,
        content: MessageContent,
        status: MessageStatus,
        createdAt: Date
    ) throws -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "conversationId": conversationId,
            "sender": ["id": senderId],
            "status": status.rawValue,
            "createdAt": Timestamp(date: createdAt)
        ]

        switch content {
        case .text(let text):
            data["content"] = ["type": "text", "text": text]
        case .image(let url):
            data["content"] = ["type": "image", "url": url.absoluteString]
        case .video(let url, let thumbnailURL):
            var contentData: [String: Any] = ["type": "video", "url": url.absoluteString]
            if let thumbnail = thumbnailURL { contentData["thumbnailURL"] = thumbnail.absoluteString }
            data["content"] = contentData
        case .audio(let url, let duration):
            data["content"] = ["type": "audio", "url": url.absoluteString, "duration": duration]
        case .post(let postId):
            data["content"] = ["type": "post", "postId": postId]
        case .story(let storyId):
            data["content"] = ["type": "story", "storyId": storyId]
        case .reel(let reelId):
            data["content"] = ["type": "reel", "reelId": reelId]
        case .like:
            data["content"] = ["type": "like"]
        }

        return data
    }

    func createConversation(participantIds: [String]) async throws -> Conversation {
        await updateCurrentUserId()

        var allParticipants = participantIds
        if !allParticipants.contains(currentUserId) {
            allParticipants.append(currentUserId)
        }

        let conversationRef = db.collection("conversations").document()
        let conversationId = conversationRef.documentID
        let now = Date()

        // Fetch participant user data
        let participants = try await fetchParticipants(ids: allParticipants)

        var conversationData: [String: Any] = [
            "id": conversationId,
            "participants": participants.map { Self.userToDict($0) },
            "isGroup": allParticipants.count > 2,
            "updatedAt": Timestamp(date: now),
            "unreadCount": 0,
            "isMuted": false,
            "createdAt": Timestamp(date: now),
            "createdBy": currentUserId
        ]

        // Only add groupName and groupAvatarURL if it's a group
        if allParticipants.count > 2 {
            conversationData["groupName"] = NSNull()
            conversationData["groupAvatarURL"] = NSNull()
        }

        try await conversationRef.setData(conversationData)

        return Conversation(
            id: conversationId,
            participants: participants,
            lastMessage: nil,
            unreadCount: 0,
            isGroup: allParticipants.count > 2,
            groupName: nil,
            groupAvatarURL: nil,
            updatedAt: now,
            isMuted: false
        )
    }

    private func fetchParticipants(ids: [String]) async throws -> [User] {
        let snapshot = try await db.collection("users")
            .whereField(FieldPath.documentID(), in: ids)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            var data = doc.data()
            data["id"] = doc.documentID
            return Self.mapUser(data)
        }
    }

    nonisolated static func userToDict(_ user: User) -> [String: Any] {
        var dict: [String: Any] = [
            "id": user.id,
            "username": user.username,
            "fullName": user.fullName
        ]
        if let email = user.email { dict["email"] = email }
        if let phone = user.phone { dict["phone"] = phone }
        if let avatarURL = user.avatarURL { dict["avatarURL"] = avatarURL.absoluteString }
        if let bio = user.bio { dict["bio"] = bio }
        if let website = user.website { dict["website"] = website }
        dict["isVerified"] = user.isVerified
        dict["isPrivate"] = user.isPrivate
        dict["followersCount"] = user.followersCount
        dict["followingCount"] = user.followingCount
        dict["postsCount"] = user.postsCount
        dict["createdAt"] = Timestamp(date: user.createdAt)
        dict["isFollowing"] = user.isFollowing
        dict["isFollowedBy"] = user.isFollowedBy
        dict["isBlocked"] = user.isBlocked
        return dict
    }

    func markAsRead(conversationId: String) async throws {
        await updateCurrentUserId()

        // Update unread count in conversation
        try await db.collection("conversations").document(conversationId).updateData([
            "unreadCount": 0,
            "lastReadBy.\(currentUserId)": Timestamp(date: Date())
        ])

        // Update message statuses locally
        if var messages = cachedMessages[conversationId] {
            messages = messages.map { msg in
                if msg.sender.id != currentUserId && msg.status != .read {
                    return Message(
                        id: msg.id,
                        conversationId: msg.conversationId,
                        sender: msg.sender,
                        content: msg.content,
                        status: .read,
                        replyToId: msg.replyToId,
                        replyToSnippet: msg.replyToSnippet,
                        reactions: msg.reactions,
                        createdAt: msg.createdAt
                    )
                }
                return msg
            }
            cachedMessages[conversationId] = messages
        }
    }

    func markAsUnread(conversationId: String) async throws {
        // Mark conversation as unread by setting unreadCount to 1
        try await db.collection("conversations").document(conversationId).updateData([
            "unreadCount": 1
        ])
    }

    func getUnreadConversationsCount() async throws -> Int {
        await updateCurrentUserId()

        let snapshot = try await db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .whereField("unreadCount", isGreaterThan: 0)
            .getDocuments()

        return snapshot.documents.count
    }

    func deleteMessage(id: String) async throws {
        // Find which conversation this message belongs to
        for (convId, messages) in cachedMessages {
            if messages.contains(where: { $0.id == id }) {
                try await db.collection("conversations")
                    .document(convId)
                    .collection("messages")
                    .document(id)
                    .delete()
                return
            }
        }
    }

    func muteConversation(id: String, mute: Bool) async throws {
        try await db.collection("conversations").document(id).updateData([
            "isMuted": mute
        ])

        // Update local cache
        if let index = cachedConversations.firstIndex(where: { $0.id == id }) {
            let conv = cachedConversations[index]
            cachedConversations[index] = Conversation(
                id: conv.id,
                participants: conv.participants,
                lastMessage: conv.lastMessage,
                unreadCount: conv.unreadCount,
                isGroup: conv.isGroup,
                groupName: conv.groupName,
                groupAvatarURL: conv.groupAvatarURL,
                updatedAt: conv.updatedAt,
                isMuted: mute
            )
        }
    }

    func deleteConversation(id: String) async throws {
        // Delete all messages first
        let messagesSnapshot = try await db.collection("conversations")
            .document(id)
            .collection("messages")
            .getDocuments()

        let batch = db.batch()
        for doc in messagesSnapshot.documents {
            batch.deleteDocument(doc.reference)
        }

        // Delete conversation
        batch.deleteDocument(db.collection("conversations").document(id))

        try await batch.commit()

        // Update local cache
        cachedConversations.removeAll { $0.id == id }
        cachedMessages.removeValue(forKey: id)
    }

    func addReaction(messageId: String, emoji: String) async throws {
        await updateCurrentUserId()

        // Find conversation containing this message
        for (convId, messages) in cachedMessages {
            if let msgIndex = messages.firstIndex(where: { $0.id == messageId }) {
                let message = messages[msgIndex]
                var reactions = message.reactions
                reactions[currentUserId] = emoji

                // Update in Firestore
                try await db.collection("conversations")
                    .document(convId)
                    .collection("messages")
                    .document(messageId)
                    .updateData(["reactions": reactions])

                // Update local cache
                var updatedMessages = messages
                updatedMessages[msgIndex] = Message(
                    id: message.id,
                    conversationId: message.conversationId,
                    sender: message.sender,
                    content: message.content,
                    status: message.status,
                    replyToId: message.replyToId,
                    replyToSnippet: message.replyToSnippet,
                    reactions: reactions,
                    createdAt: message.createdAt
                )
                cachedMessages[convId] = updatedMessages
                return
            }
        }
    }

    // MARK: - Notes

    func fetchNotes() async throws -> [InstagramNote] {
        await updateCurrentUserId()
        let currentUserId = self.currentUserId

        let snapshot = try await db.collection("notes")
            .whereField("userId", in: [currentUserId])
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
            .getDocuments()

        let notes = snapshot.documents.compactMap { Self.mapNote($0, currentUserId: currentUserId) }
        cachedNotes = notes
        notesContinuation?.yield(notes)
        return notes
    }

    func saveNote(text: String) async throws -> InstagramNote {
        await updateCurrentUserId()

        let noteRef = db.collection("notes").document()
        let noteId = noteRef.documentID
        let now = Date()

        let user = Self.placeholderUser(id: currentUserId)

        let noteData: [String: Any] = [
            "id": noteId,
            "userId": currentUserId,
            "user": Self.userToDict(user),
            "text": text,
            "createdAt": Timestamp(date: now)
        ]

        try await noteRef.setData(noteData)

        let note = InstagramNote(
            id: noteId,
            user: user,
            text: text,
            createdAt: now,
            isCurrentUser: true
        )

        cachedNotes.insert(note, at: 0)
        notesContinuation?.yield(cachedNotes)

        return note
    }

    nonisolated static func mapNote(_ document: QueryDocumentSnapshot, currentUserId: String) -> InstagramNote? {
        let data = document.data()

        guard let userId = data["userId"] as? String,
              let text = data["text"] as? String,
              let userData = data["user"] as? [String: Any],
              let user = mapUser(userData) else {
            return nil
        }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        return InstagramNote(
            id: document.documentID,
            user: user,
            text: text,
            createdAt: createdAt,
            isCurrentUser: userId == currentUserId
        )
    }

    // MARK: - Listener Management

    nonisolated func detachMessageListener(for conversationId: String) {
        Task { [weak self] in
            await self?.removeMessageListener(conversationId: conversationId)
        }
    }

    private func removeMessageListener(conversationId: String) {
        messageListeners[conversationId]?.remove()
        messageListeners.removeValue(forKey: conversationId)
    }

    nonisolated func resetSession() {
        Task { [weak self] in
            await self?.performResetSession()
        }
    }

    private func performResetSession() {
        conversationListener?.remove()
        conversationListener = nil

        for (_, listener) in messageListeners {
            listener.remove()
        }
        messageListeners.removeAll()

        notesListener?.remove()
        notesListener = nil

        cachedConversations.removeAll()
        cachedMessages.removeAll()
        cachedNotes.removeAll()
        currentUserId = ""
    }

    nonisolated func restartSession() async {
        await performResetSession()
        await updateCurrentUserId()
        try? await startConversationsListener()
    }

    // MARK: - Errors

    private enum MappingError: Error {
        case invalidURL
        case missingField(String)
    }
}

// MARK: - Safe Array Access (nonisolated)

extension Array {
    nonisolated subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}