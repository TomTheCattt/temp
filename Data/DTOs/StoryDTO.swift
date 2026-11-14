//
//  StoryDTO.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - UserStoryGroupDTO

/// API response model for grouped stories by user (Backend v2.0 feed structure: `{ "userId": "...", "author": {...}, "stories": [...] }`).
nonisolated struct UserStoryGroupDTO: Decodable, Sendable {
    let userId: String
    let author: UserStoryDTO
    let stories: [StoryDTO]
}

// MARK: - StoryDTO

/// API response model for Story. Matches BE response format.
nonisolated struct StoryDTO: Decodable, Sendable {
    let id: String
    var authorId: String?
    let audience: String?
    let viewsCount: Int?
    let repliesCount: Int?
    let createdAt: String?
    let expiresAt: String?
    var author: UserStoryDTO?     // Present in feed, absent in user-specific items, or injected from UserStoryGroupDTO
    let items: [StoryItemDTO]
    let viewed: Bool?
    let views: [StoryViewDTO]?  // Array of views; non-empty means current user has viewed

    enum CodingKeys: String, CodingKey {
        case id, authorId, audience, viewsCount, repliesCount, createdAt, expiresAt, author, items, viewed, views
    }

    init(
        id: String,
        authorId: String? = nil,
        audience: String? = nil,
        viewsCount: Int? = nil,
        repliesCount: Int? = nil,
        createdAt: String? = nil,
        expiresAt: String? = nil,
        author: UserStoryDTO? = nil,
        items: [StoryItemDTO] = [],
        viewed: Bool? = nil,
        views: [StoryViewDTO]? = nil
    ) {
        self.id = id
        self.authorId = authorId
        self.audience = audience
        self.viewsCount = viewsCount
        self.repliesCount = repliesCount
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.author = author
        self.items = items
        self.viewed = viewed
        self.views = views
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        authorId = try container.decodeIfPresent(String.self, forKey: .authorId)
        audience = try container.decodeIfPresent(String.self, forKey: .audience)
        viewsCount = try container.decodeIfPresent(Int.self, forKey: .viewsCount)
        repliesCount = try container.decodeIfPresent(Int.self, forKey: .repliesCount)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        expiresAt = try container.decodeIfPresent(String.self, forKey: .expiresAt)
        author = try container.decodeIfPresent(UserStoryDTO.self, forKey: .author)
        items = try container.decodeIfPresent([StoryItemDTO].self, forKey: .items) ?? []
        viewed = try container.decodeIfPresent(Bool.self, forKey: .viewed)
        views = try container.decodeIfPresent([StoryViewDTO].self, forKey: .views)
    }
}

// MARK: - StoryReplyDTO

/// API response model for Story Reply.
nonisolated struct StoryReplyDTO: Decodable, Sendable {
    let id: String
    let storyId: String
    let userId: String
    let text: String
    let createdAt: String
    let user: CommentAuthorDTO
    let reactions: [StoryReactionDTO]?
}

/// API response model for Story Reply Reaction.
nonisolated struct StoryReactionDTO: Decodable, Sendable {
    let id: String
    let emoji: String
    let userId: String
}

// MARK: - StoryRepliesResultDTO

nonisolated struct StoryRepliesResultDTO: Decodable, Sendable {
    let replies: [StoryReplyDTO]
    let isCurrentUserOwner: Bool
    let areRepliesEnabled: Bool
}

// MARK: - StoryReplyWrapperDTO

/// Wrapper for single story reply response: `{ "reply": {...} }` inside data envelope.
nonisolated struct StoryReplyWrapperDTO: Decodable, Sendable {
    let reply: StoryReplyDTO
}

// MARK: - StoryRepliesResultWrapperDTO

/// Wrapper for story replies result response.
nonisolated struct StoryRepliesResultWrapperDTO: Decodable, Sendable {
    let replies: StoryRepliesResultDTO
}

// MARK: - StoryItemDTO

nonisolated struct StoryItemDTO: Decodable, Sendable {
    let id: String
    let storyId: String?
    let mediaUrl: String
    let thumbnailUrl: String?
    let type: String            // "IMAGE" | "VIDEO" (uppercase from BE)
    let duration: Double
    let sortOrder: Int?
    let stickerType: String?    // "poll" | "question" | "mention" | "hashtag" | "location" | "link" | "music"
    let stickerData: String?    // JSON string
    let createdAt: String?      // Can be nil in BE feed response

    enum CodingKeys: String, CodingKey {
        case id, storyId, mediaUrl, thumbnailUrl, type, duration, sortOrder, stickerType, stickerData, createdAt
    }

    init(
        id: String,
        storyId: String? = nil,
        mediaUrl: String,
        thumbnailUrl: String? = nil,
        type: String,
        duration: Double,
        sortOrder: Int? = nil,
        stickerType: String? = nil,
        stickerData: String? = nil,
        createdAt: String? = nil
    ) {
        self.id = id
        self.storyId = storyId
        self.mediaUrl = mediaUrl
        self.thumbnailUrl = thumbnailUrl
        self.type = type
        self.duration = duration
        self.sortOrder = sortOrder
        self.stickerType = stickerType
        self.stickerData = stickerData
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        storyId = try container.decodeIfPresent(String.self, forKey: .storyId)
        mediaUrl = try container.decode(String.self, forKey: .mediaUrl)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "IMAGE"

        // Flexible duration: Double, Int, String (fallback to 5.0)
        if let d = try? container.decode(Double.self, forKey: .duration) {
            duration = d
        } else if let i = try? container.decode(Int.self, forKey: .duration) {
            duration = Double(i)
        } else if let s = try? container.decode(String.self, forKey: .duration), let d = Double(s) {
            duration = d
        } else {
            duration = 5.0
        }

        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder)
        stickerType = try container.decodeIfPresent(String.self, forKey: .stickerType)

        // Flexible stickerData: String or null
        if let str = try? container.decode(String.self, forKey: .stickerData) {
            stickerData = str
        } else {
            stickerData = nil
        }

        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    }
}

// MARK: - UserStoryDTO

nonisolated struct UserStoryDTO: Decodable, Sendable {
    let id: String
    let username: String?
    let fullName: String?
    let avatarUrl: String?
    let isVerified: Bool?
}

// MARK: - StoryViewDTO

nonisolated struct StoryViewDTO: Decodable, Sendable {
    let id: String
}

// MARK: - StoryWrapperDTO

/// Wrapper for single story creation response: `{ "story": {...} }` inside data envelope.
nonisolated struct StoryWrapperDTO: Decodable, Sendable {
    let story: StoryDTO
}

// MARK: - StoriesFeedDTO

/// Wrapper for stories feed response: `{ "items": [...] }` inside data envelope.
/// Polymorphically supports both Backend v2.0 grouped format (`[UserStoryGroupDTO]`)
/// and flat format (`[StoryDTO]`).
nonisolated struct StoriesFeedDTO: Decodable, Sendable {
    let items: [StoryDTO]

    enum CodingKeys: String, CodingKey {
        case items
    }

    init(items: [StoryDTO]) {
        self.items = items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 1. Try decoding as grouped user stories: [UserStoryGroupDTO]
        if let groups = try? container.decode([UserStoryGroupDTO].self, forKey: .items) {
            var flattened: [StoryDTO] = []
            for group in groups {
                for var story in group.stories {
                    if story.authorId == nil || story.authorId?.isEmpty == true {
                        story.authorId = group.userId
                    }
                    if story.author == nil {
                        story.author = group.author
                    }
                    flattened.append(story)
                }
            }
            self.items = flattened
            return
        }

        // 2. Fallback: try decoding directly as flat [StoryDTO]
        if let flatStories = try? container.decode([StoryDTO].self, forKey: .items) {
            self.items = flatStories
            return
        }

        // 3. Fallback: empty if items is missing or incompatible
        self.items = []
    }
}

// MARK: - UserStoriesDTO

/// Wrapper for user-specific stories: `{ "stories": [...] }` or `{ "items": [...] }` inside data envelope.
nonisolated struct UserStoriesDTO: Decodable, Sendable {
    let stories: [StoryDTO]

    enum CodingKeys: String, CodingKey {
        case stories
        case items
    }

    init(stories: [StoryDTO]) {
        self.stories = stories
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let list = try? container.decode([StoryDTO].self, forKey: .stories) {
            self.stories = list
        } else if let list = try? container.decode([StoryDTO].self, forKey: .items) {
            self.stories = list
        } else {
            self.stories = []
        }
    }
}
