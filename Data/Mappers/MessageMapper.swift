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

    static func toConversation(_ dto: ConversationDTO) -> Conversation {
        Conversation(
            id: dto.id,
            participants: UserMapper.toEntityList(dto.participants),
            lastMessage: dto.lastMessage.map { toMessage($0) },
            unreadCount: dto.unreadCount,
            isGroup: dto.isGroup,
            groupName: dto.groupName,
            groupAvatarURL: dto.groupAvatarUrl.flatMap { URL(string: $0) },
            updatedAt: DateMapper.toDate(dto.updatedAt),
            isMuted: dto.isMuted
        )
    }

    static func toConversationList(_ dtos: [ConversationDTO]) -> [Conversation] {
        dtos.map { toConversation($0) }
    }

    // MARK: - Message

    static func toMessage(_ dto: MessageDTO) -> Message {
        Message(
            id: dto.id,
            conversationId: dto.conversationId,
            sender: UserMapper.toEntity(dto.sender),
            content: toMessageContent(type: dto.contentType, content: dto.content, thumbnailUrl: dto.thumbnailUrl, duration: dto.duration),
            status: toMessageStatus(dto.status),
            replyToId: dto.replyToId,
            createdAt: DateMapper.toDate(dto.createdAt)
        )
    }

    static func toMessageList(_ dtos: [MessageDTO]) -> [Message] {
        dtos.map { toMessage($0) }
    }

    // MARK: - Content

    private static func toMessageContent(type: String, content: String, thumbnailUrl: String?, duration: Double?) -> MessageContent {
        switch type {
        case "text":
            return .text(content)
        case "image":
            return .image(URL(string: content)!)
        case "video":
            let thumb = thumbnailUrl.flatMap { URL(string: $0) }
            return .video(URL(string: content)!, thumbnailURL: thumb)
        case "audio":
            return .audio(URL(string: content)!, duration: duration ?? 0)
        case "post":
            return .post(postId: content)
        case "story":
            return .story(storyId: content)
        case "reel":
            return .reel(reelId: content)
        case "like":
            return .like
        default:
            return .text(content)
        }
    }

    // MARK: - Status

    private static func toMessageStatus(_ raw: String) -> MessageStatus {
        switch raw {
        case "sending":   return .sending
        case "sent":      return .sent
        case "delivered": return .delivered
        case "read":      return .read
        case "failed":    return .failed
        default:          return .sent
        }
    }

    // MARK: - Content Type String (for API requests)

    static func contentTypeString(_ content: MessageContent) -> String {
        switch content {
        case .text:    return "text"
        case .image:   return "image"
        case .video:   return "video"
        case .audio:   return "audio"
        case .post:    return "post"
        case .story:   return "story"
        case .reel:    return "reel"
        case .like:    return "like"
        }
    }

    /// Extract the content string value for API request.
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
