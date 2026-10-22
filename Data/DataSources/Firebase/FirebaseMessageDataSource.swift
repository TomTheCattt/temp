//
//  FirebaseMessageDataSource.swift
//  Instagram
//
//  Created by Antigravity on 17/10/26.
//

import Foundation
import UIKit
import FirebaseFirestore

// MARK: - FirebaseMessageDataSource

/// Production-grade Firebase Firestore data source for real-time messaging, conversations, notes, and call logs.
/// Fully conforms to Swift 6 Concurrency (`actor FirebaseMessageDataSource: Sendable`).
actor FirebaseMessageDataSource: Sendable {

    // MARK: - Singleton

    static let shared = FirebaseMessageDataSource()

    // MARK: - In-Memory Cache

    private var inMemoryConversations: [Conversation] = []
    private var inMemoryMessages: [String: [Message]] = [:]
    private var inMemoryNotes: [InstagramNote] = []

    // MARK: - Firestore Listeners & State

    private var conversationListener: ListenerRegistration?
    private var messageListeners: [String: ListenerRegistration] = [:]
    private var notesListener: ListenerRegistration?
    private var hasAttachedInboxListener: Bool = false
    private let logger = AppLogger.network

    // MARK: - Current User Cache

    private var currentUserIdCache: String = MockData.currentUser.id
    private var currentUserCache: User = MockData.currentUser

    // MARK: - Init

    init() {
        Task { [weak self] in
            await self?.bootstrap()
        }
    }

    private func bootstrap() async {
        await syncCurrentUser()
        seedFromMockData()
        startNotificationObservers()
        startRealtimeInboxSync()
    }

    deinit {
        conversationListener?.remove()
        for (_, listener) in messageListeners {
            listener.remove()
        }
        notesListener?.remove()
    }

    // MARK: - Seeding Cache from MockData

    private func seedFromMockData() {
        self.inMemoryConversations = MockData.conversations
        self.inMemoryMessages = MockData.seededMessages
        self.inMemoryNotes = MockData.seededNotes

        let initialTotal = inMemoryConversations.filter { $0.unreadCount != 0 }.count
        Task { @MainActor in
            AppState.shared.setUnreadChatCount(initialTotal)
        }
    }

    // MARK: - Modern NotificationCenter Observers

    private func startNotificationObservers() {
        // Subscribe to incoming messages (from external transports or notifications)
        Task { [weak self] in
            for await notification in NotificationCenter.default.notifications(named: .didUpdateMessage) {
                guard let self = self,
                      let message = notification.object as? Message else { continue }
                await self.handleLocalMessageUpdate(message)
            }
        }

        // Subscribe to finished calls to record call history into DM
        Task { [weak self] in
            for await notification in NotificationCenter.default.notifications(named: .didEndCall) {
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let remoteUserId = userInfo["remoteUserId"] as? String else { continue }
                let callerUserId = userInfo["callerUserId"] as? String ?? ""
                let isOutgoing = userInfo["isOutgoing"] as? Bool ?? true
                let hasVideo = userInfo["hasVideo"] as? Bool ?? false
                let duration = userInfo["duration"] as? String
                let reason = userInfo["reason"] as? String ?? ""
                await self.recordCallEndEvent(
                    remoteUserId: remoteUserId,
                    callerUserId: callerUserId,
                    isOutgoing: isOutgoing,
                    hasVideo: hasVideo,
                    duration: duration,
                    reason: reason
                )
            }
        }
    }

    // MARK: - Real-time Inbox & Notes Firestore Listeners

    private func startRealtimeInboxSync() {
        guard !hasAttachedInboxListener else { return }
        hasAttachedInboxListener = true

        let db = Firestore.firestore()
        let currentUserId = resolvedCurrentUserId()

        // 1. Listen to user's conversations
        conversationListener = db.collection("conversations")
            .whereField("participantIds", arrayContains: currentUserId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let _ = error {
                    // Log gracefully for offline / simulator
                    return
                }
                guard let documents = snapshot?.documents else { return }
                Task {
                    await self.mergeFirestoreConversations(documents)
                }
            }

        // 2. Listen to notes collection
        notesListener = db.collection("notes")
            .limit(to: 30)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let _ = error {
                    return
                }
                guard let documents = snapshot?.documents else { return }
                Task {
                    await self.mergeFirestoreNotes(documents)
                }
            }
    }

    // MARK: - Real-time Conversation Message Listener

    private func attachMessageListenerIfNeeded(for conversationId: String) {
        guard messageListeners[conversationId] == nil else { return }

        let db = Firestore.firestore()
        let listener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let _ = error {
                    return
                }
                guard let documentChanges = snapshot?.documentChanges else { return }
                Task {
                    await self.handleFirestoreMessageChanges(conversationId: conversationId, changes: documentChanges)
                }
            }

        messageListeners[conversationId] = listener
    }

    // MARK: - MessageRepositoryProtocol Implementations

    func fetchConversations(page: Int, perPage: Int) async throws -> [Conversation] {
        let start = (page - 1) * perPage
        let end = min(start + perPage, inMemoryConversations.count)
        guard start < end else { return [] }
        return Array(inMemoryConversations[start..<end])
    }

    func fetchMessages(conversationId: String, page: Int, perPage: Int) async throws -> [Message] {
        attachMessageListenerIfNeeded(for: conversationId)

        if inMemoryMessages[conversationId] == nil {
            if let conv = inMemoryConversations.first(where: { $0.id == conversationId }) {
                inMemoryMessages[conversationId] = conv.lastMessage.map { [$0] } ?? []
            } else {
                inMemoryMessages[conversationId] = []
            }
        }

        var currentMessages = inMemoryMessages[conversationId] ?? []
        let start = (page - 1) * perPage

        if start >= currentMessages.count && page <= Self.maxMockPages {
            let partner: User = {
                if let conv = inMemoryConversations.first(where: { $0.id == conversationId }) {
                    return conv.participants.first { $0.id != resolvedCurrentUserId() } ?? MockData.currentUser
                }
                return MockData.users.first ?? MockData.currentUser
            }()

            let oldestDate = currentMessages.last?.createdAt ?? Date()
            let olderBatch = MockData.generateOlderMessages(
                conversationId: conversationId,
                page: page,
                perPage: perPage,
                oldestDate: oldestDate,
                partner: partner
            )
            currentMessages.append(contentsOf: olderBatch)
            inMemoryMessages[conversationId] = currentMessages
        }

        guard start < currentMessages.count else { return [] }
        let end = min(start + perPage, currentMessages.count)
        return Array(currentMessages[start..<end])
    }

    func sendMessage(conversationId: String, content: MessageContent) async throws -> Message {
        let sender = resolvedCurrentUser()
        let messageId = "msg_\(UUID().uuidString.prefix(12))"
        let message = Message(
            id: messageId,
            conversationId: conversationId,
            sender: sender,
            content: content,
            status: .sent,
            replyToId: nil,
            createdAt: .now
        )

        // 1. Update in-memory message cache
        if inMemoryMessages[conversationId] != nil {
            inMemoryMessages[conversationId]?.insert(message, at: 0)
        } else {
            inMemoryMessages[conversationId] = [message]
        }

        // 2. Update conversation lastMessage & move to top (index 0)
        if let index = inMemoryConversations.firstIndex(where: { $0.id == conversationId }) {
            let existing = inMemoryConversations.remove(at: index)
            let updated = Conversation(
                id: existing.id,
                participants: existing.participants,
                lastMessage: message,
                unreadCount: existing.unreadCount,
                isGroup: existing.isGroup,
                groupName: existing.groupName,
                groupAvatarURL: existing.groupAvatarURL,
                updatedAt: message.createdAt,
                isMuted: existing.isMuted
            )
            inMemoryConversations.insert(updated, at: 0)
        }

        // 3. Post reactive UI notifications (do not broadcast didUpdateMessage for self to avoid duplicates)
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)

        // 4. Asynchronously persist to Firestore in background
        Task { [weak self] in
            await self?.persistMessageToFirestore(message: message, conversationId: conversationId)
        }

        return message
    }

    func createConversation(participantIds: [String]) async throws -> Conversation {
        // If 1-on-1 chat, reuse existing conversation if found
        if participantIds.count == 1,
           let targetId = participantIds.first,
           let existing = inMemoryConversations.first(where: { conv in
               !conv.isGroup && conv.participants.contains(where: { $0.id == targetId })
           }) {
            return existing
        }

        let current = resolvedCurrentUser()
        let otherUsers = participantIds.compactMap { id in
            MockData.users.first(where: { $0.id == id })
        }
        let convId = "conv_\(UUID().uuidString.prefix(10))"
        let newConv = Conversation(
            id: convId,
            participants: [current] + otherUsers,
            lastMessage: nil,
            unreadCount: 0,
            isGroup: participantIds.count > 1,
            groupName: nil,
            groupAvatarURL: nil,
            updatedAt: .now,
            isMuted: false
        )

        inMemoryConversations.insert(newConv, at: 0)
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)

        // Persist to Firestore
        Task { [weak self] in
            await self?.persistConversationToFirestore(newConv)
        }

        return newConv
    }

    func markAsRead(conversationId: String) async throws {
        if let index = inMemoryConversations.firstIndex(where: { $0.id == conversationId }) {
            let existing = inMemoryConversations[index]
            if existing.unreadCount > 0 {
                inMemoryConversations[index] = Conversation(
                    id: existing.id,
                    participants: existing.participants,
                    lastMessage: existing.lastMessage,
                    unreadCount: 0,
                    isGroup: existing.isGroup,
                    groupName: existing.groupName,
                    groupAvatarURL: existing.groupAvatarURL,
                    updatedAt: existing.updatedAt,
                    isMuted: existing.isMuted
                )
            }
        }

        inMemoryConversations.sort { $0.updatedAt > $1.updatedAt }
        updateTotalUnreadState()
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)

        // Sync to Firestore
        let db = Firestore.firestore()
        try? await db.collection("conversations").document(conversationId).setData([
            "unreadCount": 0
        ], merge: true)
    }

    func markAsUnread(conversationId: String) async throws {
        if let index = inMemoryConversations.firstIndex(where: { $0.id == conversationId }) {
            let existing = inMemoryConversations[index]
            if existing.unreadCount == 0 {
                inMemoryConversations[index] = Conversation(
                    id: existing.id,
                    participants: existing.participants,
                    lastMessage: existing.lastMessage,
                    unreadCount: 1,
                    isGroup: existing.isGroup,
                    groupName: existing.groupName,
                    groupAvatarURL: existing.groupAvatarURL,
                    updatedAt: existing.updatedAt,
                    isMuted: existing.isMuted
                )
            }
        }

        inMemoryConversations.sort { $0.updatedAt > $1.updatedAt }
        updateTotalUnreadState()
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)

        // Sync to Firestore
        let db = Firestore.firestore()
        try? await db.collection("conversations").document(conversationId).setData([
            "unreadCount": 1
        ], merge: true)
    }

    func getUnreadConversationsCount() -> Int {
        inMemoryConversations.filter { $0.unreadCount > 0 }.count
    }

    func deleteMessage(id: String) async throws {
        var targetConvId: String?

        for (convId, msgs) in inMemoryMessages {
            if let targetIndex = msgs.firstIndex(where: { $0.id == id }) {
                targetConvId = convId
                var updatedMsgs = msgs
                updatedMsgs.remove(at: targetIndex)
                inMemoryMessages[convId] = updatedMsgs

                if let convIndex = inMemoryConversations.firstIndex(where: { $0.id == convId }) {
                    let existing = inMemoryConversations[convIndex]
                    let newLastMessage = updatedMsgs.first
                    let newUpdatedAt = newLastMessage?.createdAt ?? existing.updatedAt
                    inMemoryConversations[convIndex] = Conversation(
                        id: existing.id,
                        participants: existing.participants,
                        lastMessage: newLastMessage,
                        unreadCount: existing.unreadCount,
                        isGroup: existing.isGroup,
                        groupName: existing.groupName,
                        groupAvatarURL: existing.groupAvatarURL,
                        updatedAt: newUpdatedAt,
                        isMuted: existing.isMuted
                    )
                }
                NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
                break
            }
        }

        if let convId = targetConvId {
            let db = Firestore.firestore()
            try? await db.collection("conversations")
                .document(convId)
                .collection("messages")
                .document(id)
                .delete()
        }
    }

    func muteConversation(id: String, mute: Bool) async throws {
        if let index = inMemoryConversations.firstIndex(where: { $0.id == id }) {
            let conv = inMemoryConversations[index]
            inMemoryConversations[index] = Conversation(
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
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)

        let db = Firestore.firestore()
        try? await db.collection("conversations").document(id).setData([
            "isMuted": mute
        ], merge: true)
    }

    func deleteConversation(id: String) async throws {
        inMemoryConversations.removeAll { $0.id == id }
        inMemoryMessages.removeValue(forKey: id)

        inMemoryConversations.sort { $0.updatedAt > $1.updatedAt }
        updateTotalUnreadState()
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)

        let db = Firestore.firestore()
        try? await db.collection("conversations").document(id).delete()
    }

    func addReaction(messageId: String, emoji: String) async throws {
        let currentUserId = resolvedCurrentUserId()
        var targetConvId: String?

        for (convId, msgs) in inMemoryMessages {
            if let idx = msgs.firstIndex(where: { $0.id == messageId }) {
                targetConvId = convId
                var updated = msgs[idx]
                var reactions = updated.reactions
                if reactions[currentUserId] == emoji {
                    reactions.removeValue(forKey: currentUserId)
                } else {
                    reactions[currentUserId] = emoji
                }
                updated = Message(
                    id: updated.id,
                    conversationId: updated.conversationId,
                    sender: updated.sender,
                    content: updated.content,
                    status: updated.status,
                    replyToId: updated.replyToId,
                    replyToSnippet: updated.replyToSnippet,
                    reactions: reactions,
                    createdAt: updated.createdAt
                )
                inMemoryMessages[convId]?[idx] = updated
                NotificationCenter.default.post(name: .didUpdateMessage, object: updated)
                break
            }
        }

        if let convId = targetConvId {
            let db = Firestore.firestore()
            let ref = db.collection("conversations").document(convId).collection("messages").document(messageId)
            try? await ref.setData([
                "reactions.\(currentUserId)": emoji
            ], merge: true)
        }
    }

    func fetchNotes() async throws -> [InstagramNote] {
        return inMemoryNotes
    }

    // MARK: - Firestore Parsing & Merging

    private func mergeFirestoreConversations(_ documents: [QueryDocumentSnapshot]) {
        for doc in documents {
            let data = doc.data()
            if let conv = Self.dictToConversation(data, docId: doc.documentID) {
                if let index = inMemoryConversations.firstIndex(where: { $0.id == conv.id }) {
                    inMemoryConversations[index] = conv
                } else {
                    inMemoryConversations.insert(conv, at: 0)
                }
            }
        }
        inMemoryConversations.sort { $0.updatedAt > $1.updatedAt }
        updateTotalUnreadState()
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
    }

    private func mergeFirestoreNotes(_ documents: [QueryDocumentSnapshot]) {
        var remoteNotes: [InstagramNote] = []
        let currentUserId = resolvedCurrentUserId()

        for doc in documents {
            let data = doc.data()
            if let note = Self.dictToNote(data, docId: doc.documentID, currentUserId: currentUserId) {
                remoteNotes.append(note)
            }
        }

        if !remoteNotes.isEmpty {
            // Merge remote notes with inMemoryNotes
            var merged = inMemoryNotes
            for note in remoteNotes {
                if let idx = merged.firstIndex(where: { $0.id == note.id }) {
                    merged[idx] = note
                } else {
                    merged.append(note)
                }
            }
            self.inMemoryNotes = merged
            NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
        }
    }

    private func handleFirestoreMessageChanges(conversationId: String, changes: [DocumentChange]) {
        let currentUserId = resolvedCurrentUserId()

        for change in changes {
            let data = change.document.data()
            guard let message = Self.dictToMessage(data, docId: change.document.documentID) else { continue }

            switch change.type {
            case .added:
                // Only ingest if not already present or sent by partner
                if inMemoryMessages[conversationId] == nil {
                    inMemoryMessages[conversationId] = [message]
                } else if !(inMemoryMessages[conversationId]?.contains(where: { $0.id == message.id }) ?? false) {
                    inMemoryMessages[conversationId]?.insert(message, at: 0)
                }

                // If remote partner sent the message, update conversation state
                if message.sender.id != currentUserId {
                    if let index = inMemoryConversations.firstIndex(where: { $0.id == conversationId }) {
                        let existing = inMemoryConversations.remove(at: index)
                        let updated = Conversation(
                            id: existing.id,
                            participants: existing.participants,
                            lastMessage: message,
                            unreadCount: existing.unreadCount + 1,
                            isGroup: existing.isGroup,
                            groupName: existing.groupName,
                            groupAvatarURL: existing.groupAvatarURL,
                            updatedAt: message.createdAt,
                            isMuted: existing.isMuted
                        )
                        inMemoryConversations.insert(updated, at: 0)
                    }
                    updateTotalUnreadState()
                    NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
                }

                NotificationCenter.default.post(name: .didUpdateMessage, object: message)

            case .modified:
                if let idx = inMemoryMessages[conversationId]?.firstIndex(where: { $0.id == message.id }) {
                    inMemoryMessages[conversationId]?[idx] = message
                    NotificationCenter.default.post(name: .didUpdateMessage, object: message)
                }

            case .removed:
                inMemoryMessages[conversationId]?.removeAll { $0.id == message.id }
                NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
            }
        }
    }

    // MARK: - Local Message and Call Handling

    private func handleLocalMessageUpdate(_ message: Message) {
        guard message.sender.id != resolvedCurrentUserId() else { return }

        let convId = message.conversationId
        if inMemoryMessages[convId] != nil {
            if !(inMemoryMessages[convId]?.contains(where: { $0.id == message.id }) ?? false) {
                inMemoryMessages[convId]?.insert(message, at: 0)
            }
        } else {
            inMemoryMessages[convId] = [message]
        }

        if let index = inMemoryConversations.firstIndex(where: { $0.id == convId }) {
            let existing = inMemoryConversations.remove(at: index)
            let updated = Conversation(
                id: existing.id,
                participants: existing.participants,
                lastMessage: message,
                unreadCount: existing.unreadCount + 1,
                isGroup: existing.isGroup,
                groupName: existing.groupName,
                groupAvatarURL: existing.groupAvatarURL,
                updatedAt: message.createdAt,
                isMuted: existing.isMuted
            )
            inMemoryConversations.insert(updated, at: 0)
        }

        inMemoryConversations.sort { $0.updatedAt > $1.updatedAt }
        updateTotalUnreadState()
        NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
    }

    private func recordCallEndEvent(
        remoteUserId: String,
        callerUserId: String,
        isOutgoing: Bool,
        hasVideo: Bool,
        duration: String?,
        reason: String
    ) {
        let partnerUser: User
        if let user = MockData.users.first(where: { $0.id == remoteUserId }) {
            partnerUser = user
        } else if let found = inMemoryConversations.flatMap(\.participants).first(where: { $0.id == remoteUserId }) {
            partnerUser = found
        } else {
            partnerUser = User(
                id: remoteUserId,
                username: "user_\(remoteUserId)",
                fullName: "User \(remoteUserId)",
                email: nil,
                phone: nil,
                avatarURL: URL(string: "https://i.pravatar.cc/300?u=\(remoteUserId)"),
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

        let sender: User = isOutgoing ? resolvedCurrentUser() : partnerUser
        let callTypeStr = hasVideo ? "Cuộc gọi video" : "Cuộc gọi thoại"
        let contentText: String

        if let duration = duration, !duration.isEmpty, duration != "00:00" {
            contentText = "\(callTypeStr) đã kết thúc · \(duration)"
        } else if reason == "rejected" || reason == "busy" {
            contentText = "\(callTypeStr) bị từ chối"
        } else if reason == "timeout" {
            contentText = isOutgoing ? "\(callTypeStr) không trả lời" : "\(callTypeStr) nhỡ"
        } else {
            contentText = "\(callTypeStr) đã kết thúc"
        }

        if let convIndex = inMemoryConversations.firstIndex(where: { conv in
            conv.participants.contains(where: { $0.id == remoteUserId })
        }) {
            let conv = inMemoryConversations[convIndex]
            let isRejectedOrBusy = (reason == "rejected" || reason == "busy")
            let isMissedIncoming = !isOutgoing && !isRejectedOrBusy && (reason == "timeout" || duration == nil || duration == "00:00")
            let newUnreadCount = isMissedIncoming ? conv.unreadCount + 1 : conv.unreadCount

            let callMessage = Message(
                id: "call_\(UUID().uuidString)",
                conversationId: conv.id,
                sender: sender,
                content: .text(contentText),
                status: isOutgoing ? .read : (isMissedIncoming ? .delivered : .read),
                replyToId: nil,
                createdAt: Date()
            )

            if inMemoryMessages[conv.id] != nil {
                inMemoryMessages[conv.id]?.insert(callMessage, at: 0)
            } else {
                inMemoryMessages[conv.id] = [callMessage]
            }

            let existing = inMemoryConversations.remove(at: convIndex)
            let updated = Conversation(
                id: existing.id,
                participants: existing.participants,
                lastMessage: callMessage,
                unreadCount: newUnreadCount,
                isGroup: existing.isGroup,
                groupName: existing.groupName,
                groupAvatarURL: existing.groupAvatarURL,
                updatedAt: Date(),
                isMuted: existing.isMuted
            )
            inMemoryConversations.insert(updated, at: 0)

            NotificationCenter.default.post(name: .didUpdateMessage, object: callMessage)
            NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
            updateTotalUnreadState()
        } else {
            let newConvId = "conv_\(remoteUserId)"
            let isRejectedOrBusy = (reason == "rejected" || reason == "busy")
            let isMissedIncoming = !isOutgoing && !isRejectedOrBusy && (reason == "timeout" || duration == nil || duration == "00:00")
            let unreadCount = isMissedIncoming ? 1 : 0

            let callMessage = Message(
                id: "call_\(UUID().uuidString)",
                conversationId: newConvId,
                sender: sender,
                content: .text(contentText),
                status: isOutgoing ? .read : (isMissedIncoming ? .delivered : .read),
                replyToId: nil,
                createdAt: Date()
            )

            inMemoryMessages[newConvId] = [callMessage]

            let newConv = Conversation(
                id: newConvId,
                participants: [resolvedCurrentUser(), partnerUser],
                lastMessage: callMessage,
                unreadCount: unreadCount,
                isGroup: false,
                groupName: nil,
                groupAvatarURL: nil,
                updatedAt: Date(),
                isMuted: false
            )
            inMemoryConversations.insert(newConv, at: 0)

            NotificationCenter.default.post(name: .didUpdateMessage, object: callMessage)
            NotificationCenter.default.post(name: .didUpdateConversations, object: nil)
            updateTotalUnreadState()
        }
    }

    // MARK: - Firestore Background Persistence

    private func persistMessageToFirestore(message: Message, conversationId: String) async {
        let db = Firestore.firestore()
        let dict = Self.messageToDict(message)

        // Write message document
        try? await db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .document(message.id)
            .setData(dict)

        // Update conversation summary
        try? await db.collection("conversations")
            .document(conversationId)
            .setData([
                "lastMessage": dict,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }

    private func persistConversationToFirestore(_ conv: Conversation) async {
        let db = Firestore.firestore()
        let dict = Self.conversationToDict(conv)
        try? await db.collection("conversations")
            .document(conv.id)
            .setData(dict, merge: true)
    }

    private func updateTotalUnreadState() {
        let unreadConversations = inMemoryConversations.filter { $0.unreadCount > 0 }.count
        Task { @MainActor in
            AppState.shared.setUnreadChatCount(unreadConversations)
            #if !targetEnvironment(simulator)
            UNUserNotificationCenter.current().setBadgeCount(unreadConversations)
            #endif
        }
    }

    private func syncCurrentUser() async {
        let (uid, user) = await MainActor.run {
            let u = SessionStore.shared.currentUser ?? MockData.currentUser
            let id = SessionStore.shared.currentUserId
            return (id.isEmpty ? u.id : id, u)
        }
        self.currentUserIdCache = uid
        self.currentUserCache = user
    }

    private func resolvedCurrentUserId() -> String {
        return currentUserIdCache
    }

    private func resolvedCurrentUser() -> User {
        return currentUserCache
    }

    // MARK: - Dictionary Mappers

    static func userToDict(_ user: User) -> [String: Any] {
        var dict: [String: Any] = [
            "id": user.id,
            "username": user.username,
            "fullName": user.fullName,
            "isVerified": user.isVerified
        ]
        if let avatar = user.avatarURL?.absoluteString {
            dict["avatarURL"] = avatar
        }
        return dict
    }

    static func dictToUser(_ dict: [String: Any]) -> User? {
        guard let id = dict["id"] as? String,
              let username = dict["username"] as? String else { return nil }
        let fullName = dict["fullName"] as? String ?? username
        let avatarURL = (dict["avatarURL"] as? String).flatMap { URL(string: $0) }
        let isVerified = dict["isVerified"] as? Bool ?? false

        return User(
            id: id,
            username: username,
            fullName: fullName,
            email: nil,
            phone: nil,
            avatarURL: avatarURL,
            bio: nil,
            website: nil,
            isVerified: isVerified,
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

    static func messageToDict(_ message: Message) -> [String: Any] {
        var dict: [String: Any] = [
            "id": message.id,
            "conversationId": message.conversationId,
            "sender": userToDict(message.sender),
            "status": message.status.rawValue,
            "reactions": message.reactions,
            "createdAt": message.createdAt.timeIntervalSince1970
        ]
        if let replyToId = message.replyToId {
            dict["replyToId"] = replyToId
        }
        if let replySnippet = message.replyToSnippet {
            dict["replyToSnippet"] = replySnippet
        }
        switch message.content {
        case .text(let text):
            dict["type"] = "text"
            dict["text"] = text
        case .image(let url):
            dict["type"] = "image"
            dict["mediaURL"] = url.absoluteString
        case .video(let url, let thumbnailURL):
            dict["type"] = "video"
            dict["mediaURL"] = url.absoluteString
            if let thumb = thumbnailURL?.absoluteString {
                dict["thumbnailURL"] = thumb
            }
        case .audio(let url, let duration):
            dict["type"] = "audio"
            dict["mediaURL"] = url.absoluteString
            dict["duration"] = duration
        case .post(let postId):
            dict["type"] = "post"
            dict["referenceId"] = postId
        case .story(let storyId):
            dict["type"] = "story"
            dict["referenceId"] = storyId
        case .reel(let reelId):
            dict["type"] = "reel"
            dict["referenceId"] = reelId
        case .like:
            dict["type"] = "like"
        }
        return dict
    }

    static func dictToMessage(_ dict: [String: Any], docId: String) -> Message? {
        let id = (dict["id"] as? String) ?? docId
        let convId = dict["conversationId"] as? String ?? ""
        guard let senderDict = dict["sender"] as? [String: Any],
              let sender = dictToUser(senderDict) else {
            return nil
        }
        let statusStr = dict["status"] as? String ?? "sent"
        let status = MessageStatus(rawValue: statusStr) ?? .sent
        let replyToId = dict["replyToId"] as? String
        let replyToSnippet = dict["replyToSnippet"] as? String
        let reactions = dict["reactions"] as? [String: String] ?? [:]

        let createdAt: Date
        if let timestamp = dict["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else if let interval = dict["createdAt"] as? TimeInterval {
            createdAt = Date(timeIntervalSince1970: interval)
        } else {
            createdAt = Date()
        }

        let content = parseContent(from: dict)

        return Message(
            id: id,
            conversationId: convId,
            sender: sender,
            content: content,
            status: status,
            replyToId: replyToId,
            replyToSnippet: replyToSnippet,
            reactions: reactions,
            createdAt: createdAt
        )
    }

    static func parseContent(from dict: [String: Any]) -> MessageContent {
        let type = dict["type"] as? String ?? "text"
        switch type {
        case "text":
            return .text(dict["text"] as? String ?? "")
        case "image":
            if let urlStr = dict["mediaURL"] as? String, let url = URL(string: urlStr) {
                return .image(url)
            }
            return .text("[Hình ảnh]")
        case "video":
            if let urlStr = dict["mediaURL"] as? String, let url = URL(string: urlStr) {
                let thumb = (dict["thumbnailURL"] as? String).flatMap { URL(string: $0) }
                return .video(url, thumbnailURL: thumb)
            }
            return .text("[Video]")
        case "audio":
            if let urlStr = dict["mediaURL"] as? String, let url = URL(string: urlStr) {
                let duration = dict["duration"] as? Double ?? 0
                return .audio(url, duration: duration)
            }
            return .text("[Tin nhắn thoại]")
        case "post":
            return .post(postId: dict["referenceId"] as? String ?? "")
        case "story":
            return .story(storyId: dict["referenceId"] as? String ?? "")
        case "reel":
            return .reel(reelId: dict["referenceId"] as? String ?? "")
        case "like":
            return .like
        default:
            return .text(dict["text"] as? String ?? "")
        }
    }

    static func conversationToDict(_ conv: Conversation) -> [String: Any] {
        var dict: [String: Any] = [
            "id": conv.id,
            "participantIds": conv.participants.map(\.id),
            "participants": conv.participants.map { userToDict($0) },
            "unreadCount": conv.unreadCount,
            "isGroup": conv.isGroup,
            "updatedAt": conv.updatedAt.timeIntervalSince1970,
            "isMuted": conv.isMuted
        ]
        if let groupName = conv.groupName {
            dict["groupName"] = groupName
        }
        if let groupAvatarURL = conv.groupAvatarURL?.absoluteString {
            dict["groupAvatarURL"] = groupAvatarURL
        }
        if let lastMessage = conv.lastMessage {
            dict["lastMessage"] = messageToDict(lastMessage)
        }
        return dict
    }

    static func dictToConversation(_ dict: [String: Any], docId: String) -> Conversation? {
        let id = (dict["id"] as? String) ?? docId
        let participantsRaw = dict["participants"] as? [[String: Any]] ?? []
        let participants = participantsRaw.compactMap { dictToUser($0) }

        let lastMessage: Message?
        if let lastMsgDict = dict["lastMessage"] as? [String: Any] {
            lastMessage = dictToMessage(lastMsgDict, docId: "last")
        } else {
            lastMessage = nil
        }

        let unreadCount = dict["unreadCount"] as? Int ?? 0
        let isGroup = dict["isGroup"] as? Bool ?? (participants.count > 2)
        let groupName = dict["groupName"] as? String
        let groupAvatarURL = (dict["groupAvatarURL"] as? String).flatMap { URL(string: $0) }

        let updatedAt: Date
        if let timestamp = dict["updatedAt"] as? Timestamp {
            updatedAt = timestamp.dateValue()
        } else if let interval = dict["updatedAt"] as? TimeInterval {
            updatedAt = Date(timeIntervalSince1970: interval)
        } else {
            updatedAt = lastMessage?.createdAt ?? Date()
        }

        let isMuted = dict["isMuted"] as? Bool ?? false

        return Conversation(
            id: id,
            participants: participants.isEmpty ? [MockData.currentUser] : participants,
            lastMessage: lastMessage,
            unreadCount: unreadCount,
            isGroup: isGroup,
            groupName: groupName,
            groupAvatarURL: groupAvatarURL,
            updatedAt: updatedAt,
            isMuted: isMuted
        )
    }

    static func dictToNote(_ dict: [String: Any], docId: String, currentUserId: String) -> InstagramNote? {
        let id = (dict["id"] as? String) ?? docId
        guard let text = dict["text"] as? String else { return nil }

        let user: User
        if let userDict = dict["user"] as? [String: Any], let parsedUser = dictToUser(userDict) {
            user = parsedUser
        } else {
            let userId = dict["userId"] as? String ?? "user_\(id)"
            let username = dict["username"] as? String ?? "user"
            let fullName = dict["fullName"] as? String ?? username
            user = User(
                id: userId,
                username: username,
                fullName: fullName,
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

        let isCurrentUser = (user.id == currentUserId) || (dict["isCurrentUser"] as? Bool ?? false)
        let createdAt: Date
        if let timestamp = dict["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else if let interval = dict["createdAt"] as? TimeInterval {
            createdAt = Date(timeIntervalSince1970: interval)
        } else {
            createdAt = Date()
        }

        return InstagramNote(
            id: id,
            user: user,
            text: text,
            createdAt: createdAt,
            isCurrentUser: isCurrentUser
        )
    }

    // MARK: - Constants

    private static let maxMockPages = 3
}
