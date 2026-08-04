//
//  MessageMapper.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - MessageMapper

enum MessageMapper {

    // MARK: - Conversation

    static func toConversation(_ dto: ConversationDTO, currentUserId: String) -> Conversation {
        let participants = dto.members.map { UserMapper.toEntity($0.user) }
        let lastMessage = dto.messages?.first.map { toMessage($0, members: dto.members) }

        // Determine if muted for current user
        let isMuted = dto.members.first(where: { $0.userId == currentUserId })?.isMuted ?? false

        // Calculate unread count: messages after lastReadAt for current user
        let currentMember = dto.members.first(where: { $0.userId == currentUserId })
        let unreadCount: Int
        if let lastReadAt = currentMember?.lastReadAt {
            let lastReadDate = DateMapper.toDate(lastReadAt)
            unreadCount = dto.messages?.filter {
                DateMapper.toDate($0.createdAt) > lastReadDate && $0.senderId != currentUserId
            }.count ?? 0
        } else {
            unreadCount = dto.messages?.filter { $0.senderId != currentUserId }.count ?? 0
        }

        return Conversation(
            id: dto.id,
            participants: participants,
            lastMessage: lastMessage,
            unreadCount: unreadCount,
            isGroup: dto.isGroup,
            groupName: dto.groupName,
            groupAvatarURL: dto.groupAvatar.flatMap { URL(string: $0) },
            updatedAt: DateMapper.toDate(dto.updatedAt),
            isMuted: isMuted
        )
    }

    static func toConversationList(_ dtos: [ConversationDTO], currentUserId: String) -> [Conversation] {
        dtos.map { toConversation($0, currentUserId: currentUserId) }
    }

    // MARK: - Message

    static func toMessage(_ dto: MessageDTO, members: [ConversationMemberDTO]? = nil) -> Message {
        // Resolve sender from dto.sender or from members list
        let sender: User
        if let senderDTO = dto.sender {
            sender = UserMapper.toEntity(senderDTO)
        } else if let member = members?.first(where: { $0.userId == dto.senderId }) {
            sender = UserMapper.toEntity(member.user)
        } else {
            sender = User(
                id: dto.senderId,
                username: "",
                fullName: "",
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

        return Message(
            id: dto.id,
            conversationId: dto.conversationId,
            sender: sender,
            content: toMessageContent(dto),
            status: toMessageStatus(dto.status),
            replyToId: dto.replyToId,
            createdAt: DateMapper.toDate(dto.createdAt)
        )
    }

    static func toMessageList(_ dtos: [MessageDTO]) -> [Message] {
        dtos.map { toMessage($0) }
    }

    // MARK: - Content

    private static func toMessageContent(_ dto: MessageDTO) -> MessageContent {
        let type = dto.contentType.uppercased()
        switch type {
        case "TEXT":
            return .text(dto.textContent ?? "")
        case "IMAGE":
            return .image(URL(string: dto.mediaUrl ?? "") ?? URL(string: "about:blank")!)
        case "VIDEO":
            let url = URL(string: dto.mediaUrl ?? "") ?? URL(string: "about:blank")!
            let thumb = dto.mediaThumbnail.flatMap { URL(string: $0) }
            return .video(url, thumbnailURL: thumb)
        case "AUDIO":
            let url = URL(string: dto.mediaUrl ?? "") ?? URL(string: "about:blank")!
            return .audio(url, duration: dto.mediaDuration ?? 0)
        case "POST":
            return .post(postId: dto.referenceId ?? dto.textContent ?? "")
        case "STORY":
            return .story(storyId: dto.referenceId ?? dto.textContent ?? "")
        case "REEL":
            return .reel(reelId: dto.referenceId ?? dto.textContent ?? "")
        case "LIKE":
            return .like
        default:
            return .text(dto.textContent ?? "")
        }
    }

    // MARK: - Status

    private static func toMessageStatus(_ raw: String) -> MessageStatus {
        switch raw.uppercased() {
        case "SENDING":     return .sending
        case "SENT":        return .sent
        case "DELIVERED":   return .delivered
        case "READ":        return .read
        case "FAILED":      return .failed
        default:            return .sent
        }
    }

    // MARK: - Content Type String (for API requests)

    static func contentTypeString(_ content: MessageContent) -> String {
        switch content {
        case .text:    return "TEXT"
        case .image:   return "IMAGE"
        case .video:   return "VIDEO"
        case .audio:   return "AUDIO"
        case .post:    return "POST"
        case .story:   return "STORY"
        case .reel:    return "REEL"
        case .like:    return "LIKE"
        }
    }

    /// Extract the content string value for persistence/API requests.
    static func contentValue(_ content: MessageContent) -> String {
        switch content {
        case .text(let text):           return text
        case .image(let url):           return url.absoluteString
        case .video(let url, _):        return url.absoluteString
        case .audio(let url, _):        return url.absoluteString
        case .post(let postId):         return postId
        case .story(let storyId):       return storyId
        case .reel(let reelId):         return reelId
        case .like:                     return ""
        }
    }
}
