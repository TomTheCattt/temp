# API Response Reference

Base URL: `http://localhost:3000`

All authenticated endpoints require header: `Authorization: Bearer <Firebase ID Token>`

Pagination query params: `?page=1&perPage=20` (max 50)

---

## Health Check

### GET /health

```json
{
  "success": true,
  "data": {
    "status": "ok",
    "timestamp": "2026-08-04T14:37:10.661Z"
  }
}
```

---

## Auth

### POST /v1/auth/register

**Body:**
```json
{
  "idToken": "eyJhbGci...",
  "name": "John Doe",
  "phone": "+84901234567"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "ddc20ee7-c705-4622-8431-deaff120408b",
      "firebaseUid": "SPrBlqwAx0VPklWeuYtVre1EHOD3",
      "username": "john_doe_1234",
      "fullName": "John Doe",
      "email": "john@example.com",
      "phone": "+84901234567",
      "avatarUrl": null,
      "bio": null,
      "website": null,
      "isVerified": false,
      "isPrivate": false,
      "postsCount": 0,
      "followersCount": 0,
      "followingCount": 0,
      "createdAt": "2026-08-04T14:37:10.661Z",
      "updatedAt": "2026-08-04T14:37:10.661Z"
    }
  }
}
```

### POST /v1/auth/login

**Body:**
```json
{
  "idToken": "eyJhbGci..."
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "ddc20ee7-c705-4622-8431-deaff120408b",
      "firebaseUid": "SPrBlqwAx0VPklWeuYtVre1EHOD3",
      "username": "dev_user",
      "fullName": "Dev User",
      "email": "dev@example.com",
      "phone": null,
      "avatarUrl": "https://i.pravatar.cc/400?u=dev_user",
      "bio": "Development account",
      "website": null,
      "isVerified": false,
      "isPrivate": false,
      "postsCount": 0,
      "followersCount": 4,
      "followingCount": 4,
      "createdAt": "2026-08-04T14:37:10.661Z",
      "updatedAt": "2026-08-04T14:37:10.874Z"
    }
  }
}
```

### POST /v1/auth/refresh

**Body:**
```json
{
  "refreshToken": "AMf-vBxV..."
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "idToken": "eyJhbGci...",
    "refreshToken": "AMf-vBxV...",
    "expiresIn": "3600"
  }
}
```

### POST /v1/auth/logout-all-devices

**Response (204):** No content

### POST /v1/auth/change-password

**Response (200):**
```json
{
  "success": true,
  "message": "Use Firebase Auth SDK updatePassword() on the client side"
}
```

---

## Users

### GET /v1/users/me

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "ddc20ee7-c705-4622-8431-deaff120408b",
      "username": "dev_user",
      "fullName": "Dev User",
      "avatarUrl": "https://i.pravatar.cc/400?u=dev_user",
      "bio": "Development account",
      "website": null,
      "isVerified": false,
      "isPrivate": false,
      "postsCount": 2,
      "followersCount": 4,
      "followingCount": 4,
      "isFollowing": false,
      "isFollowedBy": false
    }
  }
}
```

### PUT /v1/users/me

**Body:**
```json
{
  "fullName": "New Name",
  "bio": "Updated bio",
  "website": "https://example.com",
  "isPrivate": false
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "ddc20ee7-c705-4622-8431-deaff120408b",
      "username": "dev_user",
      "fullName": "New Name",
      "avatarUrl": "https://i.pravatar.cc/400?u=dev_user",
      "bio": "Updated bio",
      "website": "https://example.com",
      "isVerified": false,
      "isPrivate": false,
      "postsCount": 2,
      "followersCount": 4,
      "followingCount": 4
    }
  }
}
```

### GET /v1/users/:id

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "abc123",
      "username": "alice",
      "fullName": "Alice Nguyen",
      "avatarUrl": "https://i.pravatar.cc/400?u=alice",
      "bio": "Photography enthusiast",
      "website": null,
      "isVerified": false,
      "isPrivate": false,
      "postsCount": 10,
      "followersCount": 15,
      "followingCount": 12,
      "isFollowing": true,
      "isFollowedBy": false
    }
  }
}
```

### GET /v1/users/search?q=alice&page=1&perPage=20

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "abc123",
        "username": "alice",
        "fullName": "Alice Nguyen",
        "avatarUrl": "https://i.pravatar.cc/400?u=alice",
        "bio": "Photography enthusiast",
        "website": null,
        "isVerified": false,
        "isPrivate": false,
        "postsCount": 10,
        "followersCount": 15,
        "followingCount": 12
      }
    ],
    "page": 1,
    "perPage": 20,
    "total": 1,
    "hasMore": false
  }
}
```

### GET /v1/users/suggested?page=1&perPage=20

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "xyz789",
        "username": "emma",
        "fullName": "Emma Vo",
        "avatarUrl": "https://i.pravatar.cc/400?u=emma",
        "bio": "Living one day at a time",
        "website": null,
        "isVerified": false,
        "isPrivate": false,
        "postsCount": 8,
        "followersCount": 20,
        "followingCount": 10
      }
    ],
    "page": 1,
    "perPage": 20,
    "total": 15,
    "hasMore": false
  }
}
```

### GET /v1/users/:id/followers?page=1&perPage=20

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "abc123",
        "username": "bob",
        "fullName": "Bob Tran",
        "avatarUrl": "https://i.pravatar.cc/400?u=bob",
        "bio": "Developer by day",
        "website": null,
        "isVerified": false,
        "isPrivate": false,
        "postsCount": 5,
        "followersCount": 10,
        "followingCount": 8
      }
    ],
    "page": 1,
    "perPage": 20,
    "total": 4,
    "hasMore": false
  }
}
```

### GET /v1/users/:id/following?page=1&perPage=20

Same structure as followers.

### POST /v1/users/:id/follow

**Response (204):** No content

### DELETE /v1/users/:id/follow

**Response (204):** No content

### POST /v1/users/:id/block

**Response (204):** No content

### DELETE /v1/users/:id/block

**Response (204):** No content

### POST /v1/users/me/device-token

**Body:**
```json
{
  "token": "fcm-device-token-string",
  "platform": "IOS"
}
```

**Response (204):** No content

### DELETE /v1/users/me/device-token

**Body:**
```json
{
  "token": "fcm-device-token-string"
}
```

**Response (204):** No content

---

## Posts

### GET /v1/posts/feed?page=1&perPage=20

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "10000000-0000-4000-8000-000000000001",
        "authorId": "abc123",
        "caption": "A calm morning in Da Nang ☀️",
        "locationName": null,
        "locationLat": null,
        "locationLng": null,
        "likesCount": 15,
        "commentsCount": 3,
        "isSponsored": false,
        "createdAt": "2026-07-15T08:30:00.000Z",
        "updatedAt": "2026-07-15T08:30:00.000Z",
        "author": {
          "id": "abc123",
          "username": "alice",
          "fullName": "Alice Nguyen",
          "avatarUrl": "https://i.pravatar.cc/400?u=alice",
          "isVerified": false,
          "isPrivate": false
        },
        "mediaItems": [
          {
            "id": "media-uuid-1",
            "postId": "10000000-0000-4000-8000-000000000001",
            "url": "https://picsum.photos/seed/post-1-0/1080/1350",
            "thumbnailUrl": null,
            "type": "IMAGE",
            "width": 1080,
            "height": 1350,
            "duration": null,
            "sortOrder": 0
          }
        ],
        "isLiked": true,
        "isSaved": false
      }
    ],
    "page": 1,
    "perPage": 20,
    "total": 50,
    "hasMore": true
  }
}
```

### GET /v1/posts/explore?page=1&perPage=30

Same structure as feed (sorted by likesCount desc).

### GET /v1/posts/saved?page=1&perPage=20

Same structure as feed (isSaved is always true).

### GET /v1/posts/user/:userId?page=1&perPage=20

Same structure as feed.

### GET /v1/posts/:id

**Response (200):**
```json
{
  "success": true,
  "data": {
    "post": {
      "id": "10000000-0000-4000-8000-000000000001",
      "authorId": "abc123",
      "caption": "A calm morning in Da Nang ☀️",
      "locationName": null,
      "locationLat": null,
      "locationLng": null,
      "likesCount": 15,
      "commentsCount": 3,
      "isSponsored": false,
      "createdAt": "2026-07-15T08:30:00.000Z",
      "updatedAt": "2026-07-15T08:30:00.000Z",
      "author": {
        "id": "abc123",
        "username": "alice",
        "fullName": "Alice Nguyen",
        "avatarUrl": "https://i.pravatar.cc/400?u=alice",
        "isVerified": false,
        "isPrivate": false
      },
      "mediaItems": [
        {
          "id": "media-uuid-1",
          "postId": "10000000-0000-4000-8000-000000000001",
          "url": "https://picsum.photos/seed/post-1-0/1080/1350",
          "thumbnailUrl": null,
          "type": "IMAGE",
          "width": 1080,
          "height": 1350,
          "duration": null,
          "sortOrder": 0
        },
        {
          "id": "media-uuid-2",
          "postId": "10000000-0000-4000-8000-000000000001",
          "url": "https://picsum.photos/seed/post-1-1/1080/1080",
          "thumbnailUrl": null,
          "type": "IMAGE",
          "width": 1080,
          "height": 1080,
          "duration": null,
          "sortOrder": 1
        }
      ],
      "isLiked": true,
      "isSaved": false
    }
  }
}
```

### POST /v1/posts

**Body:**
```json
{
  "caption": "Beautiful sunset 🌅",
  "locationName": "Da Nang Beach",
  "locationLat": 16.0544,
  "locationLng": 108.2022,
  "media": [
    {
      "url": "https://storage.example.com/uploads/user-id/image.jpg",
      "type": "IMAGE",
      "width": 1080,
      "height": 1350,
      "pendingUploadId": "upload-uuid"
    }
  ]
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "post": {
      "id": "new-post-uuid",
      "authorId": "user-uuid",
      "caption": "Beautiful sunset 🌅",
      "locationName": "Da Nang Beach",
      "locationLat": 16.0544,
      "locationLng": 108.2022,
      "likesCount": 0,
      "commentsCount": 0,
      "isSponsored": false,
      "createdAt": "2026-08-04T15:00:00.000Z",
      "updatedAt": "2026-08-04T15:00:00.000Z",
      "author": {
        "id": "user-uuid",
        "username": "dev_user",
        "fullName": "Dev User",
        "avatarUrl": "https://i.pravatar.cc/400?u=dev_user",
        "isVerified": false,
        "isPrivate": false
      },
      "mediaItems": [
        {
          "id": "media-uuid",
          "postId": "new-post-uuid",
          "url": "https://storage.example.com/uploads/user-id/image.jpg",
          "thumbnailUrl": null,
          "type": "IMAGE",
          "width": 1080,
          "height": 1350,
          "duration": null,
          "sortOrder": 0
        }
      ]
    }
  }
}
```

### DELETE /v1/posts/:id

**Response (204):** No content

### POST /v1/posts/:id/like

**Response (204):** No content

### DELETE /v1/posts/:id/like

**Response (204):** No content

### POST /v1/posts/:id/save

**Response (204):** No content

### DELETE /v1/posts/:id/save

**Response (204):** No content

---

## Comments

### GET /v1/posts/:postId/comments?page=1&perPage=20

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "20000000-0000-4000-8000-000000000001",
        "postId": "10000000-0000-4000-8000-000000000001",
        "authorId": "abc123",
        "text": "Looks wonderful! 😍",
        "parentId": null,
        "likesCount": 2,
        "createdAt": "2026-07-15T09:00:00.000Z",
        "author": {
          "id": "abc123",
          "username": "bob",
          "fullName": "Bob Tran",
          "avatarUrl": "https://i.pravatar.cc/400?u=bob",
          "isVerified": false
        },
        "replies": [
          {
            "id": "20000000-0000-4000-8000-000000000002",
            "postId": "10000000-0000-4000-8000-000000000001",
            "authorId": "def456",
            "text": "Agreed! 🙌",
            "parentId": "20000000-0000-4000-8000-000000000001",
            "likesCount": 0,
            "createdAt": "2026-07-15T09:05:00.000Z",
            "author": {
              "id": "def456",
              "username": "carol",
              "fullName": "Carol Le",
              "avatarUrl": "https://i.pravatar.cc/400?u=carol",
              "isVerified": false
            }
          }
        ]
      }
    ],
    "page": 1,
    "perPage": 20,
    "total": 5,
    "hasMore": false
  }
}
```

### POST /v1/posts/:postId/comments

**Body:**
```json
{
  "text": "Amazing photo!",
  "parentId": "optional-comment-uuid-for-reply"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "comment": {
      "id": "new-comment-uuid",
      "postId": "post-uuid",
      "authorId": "user-uuid",
      "text": "Amazing photo!",
      "parentId": null,
      "likesCount": 0,
      "createdAt": "2026-08-04T15:00:00.000Z",
      "author": {
        "id": "user-uuid",
        "username": "dev_user",
        "fullName": "Dev User",
        "avatarUrl": "https://i.pravatar.cc/400?u=dev_user",
        "isVerified": false
      },
      "replies": []
    }
  }
}
```

### DELETE /v1/posts/:postId/comments/:commentId

**Response (204):** No content

### POST /v1/posts/:postId/comments/:commentId/like

**Response (204):** No content

### DELETE /v1/posts/:postId/comments/:commentId/like

**Response (204):** No content

---

## Stories

### GET /v1/stories/feed

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "40000000-0000-4000-8000-000000000001",
        "authorId": "abc123",
        "createdAt": "2026-08-04T06:00:00.000Z",
        "expiresAt": "2026-08-05T06:00:00.000Z",
        "author": {
          "id": "abc123",
          "username": "alice",
          "avatarUrl": "https://i.pravatar.cc/400?u=alice"
        },
        "items": [
          {
            "id": "story-item-uuid-1",
            "storyId": "40000000-0000-4000-8000-000000000001",
            "mediaUrl": "https://picsum.photos/seed/story-1-0/1080/1350",
            "type": "IMAGE",
            "duration": 5,
            "sortOrder": 0,
            "stickerType": null,
            "stickerData": null,
            "createdAt": "2026-08-04T06:00:00.000Z"
          }
        ],
        "views": []
      }
    ]
  }
}
```

Note: `views` array contains `{ "id": "..." }` if current user has viewed the story.

### GET /v1/stories/:userId/items

**Response (200):**
```json
{
  "success": true,
  "data": {
    "stories": [
      {
        "id": "40000000-0000-4000-8000-000000000001",
        "authorId": "abc123",
        "createdAt": "2026-08-04T06:00:00.000Z",
        "expiresAt": "2026-08-05T06:00:00.000Z",
        "items": [
          {
            "id": "story-item-uuid-1",
            "storyId": "40000000-0000-4000-8000-000000000001",
            "mediaUrl": "https://picsum.photos/seed/story-1-0/1080/1350",
            "type": "IMAGE",
            "duration": 5,
            "sortOrder": 0,
            "stickerType": null,
            "stickerData": null,
            "createdAt": "2026-08-04T06:00:00.000Z"
          }
        ],
        "views": []
      }
    ]
  }
}
```

### POST /v1/stories

**Body:**
```json
{
  "mediaUrl": "https://storage.example.com/uploads/user-id/story.jpg",
  "type": "IMAGE",
  "duration": 5,
  "stickerType": "poll",
  "stickerData": "{\"question\":\"Yes or No?\"}"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "story": {
      "id": "new-story-uuid",
      "authorId": "user-uuid",
      "createdAt": "2026-08-04T15:00:00.000Z",
      "expiresAt": "2026-08-05T15:00:00.000Z",
      "items": [
        {
          "id": "story-item-uuid",
          "storyId": "new-story-uuid",
          "mediaUrl": "https://storage.example.com/uploads/user-id/story.jpg",
          "type": "IMAGE",
          "duration": 5,
          "sortOrder": 0,
          "stickerType": "poll",
          "stickerData": "{\"question\":\"Yes or No?\"}",
          "createdAt": "2026-08-04T15:00:00.000Z"
        }
      ]
    }
  }
}
```

### POST /v1/stories/:storyId/view

**Response (204):** No content

### DELETE /v1/stories/:storyId

**Response (204):** No content

---

## Reels

### GET /v1/reels/feed?page=1&perPage=10

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "30000000-0000-4000-8000-000000000001",
        "authorId": "abc123",
        "videoUrl": "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        "thumbnailUrl": "https://picsum.photos/seed/reel-1/1080/1350",
        "caption": "Day in the life 🎬",
        "audioName": null,
        "audioArtist": null,
        "audioCoverUrl": null,
        "isOriginalAudio": true,
        "duration": 30,
        "likesCount": 45,
        "commentsCount": 0,
        "sharesCount": 0,
        "viewsCount": 1200,
        "createdAt": "2026-07-20T10:00:00.000Z",
        "author": {
          "id": "abc123",
          "username": "alice",
          "avatarUrl": "https://i.pravatar.cc/400?u=alice"
        },
        "isLiked": false
      }
    ],
    "page": 1,
    "perPage": 10,
    "total": 60,
    "hasMore": true
  }
}
```

### POST /v1/reels

**Body:**
```json
{
  "videoUrl": "https://storage.example.com/uploads/user-id/reel.mp4",
  "thumbnailUrl": "https://storage.example.com/uploads/user-id/reel_thumb.jpg",
  "caption": "New reel! 🎬",
  "duration": 15,
  "audioName": "Original Sound",
  "audioArtist": "dev_user"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "reel": {
      "id": "new-reel-uuid",
      "authorId": "user-uuid",
      "videoUrl": "https://storage.example.com/uploads/user-id/reel.mp4",
      "thumbnailUrl": "https://storage.example.com/uploads/user-id/reel_thumb.jpg",
      "caption": "New reel! 🎬",
      "audioName": "Original Sound",
      "audioArtist": "dev_user",
      "audioCoverUrl": null,
      "isOriginalAudio": true,
      "duration": 15,
      "likesCount": 0,
      "commentsCount": 0,
      "sharesCount": 0,
      "viewsCount": 0,
      "createdAt": "2026-08-04T15:00:00.000Z",
      "author": {
        "id": "user-uuid",
        "username": "dev_user",
        "avatarUrl": "https://i.pravatar.cc/400?u=dev_user"
      }
    }
  }
}
```

### POST /v1/reels/:id/like

**Response (204):** No content

### DELETE /v1/reels/:id/like

**Response (204):** No content

### POST /v1/reels/:id/view

**Response (204):** No content

---

## Conversations & Messages

### GET /v1/conversations?page=1&perPage=20

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "50000000-0000-4000-8000-000000000001",
        "isGroup": false,
        "groupName": null,
        "groupAvatar": null,
        "createdAt": "2026-08-01T10:00:00.000Z",
        "updatedAt": "2026-08-04T14:00:00.000Z",
        "members": [
          {
            "id": "member-uuid-1",
            "conversationId": "50000000-0000-4000-8000-000000000001",
            "userId": "user-uuid-1",
            "isMuted": false,
            "lastReadAt": "2026-08-04T14:00:00.000Z",
            "joinedAt": "2026-08-01T10:00:00.000Z",
            "user": {
              "id": "user-uuid-1",
              "username": "dev_user",
              "fullName": "Dev User",
              "avatarUrl": "https://i.pravatar.cc/400?u=dev_user"
            }
          },
          {
            "id": "member-uuid-2",
            "conversationId": "50000000-0000-4000-8000-000000000001",
            "userId": "user-uuid-2",
            "isMuted": false,
            "lastReadAt": null,
            "joinedAt": "2026-08-01T10:00:00.000Z",
            "user": {
              "id": "user-uuid-2",
              "username": "alice",
              "fullName": "Alice Nguyen",
              "avatarUrl": "https://i.pravatar.cc/400?u=alice"
            }
          }
        ],
        "messages": [
          {
            "id": "60000000-0000-4000-8000-000000000010",
            "conversationId": "50000000-0000-4000-8000-000000000001",
            "senderId": "user-uuid-2",
            "contentType": "TEXT",
            "textContent": "See you tomorrow!",
            "mediaUrl": null,
            "mediaThumbnail": null,
            "mediaDuration": null,
            "referenceId": null,
            "replyToId": null,
            "status": "SENT",
            "createdAt": "2026-08-04T14:00:00.000Z"
          }
        ]
      }
    ],
    "page": 1,
    "perPage": 20,
    "total": 5,
    "hasMore": false
  }
}
```

### POST /v1/conversations

**Body:**
```json
{
  "participantIds": ["user-uuid-2", "user-uuid-3"],
  "groupName": "My Group Chat"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "conversation": {
      "id": "new-conversation-uuid",
      "isGroup": true,
      "groupName": "My Group Chat",
      "groupAvatar": null,
      "createdAt": "2026-08-04T15:00:00.000Z",
      "updatedAt": "2026-08-04T15:00:00.000Z",
      "members": [
        {
          "id": "member-uuid",
          "conversationId": "new-conversation-uuid",
          "userId": "user-uuid",
          "isMuted": false,
          "lastReadAt": null,
          "joinedAt": "2026-08-04T15:00:00.000Z",
          "user": {
            "id": "user-uuid",
            "username": "dev_user",
            "fullName": "Dev User",
            "avatarUrl": "https://i.pravatar.cc/400?u=dev_user"
          }
        }
      ]
    }
  }
}
```

### GET /v1/conversations/:id/messages?page=1&perPage=20

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "60000000-0000-4000-8000-000000000001",
        "conversationId": "50000000-0000-4000-8000-000000000001",
        "senderId": "user-uuid",
        "contentType": "TEXT",
        "textContent": "Hey! How are you?",
        "mediaUrl": null,
        "mediaThumbnail": null,
        "mediaDuration": null,
        "referenceId": null,
        "replyToId": null,
        "status": "SENT",
        "createdAt": "2026-08-04T12:00:00.000Z",
        "sender": {
          "id": "user-uuid",
          "username": "dev_user",
          "avatarUrl": "https://i.pravatar.cc/400?u=dev_user"
        }
      }
    ],
    "page": 1,
    "perPage": 20,
    "total": 30,
    "hasMore": true
  }
}
```

### POST /v1/conversations/:id/messages

**Body:**
```json
{
  "contentType": "TEXT",
  "textContent": "Hello!",
  "replyToId": "optional-message-uuid"
}
```

Or for media:
```json
{
  "contentType": "IMAGE",
  "mediaUrl": "https://storage.example.com/uploads/user-id/photo.jpg",
  "mediaThumbnail": "https://storage.example.com/uploads/user-id/photo_thumb.jpg"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "message": {
      "id": "new-message-uuid",
      "conversationId": "conversation-uuid",
      "senderId": "user-uuid",
      "contentType": "TEXT",
      "textContent": "Hello!",
      "mediaUrl": null,
      "mediaThumbnail": null,
      "mediaDuration": null,
      "referenceId": null,
      "replyToId": null,
      "status": "SENT",
      "createdAt": "2026-08-04T15:00:00.000Z",
      "sender": {
        "id": "user-uuid",
        "username": "dev_user",
        "avatarUrl": "https://i.pravatar.cc/400?u=dev_user"
      }
    }
  }
}
```

**ContentType enum:** `TEXT`, `IMAGE`, `VIDEO`, `AUDIO`, `POST`, `STORY`, `REEL`, `LIKE`

### POST /v1/conversations/:id/read

**Response (204):** No content

### PUT /v1/conversations/:id/mute

**Body:**
```json
{
  "mute": true
}
```

**Response (204):** No content

### DELETE /v1/conversations/messages/:messageId

**Response (204):** No content

---

## Notifications

### GET /v1/notifications?page=1&perPage=20

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "notification-uuid",
        "recipientId": "user-uuid",
        "actorId": "actor-uuid",
        "type": "LIKE",
        "postId": "10000000-0000-4000-8000-000000000001",
        "commentText": null,
        "isRead": false,
        "createdAt": "2026-08-04T12:00:00.000Z",
        "actor": {
          "id": "actor-uuid",
          "username": "alice",
          "fullName": "Alice Nguyen",
          "avatarUrl": "https://i.pravatar.cc/400?u=alice"
        }
      },
      {
        "id": "notification-uuid-2",
        "recipientId": "user-uuid",
        "actorId": "actor-uuid-2",
        "type": "COMMENT",
        "postId": "10000000-0000-4000-8000-000000000002",
        "commentText": "Great photo!",
        "isRead": true,
        "createdAt": "2026-08-03T18:00:00.000Z",
        "actor": {
          "id": "actor-uuid-2",
          "username": "bob",
          "fullName": "Bob Tran",
          "avatarUrl": "https://i.pravatar.cc/400?u=bob"
        }
      },
      {
        "id": "notification-uuid-3",
        "recipientId": "user-uuid",
        "actorId": "actor-uuid-3",
        "type": "FOLLOW",
        "postId": null,
        "commentText": null,
        "isRead": false,
        "createdAt": "2026-08-03T10:00:00.000Z",
        "actor": {
          "id": "actor-uuid-3",
          "username": "carol",
          "fullName": "Carol Le",
          "avatarUrl": "https://i.pravatar.cc/400?u=carol"
        }
      }
    ],
    "page": 1,
    "perPage": 20,
    "total": 25,
    "hasMore": true
  }
}
```

**NotificationType enum:** `LIKE`, `COMMENT`, `FOLLOW`, `FOLLOW_REQUEST`, `MENTION`, `TAGGED_IN_POST`, `STORY_MENTION`, `LIVE_VIDEO`

### GET /v1/notifications/unread-count

**Response (200):**
```json
{
  "success": true,
  "data": {
    "count": 12
  }
}
```

### POST /v1/notifications/read-all

**Response (204):** No content

### POST /v1/notifications/:id/read

**Response (204):** No content

---

## Upload

### POST /v1/upload/image

**Body:** `multipart/form-data` with field `file` (max 10MB, jpeg/png/webp/heic)

**Response (201):**
```json
{
  "success": true,
  "data": {
    "url": "https://storage.googleapis.com/bucket/uploads/user-id/uuid.jpg",
    "width": 1080,
    "height": 1350,
    "pendingUploadId": "pending-upload-uuid"
  }
}
```

### POST /v1/upload/video

**Body:** `multipart/form-data` with field `file` (max 100MB, mp4/mov/quicktime)

**Response (201):**
```json
{
  "success": true,
  "data": {
    "url": "https://storage.googleapis.com/bucket/uploads/user-id/uuid.mp4",
    "thumbnailUrl": "https://storage.googleapis.com/bucket/uploads/user-id/uuid_thumb.jpg",
    "duration": 15.5,
    "width": 1080,
    "height": 1920,
    "pendingUploadId": "pending-upload-uuid"
  }
}
```

### POST /v1/upload/avatar

**Body:** `multipart/form-data` with field `file` (max 10MB, jpeg/png/webp/heic)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "url": "https://storage.googleapis.com/bucket/avatars/user-id/avatar.jpg"
  }
}
```

---

## Error Responses

All errors follow this format:

```json
{
  "success": false,
  "error": "ERROR_CODE",
  "message": "Human readable message"
}
```

Common error codes:

| Status | Error Code | Description |
|--------|-----------|-------------|
| 401 | UNAUTHORIZED | No token / invalid token / expired token |
| 401 | SESSION_REVOKED | Token revoked, re-login required |
| 403 | FORBIDDEN | No permission for this action |
| 404 | NOT_FOUND | Resource not found |
| 409 | CONFLICT | Duplicate action (e.g. already registered) |
| 422 | VALIDATION_ERROR | Request body validation failed |
| 429 | TOO_MANY_REQUESTS | Rate limit exceeded |
| 503 | SERVICE_UNAVAILABLE | Firebase not configured |

---

## WebSocket

Connect to: `ws://localhost:3000` with query `?token=<Firebase ID Token>`

**Incoming events:**

```json
{
  "type": "new_message",
  "message": { /* same as message object above */ }
}
```

```json
{
  "type": "new_notification",
  "notification": { /* same as notification object above */ }
}
```
