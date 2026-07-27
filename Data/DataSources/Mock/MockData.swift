//
//  MockData.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import Foundation

// MARK: - MockData

/// Central fake data store for UI development.
enum MockData {

    // MARK: - Users

    static let currentUser = User(
        id: "user_current",
        username: "tomthecat",
        fullName: "Tom The Cat",
        email: "tom@example.com",
        phone: "+84901234567",
        avatarURL: URL(string: "https://i.pravatar.cc/300?u=tomthecat"),
        bio: "iOS Developer 🍎 | Coffee lover ☕️ | Building things",
        website: "https://tomthecat.dev",
        isVerified: true,
        isPrivate: false,
        followersCount: 1234,
        followingCount: 567,
        postsCount: 42,
        createdAt: Date(timeIntervalSinceNow: -365 * 24 * 3600),
        isFollowing: false,
        isFollowedBy: false,
        isBlocked: false
    )

    static let users: [User] = [
        User(id: "user_1", username: "jane_doe", fullName: "Jane Doe", email: nil, phone: nil,
             avatarURL: URL(string: "https://i.pravatar.cc/300?u=jane"), bio: "Photographer 📸", website: nil,
             isVerified: false, isPrivate: false, followersCount: 892, followingCount: 234, postsCount: 67,
             createdAt: Date(timeIntervalSinceNow: -200 * 24 * 3600), isFollowing: true, isFollowedBy: true, isBlocked: false),
        User(id: "user_2", username: "john_smith", fullName: "John Smith", email: nil, phone: nil,
             avatarURL: URL(string: "https://i.pravatar.cc/300?u=john"), bio: "Travel 🌍 | Food 🍕", website: "https://johnsmith.com",
             isVerified: true, isPrivate: false, followersCount: 45_000, followingCount: 890, postsCount: 312,
             createdAt: Date(timeIntervalSinceNow: -500 * 24 * 3600), isFollowing: true, isFollowedBy: false, isBlocked: false),
        User(id: "user_3", username: "sara_design", fullName: "Sara Design", email: nil, phone: nil,
             avatarURL: URL(string: "https://i.pravatar.cc/300?u=sara"), bio: "UI/UX Designer ✨", website: nil,
             isVerified: false, isPrivate: true, followersCount: 2341, followingCount: 456, postsCount: 89,
             createdAt: Date(timeIntervalSinceNow: -150 * 24 * 3600), isFollowing: false, isFollowedBy: true, isBlocked: false),
        User(id: "user_4", username: "mike_dev", fullName: "Mike Developer", email: nil, phone: nil,
             avatarURL: URL(string: "https://i.pravatar.cc/300?u=mike"), bio: "SwiftUI | Kotlin | Rust", website: nil,
             isVerified: false, isPrivate: false, followersCount: 567, followingCount: 123, postsCount: 23,
             createdAt: Date(timeIntervalSinceNow: -90 * 24 * 3600), isFollowing: false, isFollowedBy: false, isBlocked: false),
        User(id: "user_5", username: "lisa_art", fullName: "Lisa Art", email: nil, phone: nil,
             avatarURL: URL(string: "https://i.pravatar.cc/300?u=lisa"), bio: "Digital Artist 🎨", website: "https://lisaart.co",
             isVerified: true, isPrivate: false, followersCount: 120_000, followingCount: 345, postsCount: 567,
             createdAt: Date(timeIntervalSinceNow: -800 * 24 * 3600), isFollowing: true, isFollowedBy: true, isBlocked: false),
    ]

    // MARK: - Posts

    static let posts: [Post] = (0..<10).map { index in
        let author = users[index % users.count]
        return Post(
            id: "post_\(index)",
            author: author,
            caption: mockCaptions[index % mockCaptions.count],
            mediaItems: [
                MediaItem(
                    id: "media_\(index)_0",
                    url: URL(string: "https://picsum.photos/seed/post\(index)/1080/1080")!,
                    thumbnailURL: URL(string: "https://picsum.photos/seed/post\(index)/400/400"),
                    type: .image,
                    width: 1080,
                    height: 1080,
                    duration: nil
                )
            ],
            location: index % 3 == 0 ? PostLocation(name: "Ho Chi Minh City", latitude: 10.8231, longitude: 106.6297) : nil,
            likesCount: Int.random(in: 10...5000),
            commentsCount: Int.random(in: 0...200),
            createdAt: Date(timeIntervalSinceNow: -Double(index) * 3600 * 2),
            isLiked: index % 2 == 0,
            isSaved: index % 4 == 0,
            isSponsored: index == 3
        )
    }

    // MARK: - Stories

    static let stories: [Story] = users.enumerated().map { index, user in
        Story(
            id: "story_\(index)",
            author: user,
            items: [
                StoryItem(
                    id: "story_item_\(index)_0",
                    mediaURL: URL(string: "https://picsum.photos/seed/story\(index)/1080/1920")!,
                    type: .image,
                    duration: 5,
                    createdAt: Date(timeIntervalSinceNow: -Double(index) * 3600),
                    sticker: nil
                )
            ],
            isViewed: index > 2,
            createdAt: Date(timeIntervalSinceNow: -Double(index) * 3600),
            expiresAt: Date(timeIntervalSinceNow: Double(24 - index) * 3600)
        )
    }

    // MARK: - Comments

    static func comments(forPostId postId: String) -> [Comment] {
        (0..<5).map { index in
            Comment(
                id: "comment_\(postId)_\(index)",
                postId: postId,
                author: users[index % users.count],
                text: mockCommentTexts[index % mockCommentTexts.count],
                likesCount: Int.random(in: 0...50),
                isLiked: index % 3 == 0,
                replies: index == 0 ? [
                    Comment(
                        id: "reply_\(postId)_\(index)_0",
                        postId: postId,
                        author: users[(index + 1) % users.count],
                        text: "Thanks! 🙏",
                        likesCount: 2,
                        isLiked: false,
                        replies: [],
                        parentId: "comment_\(postId)_\(index)",
                        createdAt: Date(timeIntervalSinceNow: -Double(index) * 1800)
                    )
                ] : [],
                parentId: nil,
                createdAt: Date(timeIntervalSinceNow: -Double(index) * 3600)
            )
        }
    }

    // MARK: - Notifications

    static let notifications: [AppNotification] = [
        AppNotification(id: "notif_1", type: .like, actor: users[0], postId: "post_0",
                        postThumbnailURL: URL(string: "https://picsum.photos/seed/post0/400/400"),
                        commentText: nil, isRead: false, createdAt: Date(timeIntervalSinceNow: -300)),
        AppNotification(id: "notif_2", type: .comment, actor: users[1], postId: "post_1",
                        postThumbnailURL: URL(string: "https://picsum.photos/seed/post1/400/400"),
                        commentText: "Amazing shot! 🔥", isRead: false, createdAt: Date(timeIntervalSinceNow: -3600)),
        AppNotification(id: "notif_3", type: .follow, actor: users[2], postId: nil,
                        postThumbnailURL: nil, commentText: nil, isRead: true,
                        createdAt: Date(timeIntervalSinceNow: -7200)),
        AppNotification(id: "notif_4", type: .like, actor: users[3], postId: "post_2",
                        postThumbnailURL: URL(string: "https://picsum.photos/seed/post2/400/400"),
                        commentText: nil, isRead: true, createdAt: Date(timeIntervalSinceNow: -86400)),
        AppNotification(id: "notif_5", type: .mention, actor: users[4], postId: "post_3",
                        postThumbnailURL: URL(string: "https://picsum.photos/seed/post3/400/400"),
                        commentText: nil, isRead: true, createdAt: Date(timeIntervalSinceNow: -172800)),
    ]

    // MARK: - Conversations

    static let conversations: [Conversation] = users.enumerated().map { index, user in
        Conversation(
            id: "conv_\(index)",
            participants: [currentUser, user],
            lastMessage: Message(
                id: "msg_last_\(index)",
                conversationId: "conv_\(index)",
                sender: index % 2 == 0 ? user : currentUser,
                content: .text(mockMessageTexts[index % mockMessageTexts.count]),
                status: .read,
                replyToId: nil,
                createdAt: Date(timeIntervalSinceNow: -Double(index) * 3600)
            ),
            unreadCount: index < 2 ? Int.random(in: 1...5) : 0,
            isGroup: false,
            groupName: nil,
            groupAvatarURL: nil,
            updatedAt: Date(timeIntervalSinceNow: -Double(index) * 3600),
            isMuted: index == 4
        )
    }

    // MARK: - Private: Mock text arrays

    private static let mockCaptions = [
        "Beautiful day! ☀️ #photography #nature",
        "Coffee and code ☕️💻 #developer #life",
        "Exploring new places 🌍✈️",
        nil,
        "Design is not just what it looks like. Design is how it works. 🎨",
        "Weekend vibes 🎶 #chill #weekend",
        "New project coming soon! Stay tuned 🚀",
        "Grateful for this journey 🙏 #blessed",
        "Sunset magic 🌅",
        "Friends make everything better 💛",
    ] as [String?]

    private static let mockCommentTexts = [
        "This is amazing! 🔥",
        "Love this shot 📸",
        "So beautiful!",
        "Where is this? I need to visit!",
        "Goals 😍",
    ]

    private static let mockMessageTexts = [
        "Hey! How are you?",
        "Did you see that post? 😂",
        "Let's catch up this weekend!",
        "Thanks for sharing!",
        "See you tomorrow 👋",
    ]
}
