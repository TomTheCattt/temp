//
//  DataSchemaMappingTests.swift
//  InstagramTests
//
//  Created by Kiro on 13/11/26.
//  Unit tests and empirical benchmarks for Backend v2.0 Data Schema mapping.
//

import XCTest
import Foundation
@testable import Instagram

final class DataSchemaMappingTests: XCTestCase {

    private let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .useDefaultKeys
        dec.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return dec
    }()

    // MARK: - 1. ReelDTO & Flexible Duration Tests

    func testReelDecoding_WithDoubleDuration() throws {
        let json = """
        {
            "id": "reel_001",
            "authorId": "usr_100",
            "videoUrl": "https://example.com/reel.mp4",
            "thumbnailUrl": "https://example.com/thumb.jpg",
            "caption": "Reel with double duration",
            "audioId": "audio_999",
            "audioName": "Trending Sound",
            "audioArtist": "Artist Name",
            "duration": 15.5,
            "likesCount": 42,
            "commentsCount": 10,
            "savesCount": 5,
            "viewsCount": 100,
            "allowRemix": true,
            "allowDownload": false,
            "createdAt": "2026-11-13T10:00:00.000Z",
            "author": {
                "id": "usr_100",
                "username": "kiro_dev",
                "fullName": "Kiro iOS",
                "avatarUrl": "https://example.com/avatar.jpg",
                "isVerified": true,
                "isFollowing": false
            }
        }
        """.data(using: .utf8)!

        let clock = ContinuousClock()
        let start = clock.now
        let dto = try decoder.decode(ReelDTO.self, from: json)
        let reel = ReelMapper.toEntity(dto)
        let elapsed = clock.now - start

        XCTAssertEqual(dto.id, "reel_001")
        XCTAssertEqual(dto.duration, 15.5)
        XCTAssertEqual(dto.audioId, "audio_999")
        XCTAssertEqual(dto.savesCount, 5)
        XCTAssertEqual(dto.allowDownload, false)

        XCTAssertEqual(reel.durationSeconds, 15.5)
        XCTAssertEqual(reel.audioTrack?.id, "audio_999")
        XCTAssertEqual(reel.savesCount, 5)
        XCTAssertEqual(reel.allowDownload, false)

        print("⏱️ [Benchmark] ReelDTO decode & map took: \(elapsed)")
    }

    func testReelDecoding_WithStringDurationFallback() throws {
        let json = """
        {
            "id": "reel_002",
            "authorId": "usr_100",
            "videoUrl": "https://example.com/reel.mp4",
            "duration": "12.3",
            "createdAt": "2026-11-13T10:00:00.000Z",
            "author": {
                "id": "usr_100"
            }
        }
        """.data(using: .utf8)!

        let dto = try decoder.decode(ReelDTO.self, from: json)
        let reel = ReelMapper.toEntity(dto)

        XCTAssertEqual(dto.duration, 12.3)
        XCTAssertEqual(reel.durationSeconds, 12.3)
        XCTAssertEqual(reel.duration, "12.3")
    }

    // MARK: - 2. Polymorphic Comment Tests

    func testCommentDecoding_PolymorphicReelComment() throws {
        let json = """
        {
            "id": "comment_555",
            "commentableType": "REEL",
            "commentableId": "reel_123",
            "authorId": "usr_200",
            "text": "Great reel!",
            "likesCount": 7,
            "repliesCount": 2,
            "createdAt": "2026-11-13T10:15:00.000Z",
            "author": {
                "id": "usr_200",
                "username": "user2"
            }
        }
        """.data(using: .utf8)!

        let dto = try decoder.decode(CommentDTO.self, from: json)
        let comment = CommentMapper.toEntity(dto)

        XCTAssertEqual(dto.resolvedCommentableType, .reel)
        XCTAssertEqual(dto.resolvedCommentableId, "reel_123")
        XCTAssertEqual(comment.commentableType, .reel)
        XCTAssertEqual(comment.commentableId, "reel_123")
        XCTAssertEqual(comment.postId, "reel_123") // Legacy alias
        XCTAssertEqual(comment.repliesCount, 2)
    }

    // MARK: - 3. Polymorphic Notification Tests

    func testNotificationDecoding_AllReferenceFields() throws {
        let json = """
        {
            "id": "notif_777",
            "recipientId": "usr_me",
            "actorId": "usr_friend",
            "type": "REEL_LIKE",
            "referenceType": "reel",
            "referenceId": "reel_999",
            "previewText": "loved your video",
            "thumbnailUrl": "https://example.com/reel_thumb.jpg",
            "deepLink": "instagram://reel/reel_999",
            "isRead": false,
            "createdAt": "2026-11-13T11:00:00.000Z",
            "actor": {
                "id": "usr_friend",
                "username": "friend_user"
            }
        }
        """.data(using: .utf8)!

        let dto = try decoder.decode(NotificationDTO.self, from: json)
        let notif = NotificationMapper.toEntity(dto)

        XCTAssertEqual(notif.type, .reelLike)
        XCTAssertEqual(notif.referenceType, "reel")
        XCTAssertEqual(notif.referenceId, "reel_999")
        XCTAssertEqual(notif.previewText, "loved your video")
        XCTAssertEqual(notif.deepLink, "instagram://reel/reel_999")
        XCTAssertEqual(notif.postThumbnailURL?.absoluteString, "https://example.com/reel_thumb.jpg")
    }

    // MARK: - 4. Direct Message & Reaction Tests

    func testMessageDecoding_WithReactionsAndShare() throws {
        let json = """
        {
            "id": "msg_888",
            "conversationId": "conv_111",
            "senderId": "usr_200",
            "contentType": "POST_SHARE",
            "referenceId": "post_456",
            "status": "DELIVERED",
            "isEphemeral": false,
            "isEdited": false,
            "isUnsent": false,
            "createdAt": "2026-11-13T11:30:00.000Z",
            "reactions": [
                {
                    "id": "react_1",
                    "messageId": "msg_888",
                    "userId": "usr_me",
                    "emoji": "🔥"
                }
            ]
        }
        """.data(using: .utf8)!

        let dto = try decoder.decode(MessageDTO.self, from: json)
        let message = MessageMapper.toMessage(dto)

        XCTAssertEqual(dto.reactions?.count, 1)
        XCTAssertEqual(dto.reactions?.first?.emoji, "🔥")
        XCTAssertEqual(message.reactions["usr_me"], "🔥")

        if case .post(let postId) = message.content {
            XCTAssertEqual(postId, "post_456")
        } else {
            XCTFail("Expected .post content type for POST_SHARE")
        }
    }

    // MARK: - 5. UserDTO Better Auth & Profile Fields

    func testUserDecoding_BetterAuthAndBusiness() throws {
        let json = """
        {
            "id": "usr_better_auth",
            "username": "creator_pro",
            "name": "Creator Name",
            "fullName": "Creator Name",
            "email": "creator@example.com",
            "avatarUrl": "https://example.com/avatar.jpg",
            "avatarThumbUrl": "https://example.com/avatar_thumb.jpg",
            "isVerified": true,
            "isPrivate": false,
            "isBusiness": true,
            "businessCategory": "Digital Creator",
            "followersCount": 5000,
            "followingCount": 300,
            "postsCount": 85,
            "reelsCount": 42,
            "createdAt": "2026-11-13T08:00:00.000Z"
        }
        """.data(using: .utf8)!

        let dto = try decoder.decode(UserDTO.self, from: json)
        let user = UserMapper.toEntity(dto)

        XCTAssertEqual(user.fullName, "Creator Name")
        XCTAssertEqual(user.avatarThumbURL?.absoluteString, "https://example.com/avatar_thumb.jpg")
        XCTAssertEqual(user.isBusiness, true)
        XCTAssertEqual(user.businessCategory, "Digital Creator")
        XCTAssertEqual(user.reelsCount, 42)
    }

    // MARK: - 6. Generic Pagination Tests

    func testGenericCursorPagination() throws {
        let json = """
        {
            "items": [
                {
                    "id": "post_1",
                    "authorId": "usr_1",
                    "likesCount": 10,
                    "commentsCount": 2,
                    "sharesCount": 1,
                    "savesCount": 3,
                    "viewsCount": 50,
                    "isSponsored": false,
                    "closeFriendsOnly": false,
                    "createdAt": "2026-11-13T09:00:00.000Z",
                    "author": { "id": "usr_1" },
                    "mediaItems": []
                }
            ],
            "nextCursor": "cursor_token_xyz",
            "hasMore": true
        }
        """.data(using: .utf8)!

        let paginated = try decoder.decode(CursorPaginatedData<PostDTO>.self, from: json)
        XCTAssertEqual(paginated.items.count, 1)
        XCTAssertEqual(paginated.nextCursor, "cursor_token_xyz")
        XCTAssertEqual(paginated.hasMore, true)
    }

    // MARK: - 7. Explore Posts Real Backend Payload Test (locationLat/locationLng string format)

    func testExplorePostsDecoding_WithRealBackendPayload() throws {
        let json = """
        {
            "success": true,
            "data": {
                "items": [
                    {
                        "id": "post-029",
                        "authorId": "user-13",
                        "caption": "Celebrating small wins 🎉 Got the promotion! Hard work pays off.",
                        "locationName": "Hoi An, Vietnam",
                        "locationLat": "15.8801",
                        "locationLng": "108.338",
                        "likesCount": 11,
                        "commentsCount": 9,
                        "sharesCount": 0,
                        "savesCount": 0,
                        "viewsCount": 0,
                        "isSponsored": false,
                        "sponsorUserId": null,
                        "audience": "PUBLIC",
                        "closeFriendsOnly": false,
                        "createdAt": "2026-11-04T22:57:17.116Z",
                        "updatedAt": "2026-11-04T22:57:17.116Z",
                        "author": {
                            "id": "user-13",
                            "username": "quynhlam13",
                            "fullName": "Quynh Lam",
                            "avatarUrl": "https://i.pravatar.cc/400?u=quynhlam13",
                            "isVerified": false,
                            "isPrivate": false
                        },
                        "mediaItems": [
                            {
                                "id": "media-post-029-0",
                                "url": "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
                                "thumbnailUrl": "https://picsum.photos/seed/post-029-0-thumb/480/600",
                                "type": "VIDEO",
                                "width": 1920,
                                "height": 1080,
                                "duration": 13,
                                "sortOrder": 0
                            },
                            {
                                "id": "media-post-029-1",
                                "url": "https://picsum.photos/seed/post-029-1/1080/1350",
                                "thumbnailUrl": null,
                                "type": "IMAGE",
                                "width": 1080,
                                "height": 1350,
                                "duration": null,
                                "sortOrder": 1
                            }
                        ],
                        "isLiked": false,
                        "isSaved": false,
                        "exploreSource": "collaborative",
                        "exploreReason": "Liked by similar users"
                    },
                    {
                        "id": "post-005",
                        "authorId": "user-8",
                        "caption": "Street photography session 📷 Captured this candid moment. The city tells stories.",
                        "locationName": "Hanoi, Vietnam",
                        "locationLat": "21.0285",
                        "locationLng": "105.8542",
                        "likesCount": 12,
                        "commentsCount": 7,
                        "sharesCount": 0,
                        "savesCount": 0,
                        "viewsCount": 0,
                        "isSponsored": false,
                        "sponsorUserId": null,
                        "audience": "PUBLIC",
                        "closeFriendsOnly": false,
                        "createdAt": "2026-10-30T15:58:02.338Z",
                        "updatedAt": "2026-10-30T15:58:02.338Z",
                        "author": {
                            "id": "user-8",
                            "username": "tuanduong8",
                            "fullName": "Tuan Duong",
                            "avatarUrl": "https://i.pravatar.cc/400?u=tuanduong8",
                            "isVerified": false,
                            "isPrivate": false
                        },
                        "mediaItems": [
                            {
                                "id": "media-post-005-0",
                                "url": "https://picsum.photos/seed/post-005-0/1080/1350",
                                "thumbnailUrl": null,
                                "type": "IMAGE",
                                "width": 1080,
                                "height": 1350,
                                "duration": null,
                                "sortOrder": 0
                            }
                        ],
                        "isLiked": false,
                        "isSaved": false,
                        "exploreSource": "collaborative",
                        "exploreReason": "Liked by similar users"
                    },
                    {
                        "id": "post-044",
                        "authorId": "user-1",
                        "caption": "Plant haul 🪴 Added 5 new babies to the collection. Plant parent life!",
                        "locationName": "Da Nang, Vietnam",
                        "locationLat": "16.0544",
                        "locationLng": "108.2022",
                        "likesCount": 9,
                        "commentsCount": 8,
                        "sharesCount": 0,
                        "savesCount": 0,
                        "viewsCount": 0,
                        "isSponsored": false,
                        "sponsorUserId": null,
                        "audience": "PUBLIC",
                        "closeFriendsOnly": false,
                        "createdAt": "2026-10-31T09:52:46.215Z",
                        "updatedAt": "2026-10-31T09:52:46.215Z",
                        "author": {
                            "id": "user-1",
                            "username": "hoangdinh1",
                            "fullName": "Hoang Dinh",
                            "avatarUrl": "https://i.pravatar.cc/400?u=hoangdinh1",
                            "isVerified": false,
                            "isPrivate": true
                        },
                        "mediaItems": [
                            {
                                "id": "media-post-044-0",
                                "url": "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
                                "thumbnailUrl": "https://picsum.photos/seed/post-044-0-thumb/480/600",
                                "type": "VIDEO",
                                "width": 1920,
                                "height": 1080,
                                "duration": 24,
                                "sortOrder": 0
                            },
                            {
                                "id": "media-post-044-1",
                                "url": "https://picsum.photos/seed/post-044-1/1080/1350",
                                "thumbnailUrl": null,
                                "type": "IMAGE",
                                "width": 1080,
                                "height": 1350,
                                "duration": null,
                                "sortOrder": 1
                            },
                            {
                                "id": "media-post-044-2",
                                "url": "https://picsum.photos/seed/post-044-2/1080/1350",
                                "thumbnailUrl": null,
                                "type": "IMAGE",
                                "width": 1080,
                                "height": 1350,
                                "duration": null,
                                "sortOrder": 2
                            },
                            {
                                "id": "media-post-044-3",
                                "url": "https://picsum.photos/seed/post-044-3/1080/1350",
                                "thumbnailUrl": null,
                                "type": "IMAGE",
                                "width": 1080,
                                "height": 1350,
                                "duration": null,
                                "sortOrder": 3
                            }
                        ],
                        "isLiked": false,
                        "isSaved": false,
                        "exploreSource": "collaborative",
                        "exploreReason": "Liked by similar users"
                    },
                    {
                        "id": "post-011",
                        "authorId": "user-11",
                        "caption": "Celebrating small wins 🎉 Got the promotion! Hard work pays off.",
                        "locationName": "Hoi An, Vietnam",
                        "locationLat": "15.8801",
                        "locationLng": "108.338",
                        "likesCount": 10,
                        "commentsCount": 6,
                        "sharesCount": 0,
                        "savesCount": 0,
                        "viewsCount": 0,
                        "isSponsored": false,
                        "sponsorUserId": null,
                        "audience": "PUBLIC",
                        "closeFriendsOnly": false,
                        "createdAt": "2026-11-01T22:08:31.254Z",
                        "updatedAt": "2026-11-01T22:08:31.254Z",
                        "author": {
                            "id": "user-11",
                            "username": "ngochuynh11",
                            "fullName": "Ngoc Huynh",
                            "avatarUrl": "https://i.pravatar.cc/400?u=ngochuynh11",
                            "isVerified": false,
                            "isPrivate": false
                        },
                        "mediaItems": [
                            {
                                "id": "media-post-011-0",
                                "url": "https://picsum.photos/seed/post-011-0/1080/1350",
                                "thumbnailUrl": null,
                                "type": "IMAGE",
                                "width": 1080,
                                "height": 1350,
                                "duration": null,
                                "sortOrder": 0
                            },
                            {
                                "id": "media-post-011-1",
                                "url": "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
                                "thumbnailUrl": "https://picsum.photos/seed/post-011-1-thumb/480/600",
                                "type": "VIDEO",
                                "width": 1920,
                                "height": 1080,
                                "duration": 41,
                                "sortOrder": 1
                            },
                            {
                                "id": "media-post-011-2",
                                "url": "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
                                "thumbnailUrl": "https://picsum.photos/seed/post-011-2-thumb/480/600",
                                "type": "VIDEO",
                                "width": 1920,
                                "height": 1080,
                                "duration": 10,
                                "sortOrder": 2
                            },
                            {
                                "id": "media-post-011-3",
                                "url": "https://picsum.photos/seed/post-011-3/1080/1350",
                                "thumbnailUrl": null,
                                "type": "IMAGE",
                                "width": 1080,
                                "height": 1350,
                                "duration": null,
                                "sortOrder": 3
                            }
                        ],
                        "isLiked": false,
                        "isSaved": false,
                        "exploreSource": "content_based",
                        "exploreReason": "Matches your interests"
                    },
                    {
                        "id": "post-028",
                        "authorId": "user-19",
                        "caption": "Travel diary ✈️ Day 3 in Bali - rice terraces, temples, and endless smiles.",
                        "locationName": "Hoi An, Vietnam",
                        "locationLat": "15.8801",
                        "locationLng": "108.338",
                        "likesCount": 13,
                        "commentsCount": 3,
                        "sharesCount": 0,
                        "savesCount": 0,
                        "viewsCount": 0,
                        "isSponsored": false,
                        "sponsorUserId": null,
                        "audience": "PUBLIC",
                        "closeFriendsOnly": false,
                        "createdAt": "2026-11-01T00:04:40.363Z",
                        "updatedAt": "2026-11-01T00:04:40.363Z",
                        "author": {
                            "id": "user-19",
                            "username": "sonvo19",
                            "fullName": "Son Vo",
                            "avatarUrl": "https://i.pravatar.cc/400?u=sonvo19",
                            "isVerified": false,
                            "isPrivate": false
                        },
                        "mediaItems": [
                            {
                                "id": "media-post-028-0",
                                "url": "https://picsum.photos/seed/post-028-0/1080/1350",
                                "thumbnailUrl": null,
                                "type": "IMAGE",
                                "width": 1080,
                                "height": 1350,
                                "duration": null,
                                "sortOrder": 0
                            },
                            {
                                "id": "media-post-028-1",
                                "url": "https://picsum.photos/seed/post-028-1/1080/1350",
                                "thumbnailUrl": null,
                                "type": "IMAGE",
                                "width": 1080,
                                "height": 1350,
                                "duration": null,
                                "sortOrder": 1
                            }
                        ],
                        "isLiked": false,
                        "isSaved": false,
                        "exploreSource": "content_based",
                        "exploreReason": "Matches your interests"
                    }
                ],
                "nextCursor": null,
                "hasMore": false,
                "sections": [
                    {
                        "id": "for_you",
                        "title": "For You",
                        "type": "for_you",
                        "items": []
                    }
                ]
            }
        }
        """.data(using: .utf8)!

        let envelope = try decoder.decode(APIEnvelope<PaginatedPostsDTO>.self, from: json)
        guard let data = envelope.data else {
            XCTFail("Expected data in envelope")
            return
        }

        XCTAssertEqual(data.items.count, 5)
        let postDTO = data.items[0]
        XCTAssertEqual(postDTO.id, "post-029")
        XCTAssertEqual(postDTO.locationLat, 15.8801)
        XCTAssertEqual(postDTO.locationLng, 108.338)
        XCTAssertEqual(postDTO.mediaItems.count, 2)
        XCTAssertEqual(postDTO.mediaItems[0].duration, 13.0)

        let post = PostMapper.toEntity(postDTO)
        XCTAssertEqual(post.location?.latitude, 15.8801)
        XCTAssertEqual(post.location?.longitude, 108.338)
        XCTAssertEqual(post.likesCount, 11)
        XCTAssertEqual(post.commentsCount, 9)
    }

    // MARK: - 8. ConversationMember Nested User Decoding Tests

    func testConversationMemberDecoding_WithNestedUser() throws {
        let json = """
        {
            "id": "cm-001",
            "userId": "user-8",
            "role": "MEMBER",
            "isMuted": false,
            "lastReadAt": "2026-11-13T10:00:00.000Z",
            "user": {
                "id": "user-8",
                "username": "tuanduong8",
                "fullName": "Tuan Duong",
                "avatarUrl": "https://picsum.photos/seed/tuanduong8/400/400",
                "isVerified": true
            }
        }
        """.data(using: .utf8)!

        let memberDTO = try decoder.decode(ConversationMemberDTO.self, from: json)
        XCTAssertEqual(memberDTO.resolvedUserId, "user-8")
        XCTAssertEqual(memberDTO.resolvedUsername, "tuanduong8")
        XCTAssertEqual(memberDTO.resolvedFullName, "Tuan Duong")
        XCTAssertEqual(memberDTO.resolvedAvatarUrl, "https://picsum.photos/seed/tuanduong8/400/400")
        XCTAssertEqual(memberDTO.resolvedIsVerified, true)

        let user = memberDTO.user
        XCTAssertEqual(user.id, "user-8")
        XCTAssertEqual(user.username, "tuanduong8")
        XCTAssertEqual(user.fullName, "Tuan Duong")
        XCTAssertEqual(user.avatarURL?.absoluteString, "https://picsum.photos/seed/tuanduong8/400/400")
        XCTAssertEqual(user.isVerified, true)
    }

    func testConversationMemberDecoding_FallbackFlatFields() throws {
        let json = """
        {
            "id": "cm-002",
            "userId": "user-9",
            "role": "ADMIN",
            "username": "flat_user",
            "fullName": "Flat Name",
            "avatarUrl": "https://example.com/avatar.jpg",
            "isVerified": false
        }
        """.data(using: .utf8)!

        let memberDTO = try decoder.decode(ConversationMemberDTO.self, from: json)
        XCTAssertEqual(memberDTO.resolvedUserId, "user-9")
        XCTAssertEqual(memberDTO.resolvedUsername, "flat_user")
        XCTAssertEqual(memberDTO.resolvedFullName, "Flat Name")
        XCTAssertEqual(memberDTO.resolvedAvatarUrl, "https://example.com/avatar.jpg")

        let user = memberDTO.user
        XCTAssertEqual(user.id, "user-9")
        XCTAssertEqual(user.username, "flat_user")
        XCTAssertEqual(user.fullName, "Flat Name")
        XCTAssertEqual(user.avatarURL?.absoluteString, "https://example.com/avatar.jpg")
    }

    // MARK: - 9. Stories Feed Grouped & Polymorphic Decoding Tests

    func testStoriesFeedDecoding_WithRealGroupedBackendPayload() throws {
        let json = """
        {
            "success": true,
            "data": {
                "items": [
                    {
                        "userId": "user-10",
                        "author": {
                            "id": "user-10",
                            "username": "mylam10",
                            "fullName": "My Lam",
                            "avatarUrl": "https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=400&h=400&auto=format&fit=crop&crop=faces&q=80",
                            "isVerified": false
                        },
                        "stories": [
                            {
                                "id": "story-user-10-1794564842633",
                                "createdAt": "2026-11-13T03:14:02.680Z",
                                "expiresAt": "2026-11-14T03:14:02.633Z",
                                "audience": "followers",
                                "items": [
                                    {
                                        "id": "story-item-story-user-10-1794564842633-0",
                                        "mediaUrl": "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=1080&h=1920&auto=format&fit=crop&q=80",
                                        "type": "IMAGE",
                                        "duration": 5,
                                        "sortOrder": 0,
                                        "stickerType": null,
                                        "stickerData": null
                                    },
                                    {
                                        "id": "story-item-story-user-10-1794564842633-1",
                                        "mediaUrl": "https://media.w3.org/2010/05/bunny/trailer.mp4",
                                        "type": "VIDEO",
                                        "duration": 10,
                                        "sortOrder": 1,
                                        "stickerType": null,
                                        "stickerData": null
                                    }
                                ]
                            }
                        ]
                    },
                    {
                        "userId": "user-4",
                        "author": {
                            "id": "user-4",
                            "username": "trangphan4",
                            "fullName": "Trang Phan",
                            "avatarUrl": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&auto=format&fit=crop&crop=faces&q=80",
                            "isVerified": false
                        },
                        "stories": [
                            {
                                "id": "story-user-4-1794564841523",
                                "createdAt": "2026-11-13T03:14:01.558Z",
                                "expiresAt": "2026-11-14T03:14:01.523Z",
                                "audience": "followers",
                                "items": [
                                    {
                                        "id": "story-item-story-user-4-1794564841523-0",
                                        "mediaUrl": "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=1080&h=1920&auto=format&fit=crop&q=80",
                                        "type": "IMAGE",
                                        "duration": 5,
                                        "sortOrder": 0,
                                        "stickerType": null,
                                        "stickerData": null
                                    },
                                    {
                                        "id": "story-item-story-user-4-1794564841523-1",
                                        "mediaUrl": "https://vjs.zencdn.net/v/oceans.mp4",
                                        "type": "VIDEO",
                                        "duration": 10,
                                        "sortOrder": 1,
                                        "stickerType": null,
                                        "stickerData": null
                                    }
                                ]
                            }
                        ]
                    },
                    {
                        "userId": "user-3",
                        "author": {
                            "id": "user-3",
                            "username": "ngochua3",
                            "fullName": "Ngoc Hua",
                            "avatarUrl": "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&auto=format&fit=crop&crop=faces&q=80",
                            "isVerified": false
                        },
                        "stories": [
                            {
                                "id": "story-user-3-1794564841323",
                                "createdAt": "2026-11-13T03:14:01.358Z",
                                "expiresAt": "2026-11-14T03:14:01.323Z",
                                "audience": "followers",
                                "items": [
                                    {
                                        "id": "story-item-story-user-3-1794564841323-0",
                                        "mediaUrl": "https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=1080&h=1920&auto=format&fit=crop&q=80",
                                        "type": "IMAGE",
                                        "duration": 5,
                                        "sortOrder": 0,
                                        "stickerType": null,
                                        "stickerData": null
                                    }
                                ]
                            }
                        ]
                    }
                ]
            }
        }
        """.data(using: .utf8)!

        let clock = ContinuousClock()
        let start = clock.now
        let envelope = try decoder.decode(APIEnvelope<StoriesFeedDTO>.self, from: json)
        guard let feedDTO = envelope.data else {
            XCTFail("Expected data in APIEnvelope")
            return
        }

        let stories = StoryMapper.toEntityList(feedDTO.items)
        let elapsed = clock.now - start

        XCTAssertEqual(stories.count, 3, "Expected 3 flattened stories from 3 user groups")

        // First user: mylam10
        let story0 = stories[0]
        XCTAssertEqual(story0.id, "story-user-10-1794564842633")
        XCTAssertEqual(story0.author.id, "user-10")
        XCTAssertEqual(story0.author.username, "mylam10")
        XCTAssertEqual(story0.author.fullName, "My Lam")
        XCTAssertEqual(story0.items.count, 2)
        XCTAssertEqual(story0.items[0].type, .image)
        XCTAssertEqual(story0.items[0].duration, 5.0)
        XCTAssertEqual(story0.items[1].type, .video)
        XCTAssertEqual(story0.items[1].duration, 10.0)

        // Second user: trangphan4
        let story1 = stories[1]
        XCTAssertEqual(story1.id, "story-user-4-1794564841523")
        XCTAssertEqual(story1.author.id, "user-4")
        XCTAssertEqual(story1.author.username, "trangphan4")
        XCTAssertEqual(story1.items.count, 2)

        // Third user: ngochua3
        let story2 = stories[2]
        XCTAssertEqual(story2.id, "story-user-3-1794564841323")
        XCTAssertEqual(story2.author.id, "user-3")
        XCTAssertEqual(story2.author.username, "ngochua3")
        XCTAssertEqual(story2.items.count, 1)

        print("⏱️ [Benchmark] StoriesFeedDTO decode & map took: \(elapsed)")
    }

    func testStoriesFeedDecoding_WithFlatFallbackPayload() throws {
        let json = """
        {
            "items": [
                {
                    "id": "story-flat-1",
                    "authorId": "user-flat-1",
                    "createdAt": "2026-11-13T10:00:00.000Z",
                    "expiresAt": "2026-11-14T10:00:00.000Z",
                    "audience": "public",
                    "author": {
                        "id": "user-flat-1",
                        "username": "flat_user"
                    },
                    "items": [
                        {
                            "id": "item-1",
                            "mediaUrl": "https://example.com/pic.jpg",
                            "type": "IMAGE",
                            "duration": 5.0
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!

        let feedDTO = try decoder.decode(StoriesFeedDTO.self, from: json)
        let stories = StoryMapper.toEntityList(feedDTO.items)

        XCTAssertEqual(stories.count, 1)
        XCTAssertEqual(stories[0].author.username, "flat_user")
        XCTAssertEqual(stories[0].items.count, 1)
    }

    func testStoryItemDecoding_FlexibleDurationAndFallback() throws {
        let jsonIntDuration = """
        {
            "id": "item-int",
            "mediaUrl": "https://example.com/int.jpg",
            "type": "IMAGE",
            "duration": 7
        }
        """.data(using: .utf8)!

        let itemInt = try decoder.decode(StoryItemDTO.self, from: jsonIntDuration)
        XCTAssertEqual(itemInt.duration, 7.0)
        XCTAssertNil(itemInt.createdAt)

        let jsonStringDuration = """
        {
            "id": "item-str",
            "mediaUrl": "https://example.com/str.jpg",
            "type": "VIDEO",
            "duration": "14.5"
        }
        """.data(using: .utf8)!

        let itemStr = try decoder.decode(StoryItemDTO.self, from: jsonStringDuration)
        XCTAssertEqual(itemStr.duration, 14.5)
    }

    // MARK: - 10. Paginated Comments Dual Cursor & Offset Tests

    func testPaginatedCommentsDecoding_WithRealCursorBackendPayload() throws {
        let json = """
        {
            "success": true,
            "data": {
                "items": [],
                "nextCursor": null,
                "hasMore": false
            }
        }
        """.data(using: .utf8)!

        let clock = ContinuousClock()
        let start = clock.now
        let envelope = try decoder.decode(APIEnvelope<PaginatedCommentsDTO>.self, from: json)
        guard let data = envelope.data else {
            XCTFail("Expected data in APIEnvelope")
            return
        }

        let comments = CommentMapper.toEntityList(data.items)
        let elapsed = clock.now - start

        XCTAssertTrue(comments.isEmpty)
        XCTAssertEqual(data.hasMore, false)
        XCTAssertNil(data.nextCursor)
        XCTAssertEqual(data.page, 1)
        XCTAssertEqual(data.perPage, 20)
        XCTAssertEqual(data.total, 0)

        print("⏱️ [Benchmark] PaginatedCommentsDTO empty cursor decode took: \(elapsed)")
    }

    func testPaginatedCommentsDecoding_WithPopulatedCursorPayload() throws {
        let json = """
        {
            "success": true,
            "data": {
                "items": [
                    {
                        "id": "comment-post-mylam-1",
                        "commentableType": "POST",
                        "commentableId": "post-mylam-2",
                        "authorId": "user-8",
                        "text": "Stunning shot! Love the colors.",
                        "parentId": null,
                        "likesCount": 5,
                        "repliesCount": 1,
                        "createdAt": "2026-11-13T10:00:00.000Z",
                        "author": {
                            "id": "user-8",
                            "username": "tuanduong8",
                            "fullName": "Tuan Duong",
                            "avatarUrl": "https://picsum.photos/seed/tuanduong8/400/400",
                            "isVerified": true,
                            "isFollowing": false
                        },
                        "isLiked": false
                    }
                ],
                "nextCursor": "cursor_comment_token_999",
                "hasMore": true
            }
        }
        """.data(using: .utf8)!

        let clock = ContinuousClock()
        let start = clock.now
        let envelope = try decoder.decode(APIEnvelope<PaginatedCommentsDTO>.self, from: json)
        guard let data = envelope.data else {
            XCTFail("Expected data in APIEnvelope")
            return
        }

        let comments = CommentMapper.toEntityList(data.items)
        let elapsed = clock.now - start

        XCTAssertEqual(comments.count, 1)
        let comment = comments[0]
        XCTAssertEqual(comment.id, "comment-post-mylam-1")
        XCTAssertEqual(comment.commentableType, .post)
        XCTAssertEqual(comment.commentableId, "post-mylam-2")
        XCTAssertEqual(comment.text, "Stunning shot! Love the colors.")
        XCTAssertEqual(comment.author.username, "tuanduong8")
        XCTAssertEqual(comment.likesCount, 5)
        XCTAssertEqual(comment.repliesCount, 1)
        XCTAssertEqual(data.hasMore, true)
        XCTAssertEqual(data.nextCursor, "cursor_comment_token_999")
        XCTAssertEqual(data.total, 1)

        print("⏱️ [Benchmark] PaginatedCommentsDTO populated cursor decode & map took: \(elapsed)")
    }

    func testPaginatedCommentsDecoding_WithLegacyOffsetPayload() throws {
        let json = """
        {
            "items": [
                {
                    "id": "comment-offset-1",
                    "text": "Legacy offset comment",
                    "likesCount": 2,
                    "createdAt": "2026-11-13T09:00:00.000Z",
                    "author": {
                        "id": "user-9",
                        "username": "user9"
                    }
                }
            ],
            "page": 2,
            "perPage": 15,
            "total": 45,
            "hasMore": true
        }
        """.data(using: .utf8)!

        let dto = try decoder.decode(PaginatedCommentsDTO.self, from: json)
        let comments = CommentMapper.toEntityList(dto.items)

        XCTAssertEqual(comments.count, 1)
        XCTAssertEqual(dto.page, 2)
        XCTAssertEqual(dto.perPage, 15)
        XCTAssertEqual(dto.total, 45)
        XCTAssertEqual(dto.hasMore, true)
    }
}
