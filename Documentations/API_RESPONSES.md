# API Response Reference

**Base URL:** `http://localhost:3000` (configurable via `AppConfig.baseURL`)

**Authentication:** All authenticated endpoints require header: `Authorization: Bearer <Better Auth Access Token>`

> **Important:** The client uses **Better Auth tokens** (access/refresh tokens issued by backend).
> The backend issues its own JWT access tokens (15 min) and refresh tokens (7 days sliding window).
> The `/v1/auth/refresh` endpoint is called by the client to rotate tokens.

**Response Envelope:** All responses follow the `APIEnvelope<T>` format:
```json
{
  "success": true,
  "data": { ... },
  "error": null,
  "message": null
}
```
Errors: `"success": false, "error": "ERROR_CODE", "message": "Human readable"`

**Pagination:**
- **Cursor-based** (posts feed, explore, saved, reels feed): `?cursor=ISO_TIMESTAMP&perPage=20` — returns `{ items, nextCursor, hasMore }`
- **Page-based** (other endpoints): `?page=1&perPage=20` (max 50) — returns `{ items, page, perPage, total, hasMore }`

**Date Format:** ISO 8601 with fractional seconds (`yyyy-MM-dd'T'HH:mm:ss.SSSZ`)

**Field Naming:** JSON uses **camelCase** (client decodes with `.useDefaultKeys`)

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

## Auth (Better Auth - Email/Password)

### POST /v1/auth/register

Register a new user with email/password.

**Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "username": "john_doe",
  "fullName": "John Doe",
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
      "email": "user@example.com",
      "username": "john_doe",
      "fullName": "John Doe",
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

> **Note:** Better Auth sets tokens in HTTP-only cookies. The client extracts tokens from the `Set-Cookie` headers via `requestEnvelopeWithResponse`.

### POST /v1/auth/login

Sign in with email/password.

**Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "ddc20ee7-c705-4622-8431-deaff120408b",
      "email": "user@example.com",
      "username": "dev_user",
      "fullName": "Dev User",
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

> **Important:** Tokens are returned in HTTP-only cookies (`instagram-clone.access_token`, `instagram-clone.refresh_token`). The client uses `requestEnvelopeWithResponse` to extract them from `Set-Cookie` headers.

### POST /v1/auth/logout

Sign out current session.

**Response (204):** No content

### POST /v1/auth/logout-all-devices

Invalidate all sessions for the current user.

**Response (204):** No content

### GET /v1/auth/me

Get current user profile (requires authentication).

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "ddc20ee7-c705-4622-8431-deaff120408b",
      "email": "dev@example.com",
      "username": "dev_user",
      "fullName": "Dev User",
      "phone": null,
      "avatarUrl": "https://i.pravatar.cc/400?u=dev_user",
      "bio": "Development account",
      "website": null,
      "isVerified": false,
      "isPrivate": false,
      "postsCount": 2,
      "followersCount": 4,
      "followingCount": 4,
      "createdAt": "2026-08-04T14:37:10.661Z",
      "updatedAt": "2026-08-04T14:37:10.874Z"
    }
  }
}
```

### POST /v1/auth/refresh

Refresh access token using refresh token.

**Headers:** `Cookie: instagram-clone.refresh_token=...`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "dGhpcyBpcyBhIHJlZnJl...",  // New refresh token (rotation)
    "expiresAt": 1728123456  // Unix timestamp
  }
}
```

> **Note:** The client calls this automatically via `AuthManager.refreshToken()` when access token is near expiry (5 min buffer). The response is decoded using `.useDefaultKeys`.

### POST /v1/auth/forgot-password

Request password reset email.

**Body:**
```json
{
  "email": "user@example.com"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password reset email sent"
}
```

### POST /v1/auth/verify-email

Verify email with token from verification email.

**Body:**
```json
{
  "token": "verification-token-from-email"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Email verified successfully"
}
```

### POST /v1/auth/resend-verification

Resend email verification link.

**Body:**
```json
{
  "email": "user@example.com"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Verification email sent"
}
```

### POST /v1/auth/change-password

Change password for authenticated user.

**Headers:** `Authorization: Bearer <access_token>`

**Body:**
```json
{
  "currentPassword": "oldPassword123",
  "newPassword": "newSecurePassword456"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

---

## Users

### GET /v1/user/profile

Get current user's full profile (alias for `/v1/users/me`).

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "ddc20ee7-c705-4622-8431-deaff120408b",
      "email": "dev@example.com",
      "username": "dev_user",
      "fullName": "Dev User",
      "phone": null,
      "avatarUrl": "https://i.pravatar.cc/400?u=dev_user",
      "bio": "Development account",
      "website": null,
      "isVerified": false,
      "isPrivate": false,
      "postsCount": 2,
      "followersCount": 4,
      "followingCount": 4,
      "createdAt": "2026-08-04T14:37:10.661Z",
      "updatedAt": "2026-08-04T14:37:10.874Z"
    }
  }
}
```

### PUT /v1/user/profile

Update current user's profile (name only - alias for updating display name).

**Headers:** `Authorization: Bearer <access_token>`

**Body:**
```json
{
  "name": "New Display Name"
}
```

**Response (200):** Same shape as `GET /v1/user/profile` with updated `fullName`.

### PUT /v1/users/me

Update current user's full profile (canonical endpoint).

**Headers:** `Authorization: Bearer <access_token>`

**Body:**
```json
{
  "fullName": "New Full Name",
  "bio": "Updated bio",
  "website": "https://example.com",
  "isPrivate": true
}
```

All fields optional; send only what's being changed.

**Response (200):** Same shape as `GET /v1/user/profile` with updated values.

### GET /v1/user/settings

Get current user's preferences.

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "settings": {
      "language": "en",
      "biometricEnabled": true,
      "pushEnabled": true,
      "darkMode": false
    }
  }
}
```

### PUT /v1/user/settings

Update current user's preferences. All fields optional.

**Headers:** `Authorization: Bearer <access_token>`

**Body:**
```json
{
  "language": "vi",
  "biometricEnabled": false,
  "pushEnabled": true,
  "darkMode": true
}
```

**Response (200):** Same shape as `GET /v1/user/settings` with updated values.

### GET /v1/users/:id

Get public profile of another user.

**Headers:** `Authorization: Bearer <access_token>`

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

Search users by username/full name.

**Headers:** `Authorization: Bearer <access_token>`

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

Get suggested users to follow.

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):** Same structure as `/v1/users/search`.

### GET /v1/users/:id/followers?page=1&perPage=20

Get user's followers (page-based).

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):** Same item shape as `/v1/users/search`.

### GET /v1/users/:id/following?page=1&perPage=20

Get user's following (page-based). Same structure as followers.

### POST /v1/users/:id/follow

Follow a user.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### DELETE /v1/users/:id/follow

Unfollow a user.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### POST /v1/users/:id/block

Block a user.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### DELETE /v1/users/:id/block

Unblock a user.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### GET /v1/user/blocked?page=1&perPage=20

Get list of users blocked by current user (alias for `/v1/users/me/blocked`).

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):** Same item shape as `/v1/users/search`.

---

## Close Friends

### GET /v1/user/close-friends?page=1&perPage=50

Returns the accounts on the current user's Close Friends list (alias for `/v1/users/me/close-friends`).

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):** Same item shape as `/v1/users/search`.

### POST /v1/user/close-friends/:userId

Add a user to Close Friends (alias for `/v1/users/me/close-friends/:userId`).

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### DELETE /v1/user/close-friends/:userId

Remove a user from Close Friends (alias for `/v1/users/me/close-friends/:userId`).

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

---

## Device Tokens

### POST /v1/user/me/device-token

Register FCM/APNs device token for push notifications.

**Headers:** `Authorization: Bearer <access_token>`

**Body:**
```json
{
  "token": "fcm-device-token-string",
  "platform": "IOS"
}
```

**Response (204):** No content

### DELETE /v1/user/me/device-token

Unregister device token.

**Headers:** `Authorization: Bearer <access_token>`

**Body:**
```json
{
  "token": "fcm-device-token-string"
}
```

**Response (204):** No content

> **Note:** BE does not have a GET endpoint for device tokens.

---

## Posts

### GET /v1/posts/feed?cursor=ISO_TIMESTAMP&perPage=20

Get home feed posts (cursor-based pagination).

**Headers:** `Authorization: Bearer <access_token>`

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
    "nextCursor": "2026-07-15T08:30:00.000Z",
    "hasMore": true
  }
}
```

### GET /v1/posts/explore?cursor=ISO_TIMESTAMP&perPage=30

Get explore posts (cursor-based pagination, sorted by engagement).

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):** Same structure as feed.

### GET /v1/posts/saved?cursor=ISO_TIMESTAMP&perPage=20

Get saved posts (cursor-based pagination).

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):** Same structure as feed (isSaved is always true).

### GET /v1/posts/user/:userId?cursor=ISO_TIMESTAMP&perPage=20

Get user's posts (cursor-based pagination).

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):** Same structure as feed.

### GET /v1/posts/:id

Get single post detail.

**Headers:** `Authorization: Bearer <access_token>`

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

Create a new post.

**Headers:** `Authorization: Bearer <access_token>`

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

**Response (201):** Same shape as `GET /v1/posts/:id` (the created post object wrapped in `{ "post": {...} }`).

### PUT /v1/posts/:id

Edit an existing post. Only caption and location are editable — media is immutable after creation. All body fields optional; send only what's being changed. Send `caption: null` / `locationName: null` to clear them. Only the post author may edit (otherwise `403 FORBIDDEN`).

**Headers:** `Authorization: Bearer <access_token>`

**Body:**
```json
{
  "caption": "Updated caption ✏️",
  "locationName": "Da Nang Beach",
  "locationLat": 16.0544,
  "locationLng": 108.2022
}
```

**Response (200):** Same shape as `GET /v1/posts/:id` (the updated post object).

### DELETE /v1/posts/:id

Delete a post. Only the post author may delete (otherwise `403 FORBIDDEN`).

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### POST /v1/posts/:id/like

Like a post.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### DELETE /v1/posts/:id/like

Unlike a post.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### POST /v1/posts/:id/save

Save a post.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### DELETE /v1/posts/:id/save

Unsave a post.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

---

## Comments

### GET /v1/posts/:post_id/comments?cursor=ISO_TIMESTAMP&perPage=20

Get post comments (cursor-based pagination).

**Headers:** `Authorization: Bearer <access_token>`

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
    "nextCursor": "2026-07-15T09:00:00.000Z",
    "hasMore": false
  }
}
```

### POST /v1/posts/:post_id/comments

Add a comment or reply.

**Headers:** `Authorization: Bearer <access_token>`

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

### DELETE /v1/posts/:post_id/comments/:comment_id

Delete a comment. Only the comment author or post author may delete.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### POST /v1/posts/:post_id/comments/:comment_id/like

Like a comment.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### DELETE /v1/posts/:post_id/comments/:comment_id/like

Unlike a comment.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

---

## Stories

> **Note:** Stories endpoints use **page-based pagination** (not cursor-based).

### GET /v1/stories/feed

Get stories feed (active stories from self + following). No pagination - returns all active stories grouped by author.

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "userId": "abc123",
        "author": {
          "id": "abc123",
          "username": "alice",
          "fullName": "Alice Nguyen",
          "avatarUrl": "https://i.pravatar.cc/400?u=alice",
          "isVerified": false
        },
        "stories": [
          {
            "id": "40000000-0000-4000-8000-000000000001",
            "createdAt": "2026-08-04T06:00:00.000Z",
            "expiresAt": "2026-08-05T06:00:00.000Z",
            "items": [
              {
                "id": "story-item-uuid-1",
                "mediaUrl": "https://picsum.photos/seed/story-1-0/1080/1350",
                "type": "IMAGE",
                "duration": 5,
                "sortOrder": 0,
                "stickerType": null,
                "stickerData": null,
                "createdAt": "2026-08-04T06:00:00.000Z"
              }
            ]
          }
        ]
      }
    ]
  }
}
```

### GET /v1/stories/:userId/items

Get story items for a specific user (with view status).

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "stories": [
      {
        "id": "40000000-0000-4000-8000-000000000001",
        "createdAt": "2026-08-04T06:00:00.000Z",
        "expiresAt": "2026-08-05T06:00:00.000Z",
        "items": [
          {
            "id": "story-item-uuid-1",
            "mediaUrl": "https://picsum.photos/seed/story-1-0/1080/1350",
            "type": "IMAGE",
            "duration": 5,
            "sortOrder": 0,
            "stickerType": null,
            "stickerData": null,
            "createdAt": "2026-08-04T06:00:00.000Z"
          }
        ],
        "viewed": false
      }
    ]
  }
}
```

### POST /v1/stories

Create a new story.

**Headers:** `Authorization: Bearer <access_token>`

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

Mark story as viewed.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### DELETE /v1/stories/:storyId

Delete a story. Only the story author may delete.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

---

## Reels

### GET /v1/reels/feed?cursor=ISO_TIMESTAMP&perPage=10

Get reels feed (cursor-based pagination).

**Headers:** `Authorization: Bearer <access_token>`

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
          "avatarUrl": "https://i.pravatar.cc/400?u=alice",
          "isFollowing": false
        },
        "isLiked": false,
        "isSaved": false
      }
    ],
    "nextCursor": "2026-07-20T10:00:00.000Z",
    "hasMore": true
  }
}
```

> `author.isFollowing` reflects whether the current user follows the reel's author.
> `isSaved` reflects whether the current user has saved the reel.

### GET /v1/reels/user/:userId?cursor=ISO_TIMESTAMP&perPage=30

Get reels by a specific user (cursor-based pagination). Same item + pagination shape as feed.

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):** Same structure as reels feed.

### POST /v1/reels

Create a new reel.

**Headers:** `Authorization: Bearer <access_token>`

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

Like a reel.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### DELETE /v1/reels/:id/like

Unlike a reel.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### POST /v1/reels/:id/save

Save a reel.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### DELETE /v1/reels/:id/save

Unsave a reel.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### DELETE /v1/reels/:id

Delete a reel. Only the reel's author may delete it.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### POST /v1/reels/:id/view

Record a view for a reel.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### GET /v1/reels/:reel_id/comments?cursor=ISO_TIMESTAMP&perPage=20

Reel comments use the same contract as post comments (cursor-based pagination).

### POST /v1/reels/:reel_id/comments

Same body and response shape as `POST /v1/posts/:post_id/comments`.

---

## Upload (Neon Object Storage)

The upload system supports two flows:

1. **Presigned URL flow** (for large files - direct to S3):
   - `POST /v1/upload/presign` → Get presigned URL
   - `PUT` to presigned URL → Upload file to S3
   - `POST /v1/upload/confirm` → Confirm upload with backend

2. **Direct multipart upload** (for smaller files):
   - `POST /v1/upload/image`, `/v1/upload/video`, `/v1/upload/avatar`

### POST /v1/upload/presign

Get a presigned URL for direct S3 upload.

**Headers:** `Authorization: Bearer <access_token>`

**Body:**
```json
{
  "contentType": "video/mp4",
  "maxSize": 104857600,
  "prefix": "reels"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "uploadUrl": "https://bucket.s3.region.amazonaws.com/key?signature=...",
    "pendingUploadId": "pending-upload-uuid",
    "storagePath": "reels/user-id/uuid.mp4",
    "url": "https://cdn.example.com/reels/user-id/uuid.mp4",
    "expiresIn": 3600,
    "width": null,
    "height": null,
    "duration": null
  }
}
```

### POST /v1/upload/confirm

Confirm a presigned upload and create the resource.

**Headers:** `Authorization: Bearer <access_token>`

**Body:**
```json
{
  "pendingUploadId": "pending-upload-uuid",
  "targetType": "reel",
  "targetId": "optional-reel-id"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "pendingUploadId": "pending-upload-uuid",
    "url": "https://cdn.example.com/reels/user-id/uuid.mp4",
    "storagePath": "reels/user-id/uuid.mp4"
  }
}
```

### POST /v1/upload/image

Direct multipart image upload (max 10MB).

**Headers:** `Authorization: Bearer <access_token>`
**Content-Type:** `multipart/form-data`

**Body:** `file` field with image data

**Response (201):**
```json
{
  "success": true,
  "data": {
    "url": "https://cdn.example.com/posts/images/user-id/uuid.jpg",
    "width": 1080,
    "height": 1350,
    "pendingUploadId": "pending-upload-uuid"
  }
}
```

### POST /v1/upload/video

Direct multipart video upload (max 100MB).

**Headers:** `Authorization: Bearer <access_token>`
**Content-Type:** `multipart/form-data`

**Body:** `file` field with video data

**Response (201):**
```json
{
  "success": true,
  "data": {
    "url": "https://cdn.example.com/posts/videos/user-id/uuid.mp4",
    "thumbnailUrl": "https://cdn.example.com/posts/videos/user-id/uuid_thumb.jpg",
    "duration": 15.5,
    "width": 1080,
    "height": 1920,
    "pendingUploadId": "pending-upload-uuid"
  }
}
```

### POST /v1/upload/avatar

Direct multipart avatar upload (max 10MB, processed to 400x400 by BE).

**Headers:** `Authorization: Bearer <access_token>`
**Content-Type:** `multipart/form-data`

**Body:** `file` field with image data

**Response (200):**
```json
{
  "success": true,
  "data": {
    "url": "https://cdn.example.com/avatars/user-id/avatar.jpg"
  }
}
```

### GET /v1/upload/pending/:id

Get status of a pending upload.

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "pendingUploadId": "pending-upload-uuid",
    "url": "https://cdn.example.com/...",
    "storagePath": "reels/user-id/uuid.mp4",
    "confirmed": true,
    "createdAt": "2026-08-04T14:37:10.661Z"
  }
}
```

### DELETE /v1/upload/pending/:id

Delete a pending upload (and its storage).

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

---

## Conversations & Messages

### GET /v1/conversations?page=1&perPage=20

Get user's conversations (page-based).

**Headers:** `Authorization: Bearer <access_token>`

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

Create a new conversation (DM or group).

**Headers:** `Authorization: Bearer <access_token>`

**Body:**
```json
{
  "participantIds": ["user-uuid-2", "user-uuid-3"],
  "groupName": "My Group Chat"
}
```

**Response (201):** Conversation object with members.

### GET /v1/conversations/:id/messages?page=1&perPage=20

Get messages for a conversation (page-based).

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):** Paginated messages.

### POST /v1/conversations/:id/messages

Send a message.

**Headers:** `Authorization: Bearer <access_token>`

**Body (text):**
```json
{
  "contentType": "TEXT",
  "textContent": "Hello!",
  "replyToId": "optional-message-uuid"
}
```

**Body (media):**
```json
{
  "contentType": "IMAGE",
  "mediaUrl": "https://storage.example.com/uploads/user-id/photo.jpg",
  "mediaThumbnail": "https://storage.example.com/uploads/user-id/photo_thumb.jpg"
}
```

**Response (201):** Created message object.

### POST /v1/conversations/:id/read

Mark conversation as read.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### PUT /v1/conversations/:id/mute

Mute/unmute a conversation.

**Headers:** `Authorization: Bearer <access_token>`

**Body:**
```json
{
  "mute": true
}
```

**Response (204):** No content

### DELETE /v1/conversations/messages/:message_id

Delete a message.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

---

## Notifications

### GET /v1/notifications?page=1&perPage=20

Get notifications (page-based).

**Headers:** `Authorization: Bearer <access_token>`

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
        "postThumbnailUrl": "https://picsum.photos/seed/post-1-0/200/200",
        "commentText": null,
        "isRead": false,
        "createdAt": "2026-08-04T12:00:00.000Z",
        "actor": {
          "id": "actor-uuid",
          "username": "alice",
          "fullName": "Alice Nguyen",
          "avatarUrl": "https://i.pravatar.cc/400?u=alice"
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

Get unread notification count.

**Headers:** `Authorization: Bearer <access_token>`

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

Mark all notifications as read.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

### POST /v1/notifications/:id/read

Mark a notification as read.

**Headers:** `Authorization: Bearer <access_token>`

**Response (204):** No content

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
| 503 | SERVICE_UNAVAILABLE | Service unavailable |

---

## WebSocket

Connect to: `ws://localhost:3000/ws?token=<access_token>`

> **Important:** Token is passed as query parameter `?token=xxx`, NOT in headers.

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

```json
{
  "type": "user_online",
  "userId": "abc123"
}
```

```json
{
  "type": "user_offline",
  "userId": "abc123",
  "lastSeen": "2026-08-04T14:37:10.661Z"
}
```

```json
{
  "type": "typing",
  "conversationId": "conv-uuid",
  "userId": "abc123"
}
```

```json
{
  "type": "stop_typing",
  "conversationId": "conv-uuid",
  "userId": "abc123"
}
```

```json
{
  "type": "call_incoming",
  "callId": "call-uuid",
  "callerId": "abc123",
  "callerName": "Alice",
  "hasVideo": true
}
```

**Outgoing events:**

```json
{
  "type": "send_message",
  "conversationId": "conv-uuid",
  "contentType": "TEXT",
  "textContent": "Hello!"
}
```

```json
{
  "type": "start_typing",
  "conversationId": "conv-uuid"
}
```

```json
{
  "type": "stop_typing",
  "conversationId": "conv-uuid"
}
```

```json
{
  "type": "mark_read",
  "conversationId": "conv-uuid"
}
```

```json
{
  "type": "call_initiate",
  "targetId": "abc123",
  "hasVideo": true
}
```

```json
{
  "type": "call_offer",
  "callId": "call-uuid",
  "sdp": "..."
}
```

```json
{
  "type": "call_answer",
  "callId": "call-uuid",
  "sdp": "..."
}
```

```json
{
  "type": "call_ice_candidate",
  "callId": "call-uuid",
  "candidate": "..."
}
```

```json
{
  "type": "call_hangup",
  "callId": "call-uuid"
}
```

```json
{
  "type": "subscribe",
  "topics": ["messages", "notifications", "presence"]
}
```

```json
{
  "type": "unsubscribe",
  "topics": ["messages"]
}
```