# API Response Reference

**Base URL:** `http://localhost:3000` (configurable via `AppConfig.baseURL`)

**Authentication:** All authenticated endpoints require header: `Authorization: Bearer <Firebase ID Token>`

> **Important:** The client uses **Firebase ID Token** (JWT from Firebase Auth SDK) as the access token.
> The backend **does NOT issue its own access/refresh tokens**. The Firebase SDK handles token rotation internally.
> The `/v1/auth/refresh` endpoint exists in this spec but **is not called by the client** - it's kept for reference only.

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

**Pagination:** `?page=1&perPage=20` (max 50) — returns `{ items, page, perPage, total, hasMore }`

**Date Format:** ISO 8601 with fractional seconds (`yyyy-MM-dd'T'HH:mm:ss.SSSZ`)

**Field Naming:** JSON uses **snake_case** (client decodes with `.convertFromSnakeCase`)

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

Register a new user after Firebase Auth account creation.

**Body:**
```json
{
  "idToken": "eyJhbGci...",    // Firebase ID Token from createUser()
  "name": "John Doe",          // Full name
  "phone": "+84901234567"      // Optional phone number
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "ddc20ee7-c705-4622-8431-deaff120408b",      // App's internal UUID (not firebaseUid)
      "firebase_uid": "SPrBlqwAx0VPklWeuYtVre1EHOD3",   // Firebase UID for reference
      "username": "john_doe_1234",
      "full_name": "John Doe",
      "email": "john@example.com",
      "phone": "+84901234567",
      "avatar_url": null,
      "bio": null,
      "website": null,
      "is_verified": false,
      "is_private": false,
      "posts_count": 0,
      "followers_count": 0,
      "following_count": 0,
      "created_at": "2026-08-04T14:37:10.661Z",
      "updated_at": "2026-08-04T14:37:10.661Z"
    }
  }
}
```

> **Note:** Response uses snake_case. `id` is the app's internal UUID (primary key), `firebase_uid` is the Firebase Auth UID. Client maps both via `UserMapper`.

### POST /v1/auth/login

Verify Firebase ID Token and return user profile.

**Body:**
```json
{
  "idToken": "eyJhbGci..."    // Firebase ID Token from signIn()
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "ddc20ee7-c705-4622-8431-deaff120408b",
      "firebase_uid": "SPrBlqwAx0VPklWeuYtVre1EHOD3",
      "username": "dev_user",
      "full_name": "Dev User",
      "email": "dev@example.com",
      "phone": null,
      "avatar_url": "https://i.pravatar.cc/400?u=dev_user",
      "bio": "Development account",
      "website": null,
      "is_verified": false,
      "is_private": false,
      "posts_count": 0,
      "followers_count": 4,
      "following_count": 4,
      "created_at": "2026-08-04T14:37:10.661Z",
      "updated_at": "2026-08-04T14:37:10.874Z"
    }
  }
}
```

> **Important:** Do NOT return `accessToken`, `refreshToken`, or `expiresIn` in the response. The client already has the Firebase ID Token and uses it as the Bearer token. The client extracts token expiry from the JWT `exp` claim locally.

### POST /v1/auth/refresh  (NOT USED BY CLIENT - REFERENCE ONLY)

The client **does not call this endpoint**. Token refresh is handled by Firebase SDK via `user.getIDToken()` which auto-refreshes expired tokens. This endpoint is documented for reference only.

**Body:**
```json
{
  "refresh_token": "..."    // Not used - Firebase doesn't provide backend refresh tokens
}
```

**Response (200) - If implemented:**
```json
{
  "success": true,
  "data": {
    "id_token": "eyJhbGci...",       // New Firebase ID Token (if backend generates)
    "refresh_token": "...",          // New refresh token (if backend issues)
    "expires_in": 3600               // Seconds until expiry
  }
}
```

### POST /v1/auth/logout-all-devices

Invalidate all sessions for the current user (called on logout).

**Response (204):** No content

### POST /v1/auth/forgot-password

Request password reset via phone number.

**Body:**
```json
{
  "phone_number": "+84901234567"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password reset code sent"
}
```

### POST /v1/auth/reset-password

Reset password with OTP token from SMS/email.

**Body:**
```json
{
  "token": "123456",
  "password": "newSecurePassword123"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password reset successful"
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

Change password for authenticated user (requires current password).

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Body:**
```json
{
  "current_password": "oldPassword123",
  "new_password": "newSecurePassword456"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Password changed successfully"
}
```

> **Note:** Client also calls Firebase Auth SDK `updatePassword()` after this succeeds (requires re-authentication with current password). Backend should verify current password and update the user's password hash.

---

## Users

> **Endpoint Paths:** The client uses `/v1/user/profile` and `/v1/user/settings` (not `/v1/users/me`).

### GET /v1/user/profile

Get current user's full profile.

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "ddc20ee7-c705-4622-8431-deaff120408b",
      "firebase_uid": "SPrBlqwAx0VPklWeuYtVre1EHOD3",
      "username": "dev_user",
      "full_name": "Dev User",
      "email": "dev@example.com",
      "phone": null,
      "avatar_url": "https://i.pravatar.cc/400?u=dev_user",
      "bio": "Development account",
      "website": null,
      "is_verified": false,
      "is_private": false,
      "posts_count": 2,
      "followers_count": 4,
      "following_count": 4,
      "created_at": "2026-08-04T14:37:10.661Z",
      "updated_at": "2026-08-04T14:37:10.874Z"
    }
  }
}
```

### PUT /v1/user/profile

Update current user's profile (name only).

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Body:**
```json
{
  "name": "New Name"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "ddc20ee7-c705-4622-8431-deaff120408b",
      "firebase_uid": "SPrBlqwAx0VPklWeuYtVre1EHOD3",
      "username": "dev_user",
      "full_name": "New Name",
      "email": "dev@example.com",
      "phone": null,
      "avatar_url": "https://i.pravatar.cc/400?u=dev_user",
      "bio": "Development account",
      "website": null,
      "is_verified": false,
      "is_private": false,
      "posts_count": 2,
      "followers_count": 4,
      "following_count": 4,
      "created_at": "2026-08-04T14:37:10.661Z",
      "updated_at": "2026-08-04T15:30:00.000Z"
    }
  }
}
```

### GET /v1/user/settings

Get current user's preferences (notifications, data usage, UI).

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "settings": {
      "language": "en",
      "biometric_enabled": true,
      "push_enabled": true,
      "dark_mode": false
    }
  }
}
```

### PUT /v1/user/settings

Update current user's preferences. All fields optional.

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Body:**
```json
{
  "language": "vi",
  "biometric_enabled": false,
  "push_enabled": true,
  "dark_mode": true
}
```

**Response (200):** Same shape as `GET /v1/user/settings` with updated values.
```json
{
  "success": true,
  "data": {
    "settings": {
      "language": "vi",
      "biometric_enabled": false,
      "push_enabled": true,
      "dark_mode": true
    }
  }
}
```

> **Note:** The client sends snake_case keys (`biometric_enabled`, `push_enabled`, `dark_mode`). The `language` field uses ISO 639-1 codes (e.g., "en", "vi").

### GET /v1/users/:id

Get public profile of another user.

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "abc123",
      "username": "alice",
      "full_name": "Alice Nguyen",
      "avatar_url": "https://i.pravatar.cc/400?u=alice",
      "bio": "Photography enthusiast",
      "website": null,
      "is_verified": false,
      "is_private": false,
      "posts_count": 10,
      "followers_count": 15,
      "following_count": 12,
      "is_following": true,
      "is_followed_by": false
    }
  }
}
```

### GET /v1/users/search?q=alice&page=1&perPage=20

Search users by username/full name.

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "abc123",
        "username": "alice",
        "full_name": "Alice Nguyen",
        "avatar_url": "https://i.pravatar.cc/400?u=alice",
        "bio": "Photography enthusiast",
        "website": null,
        "is_verified": false,
        "is_private": false,
        "posts_count": 10,
        "followers_count": 15,
        "following_count": 12
      }
    ],
    "page": 1,
    "perPage": 20,
    "total": 1,
    "has_more": false
  }
}
```

### GET /v1/users/suggested?page=1&perPage=20

Get suggested users to follow.

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "xyz789",
        "username": "emma",
        "full_name": "Emma Vo",
        "avatar_url": "https://i.pravatar.cc/400?u=emma",
        "bio": "Living one day at a time",
        "website": null,
        "is_verified": false,
        "is_private": false,
        "posts_count": 8,
        "followers_count": 20,
        "following_count": 10
      }
    ],
    "page": 1,
    "perPage": 20,
    "total": 15,
    "has_more": false
  }
}
```

### GET /v1/users/:id/followers?page=1&perPage=20

Get user's followers.

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "abc123",
        "username": "bob",
        "full_name": "Bob Tran",
        "avatar_url": "https://i.pravatar.cc/400?u=bob",
        "bio": "Developer by day",
        "website": null,
        "is_verified": false,
        "is_private": false,
        "posts_count": 5,
        "followers_count": 10,
        "following_count": 8
      }
    ],
    "page": 1,
    "perPage": 20,
    "total": 4,
    "has_more": false
  }
}
```

### GET /v1/users/:id/following?page=1&perPage=20

Get user's following. Same structure as followers.

### POST /v1/users/:id/follow

Follow a user.

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (204):** No content

### DELETE /v1/users/:id/follow

Unfollow a user.

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (204):** No content

### POST /v1/users/:id/block

Block a user.

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (204):** No content

### DELETE /v1/users/:id/block

Unblock a user.

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (204):** No content

### GET /v1/users/me/blocked?page=1&perPage=20

Get list of users blocked by current user. Same item shape as `/followers`.

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "blk123",
        "username": "spammer",
        "full_name": "Spam Account",
        "avatar_url": "https://i.pravatar.cc/400?u=spammer",
        "bio": null,
        "website": null,
        "is_verified": false,
        "is_private": false,
        "posts_count": 0,
        "followers_count": 0,
        "following_count": 0
      }
    ],
    "page": 1,
    "perPage": 20,
    "total": 1,
    "has_more": false
  }
}
```

---

## Close Friends

### GET /v1/users/me/close-friends?page=1&perPage=50

Returns the accounts on the current user's Close Friends list. Same item shape as `/followers`.

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "cf123",
        "username": "bestie",
        "full_name": "Best Friend",
        "avatar_url": "https://i.pravatar.cc/400?u=bestie",
        "bio": null,
        "website": null,
        "is_verified": false,
        "is_private": false,
        "posts_count": 12,
        "followers_count": 30,
        "following_count": 25
      }
    ],
    "page": 1,
    "perPage": 50,
    "total": 1,
    "has_more": false
  }
}
```

### PUT /v1/users/me/close-friends

Replaces the entire Close Friends list with the provided set of user IDs (idempotent full-set update, matching Instagram's editor which submits the final selection).

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Body:**
```json
{
  "user_ids": ["cf123", "cf456"]
}
```

**Response (200):** Same shape as `GET /v1/users/me/close-friends` (the updated list).

### POST /v1/users/me/device-token

Register FCM/APNs device token for push notifications.

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Body:**
```json
{
  "token": "fcm-device-token-string",
  "platform": "IOS"
}
```

**Response (204):** No content

### DELETE /v1/users/me/device-token

Unregister device token.

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Body:**
```json
{
  "token": "fcm-device-token-string"
}
```

**Response (204):** No content

---

## Posts

> **Field Naming:** All JSON fields use snake_case (client decodes with `.convertFromSnakeCase`)

### GET /v1/posts/feed?page=1&perPage=20

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "10000000-0000-4000-8000-000000000001",
        "author_id": "abc123",
        "caption": "A calm morning in Da Nang ☀️",
        "location_name": null,
        "location_lat": null,
        "location_lng": null,
        "likes_count": 15,
        "comments_count": 3,
        "is_sponsored": false,
        "created_at": "2026-07-15T08:30:00.000Z",
        "updated_at": "2026-07-15T08:30:00.000Z",
        "author": {
          "id": "abc123",
          "username": "alice",
          "full_name": "Alice Nguyen",
          "avatar_url": "https://i.pravatar.cc/400?u=alice",
          "is_verified": false,
          "is_private": false
        },
        "media_items": [
          {
            "id": "media-uuid-1",
            "post_id": "10000000-0000-4000-8000-000000000001",
            "url": "https://picsum.photos/seed/post-1-0/1080/1350",
            "thumbnail_url": null,
            "type": "IMAGE",
            "width": 1080,
            "height": 1350,
            "duration": null,
            "sort_order": 0
          }
        ],
        "is_liked": true,
        "is_saved": false
      }
    ],
    "page": 1,
    "perPage": 20,
    "total": 50,
    "has_more": true
  }
}
```

### GET /v1/posts/explore?page=1&perPage=30

Same structure as feed (sorted by likes_count desc).

### GET /v1/posts/saved?page=1&perPage=20

Same structure as feed (is_saved is always true).

### GET /v1/posts/user/:userId?page=1&perPage=20

Same structure as feed.

### GET /v1/posts/:id

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "post": {
      "id": "10000000-0000-4000-8000-000000000001",
      "author_id": "abc123",
      "caption": "A calm morning in Da Nang ☀️",
      "location_name": null,
      "location_lat": null,
      "location_lng": null,
      "likes_count": 15,
      "comments_count": 3,
      "is_sponsored": false,
      "created_at": "2026-07-15T08:30:00.000Z",
      "updated_at": "2026-07-15T08:30:00.000Z",
      "author": {
        "id": "abc123",
        "username": "alice",
        "full_name": "Alice Nguyen",
        "avatar_url": "https://i.pravatar.cc/400?u=alice",
        "is_verified": false,
        "is_private": false
      },
      "media_items": [
        {
          "id": "media-uuid-1",
          "post_id": "10000000-0000-4000-8000-000000000001",
          "url": "https://picsum.photos/seed/post-1-0/1080/1350",
          "thumbnail_url": null,
          "type": "IMAGE",
          "width": 1080,
          "height": 1350,
          "duration": null,
          "sort_order": 0
        },
        {
          "id": "media-uuid-2",
          "post_id": "10000000-0000-4000-8000-000000000001",
          "url": "https://picsum.photos/seed/post-1-1/1080/1080",
          "thumbnail_url": null,
          "type": "IMAGE",
          "width": 1080,
          "height": 1080,
          "duration": null,
          "sort_order": 1
        }
      ],
      "is_liked": true,
      "is_saved": false
    }
  }
}
```

### POST /v1/posts

Create a new post.

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Body:**
```json
{
  "caption": "Beautiful sunset 🌅",
  "location_name": "Da Nang Beach",
  "location_lat": 16.0544,
  "location_lng": 108.2022,
  "media": [
    {
      "url": "https://storage.example.com/uploads/user-id/image.jpg",
      "type": "IMAGE",
      "width": 1080,
      "height": 1350,
      "pending_upload_id": "upload-uuid"
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
      "author_id": "user-uuid",
      "caption": "Beautiful sunset 🌅",
      "location_name": "Da Nang Beach",
      "location_lat": 16.0544,
      "location_lng": 108.2022,
      "likes_count": 0,
      "comments_count": 0,
      "is_sponsored": false,
      "created_at": "2026-08-04T15:00:00.000Z",
      "updated_at": "2026-08-04T15:00:00.000Z",
      "author": {
        "id": "user-uuid",
        "username": "dev_user",
        "full_name": "Dev User",
        "avatar_url": "https://i.pravatar.cc/400?u=dev_user",
        "is_verified": false,
        "is_private": false
      },
      "media_items": [
        {
          "id": "media-uuid",
          "post_id": "new-post-uuid",
          "url": "https://storage.example.com/uploads/user-id/image.jpg",
          "thumbnail_url": null,
          "type": "IMAGE",
          "width": 1080,
          "height": 1350,
          "duration": null,
          "sort_order": 0
        }
      ]
    }
  }
}
```

### PUT /v1/posts/:id

Edit an existing post. Only the caption and location are editable — media is immutable after creation (matches Instagram). All body fields are optional; send only the fields being changed. Send `caption: null` / `location_name: null` to clear them. Only the post author may edit (otherwise `403 FORBIDDEN`).

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Body:**
```json
{
  "caption": "Updated caption ✏️",
  "location_name": "Da Nang Beach",
  "location_lat": 16.0544,
  "location_lng": 108.2022
}
```

**Response (200):** Same shape as `GET /v1/posts/:id` (the updated post object wrapped in `{ "post": {...} }`).

```json
{
  "success": true,
  "data": {
    "post": {
      "id": "10000000-0000-4000-8000-000000000001",
      "author_id": "abc123",
      "caption": "Updated caption ✏️",
      "location_name": "Da Nang Beach",
      "location_lat": 16.0544,
      "location_lng": 108.2022,
      "likes_count": 15,
      "comments_count": 3,
      "is_sponsored": false,
      "created_at": "2026-07-15T08:30:00.000Z",
      "updated_at": "2026-08-04T16:00:00.000Z",
      "author": { "id": "abc123", "username": "alice", "full_name": "Alice Nguyen", "avatar_url": "https://i.pravatar.cc/400?u=alice", "is_verified": false, "is_private": false },
      "media_items": [ /* unchanged, same as create/detail */ ],
      "is_liked": true,
      "is_saved": false
    }
  }
}
```

### DELETE /v1/posts/:id

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (204):** No content

### POST /v1/posts/:id/like

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (204):** No content

### DELETE /v1/posts/:id/like

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (204):** No content

### POST /v1/posts/:id/save

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (204):** No content

### DELETE /v1/posts/:id/save

**Headers:** `Authorization: Bearer <Firebase ID Token>`

**Response (204):** No content

---

## Comments

> **Field Naming:** All JSON fields use snake_case (client decodes with `.convertFromSnakeCase`)

### GET /v1/posts/:post_id/comments?page=1&perPage=20

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "20000000-0000-4000-8000-000000000001",
        "post_id": "10000000-0000-4000-8000-000000000001",
        "author_id": "abc123",
        "text": "Looks wonderful! 😍",
        "parent_id": null,
        "likes_count": 2,
        "created_at": "2026-07-15T09:00:00.000Z",
        "author": {
          "id": "abc123",
          "username": "bob",
          "full_name": "Bob Tran",
          "avatar_url": "https://i.pravatar.cc/400?u=bob",
          "is_verified": false
        },
        "replies": [
          {
            "id": "20000000-0000-4000-8000-000000000002",
            "post_id": "10000000-0000-4000-8000-000000000001",
            "author_id": "def456",
            "text": "Agreed! 🙌",
            "parent_id": "20000000-0000-4000-8000-000000000001",
            "likes_count": 0,
            "created_at": "2026-07-15T09:05:00.000Z",
            "author": {
              "id": "def456",
              "username": "carol",
              "full_name": "Carol Le",
              "avatar_url": "https://i.pravatar.cc/400?u=carol",
              "is_verified": false
            }
          }
        ]
      }
    ],
    "page": 1,
    "perPage": 20,
    "total": 5,
    "has_more": false
  }
}
```

### POST /v1/posts/:post_id/comments

**Body:**
```json
{
  "text": "Amazing photo!",
  "parent_id": "optional-comment-uuid-for-reply"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "comment": {
      "id": "new-comment-uuid",
      "post_id": "post-uuid",
      "author_id": "user-uuid",
      "text": "Amazing photo!",
      "parent_id": null,
      "likes_count": 0,
      "created_at": "2026-08-04T15:00:00.000Z",
      "author": {
        "id": "user-uuid",
        "username": "dev_user",
        "full_name": "Dev User",
        "avatar_url": "https://i.pravatar.cc/400?u=dev_user",
        "is_verified": false
      },
      "replies": []
    }
  }
}
```

### DELETE /v1/posts/:post_id/comments/:comment_id

**Response (204):** No content

### POST /v1/posts/:post_id/comments/:comment_id/like

**Response (204):** No content

### DELETE /v1/posts/:post_id/comments/:comment_id/like

**Response (204):** No content

---

## Stories

> **Field Naming:** All JSON fields use snake_case (client decodes with `.convertFromSnakeCase`)

### GET /v1/stories/feed

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "40000000-0000-4000-8000-000000000001",
        "author_id": "abc123",
        "created_at": "2026-08-04T06:00:00.000Z",
        "expires_at": "2026-08-05T06:00:00.000Z",
        "author": {
          "id": "abc123",
          "username": "alice",
          "avatar_url": "https://i.pravatar.cc/400?u=alice"
        },
        "items": [
          {
            "id": "story-item-uuid-1",
            "story_id": "40000000-0000-4000-8000-000000000001",
            "media_url": "https://picsum.photos/seed/story-1-0/1080/1350",
            "type": "IMAGE",
            "duration": 5,
            "sort_order": 0,
            "sticker_type": null,
            "sticker_data": null,
            "created_at": "2026-08-04T06:00:00.000Z"
          }
        ],
        "views": []
      }
    ]
  }
}
```

Note: `views` array contains `{ "id": "..." }` if current user has viewed the story.

### GET /v1/stories/:user_id/items

**Response (200):**
```json
{
  "success": true,
  "data": {
    "stories": [
      {
        "id": "40000000-0000-4000-8000-000000000001",
        "author_id": "abc123",
        "created_at": "2026-08-04T06:00:00.000Z",
        "expires_at": "2026-08-05T06:00:00.000Z",
        "items": [
          {
            "id": "story-item-uuid-1",
            "story_id": "40000000-0000-4000-8000-000000000001",
            "media_url": "https://picsum.photos/seed/story-1-0/1080/1350",
            "type": "IMAGE",
            "duration": 5,
            "sort_order": 0,
            "sticker_type": null,
            "sticker_data": null,
            "created_at": "2026-08-04T06:00:00.000Z"
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
  "media_url": "https://storage.example.com/uploads/user-id/story.jpg",
  "type": "IMAGE",
  "duration": 5,
  "sticker_type": "poll",
  "sticker_data": "{\"question\":\"Yes or No?\"}"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "story": {
      "id": "new-story-uuid",
      "author_id": "user-uuid",
      "created_at": "2026-08-04T15:00:00.000Z",
      "expires_at": "2026-08-05T15:00:00.000Z",
      "items": [
        {
          "id": "story-item-uuid",
          "story_id": "new-story-uuid",
          "media_url": "https://storage.example.com/uploads/user-id/story.jpg",
          "type": "IMAGE",
          "duration": 5,
          "sort_order": 0,
          "sticker_type": "poll",
          "sticker_data": "{\"question\":\"Yes or No?\"}",
          "created_at": "2026-08-04T15:00:00.000Z"
        }
      ]
    }
  }
}
```

### POST /v1/stories/:story_id/view

**Response (204):** No content

### DELETE /v1/stories/:story_id

**Response (204):** No content

---

## Reels

> **Field Naming:** All JSON fields use snake_case (client decodes with `.convertFromSnakeCase`)

### GET /v1/reels/user/:user_id?page=1&perPage=30

Returns reels authored by a specific user (used by the profile Reels grid).
Same item + pagination shape as `/v1/reels/feed`.

**Response (200):** Same structure as the reels feed below (filtered to `author_id == :user_id`).

### GET /v1/reels/feed?page=1&perPage=10

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "30000000-0000-4000-8000-000000000001",
        "author_id": "abc123",
        "video_url": "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        "thumbnail_url": "https://picsum.photos/seed/reel-1/1080/1350",
        "caption": "Day in the life 🎬",
        "audio_name": null,
        "audio_artist": null,
        "audio_cover_url": null,
        "is_original_audio": true,
        "duration": 30,
        "likes_count": 45,
        "comments_count": 0,
        "shares_count": 0,
        "views_count": 1200,
        "created_at": "2026-07-20T10:00:00.000Z",
        "author": {
          "id": "abc123",
          "username": "alice",
          "avatar_url": "https://i.pravatar.cc/400?u=alice",
          "is_following": false
        },
        "is_liked": false,
        "is_saved": false
      }
    ],
    "page": 1,
    "perPage": 10,
    "total": 60,
    "has_more": true
  }
}
```

> `author.is_following` reflects whether the current user follows the reel's
> author (drives the inline Follow button + the "Following" tab filter).
> `is_saved` reflects whether the current user has saved the reel (drives the
> bookmark toggle). Both default to `false` when absent.

### POST /v1/reels

**Body:**
```json
{
  "video_url": "https://storage.example.com/uploads/user-id/reel.mp4",
  "thumbnail_url": "https://storage.example.com/uploads/user-id/reel_thumb.jpg",
  "caption": "New reel! 🎬",
  "duration": 15,
  "audio_name": "Original Sound",
  "audio_artist": "dev_user"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "reel": {
      "id": "new-reel-uuid",
      "author_id": "user-uuid",
      "video_url": "https://storage.example.com/uploads/user-id/reel.mp4",
      "thumbnail_url": "https://storage.example.com/uploads/user-id/reel_thumb.jpg",
      "caption": "New reel! 🎬",
      "audio_name": "Original Sound",
      "audio_artist": "dev_user",
      "audio_cover_url": null,
      "is_original_audio": true,
      "duration": 15,
      "likes_count": 0,
      "comments_count": 0,
      "shares_count": 0,
      "views_count": 0,
      "created_at": "2026-08-04T15:00:00.000Z",
      "author": {
        "id": "user-uuid",
        "username": "dev_user",
        "avatar_url": "https://i.pravatar.cc/400?u=dev_user"
      }
    }
  }
}
```

### POST /v1/reels/:id/like

**Response (204):** No content

### DELETE /v1/reels/:id/like

**Response (204):** No content

### POST /v1/reels/:id/save

Save a reel to the current user's collection.

**Response (204):** No content

### DELETE /v1/reels/:id/save

Remove a reel from the current user's saved collection.

**Response (204):** No content

### DELETE /v1/reels/:id

Delete a reel. Only the reel's author may delete it (otherwise `403 FORBIDDEN`).

**Response (204):** No content

### POST /v1/reels/:id/view

**Response (204):** No content

### GET /v1/reels/:reel_id/comments?page=1&perPage=20

Reel comments reuse the exact same contract, request params, and response shape
as post comments (`GET /v1/posts/:post_id/comments`). The client renders reel
comments with the same UI as post comments (presented as a ~2/3-height sheet).

### POST /v1/reels/:reel_id/comments

Same body and response shape as `POST /v1/posts/:post_id/comments`.

> Note: If the backend prefers a single polymorphic comments resource, an
> alternative is `GET/POST /v1/comments?target_type=REEL&target_id=:reel_id`.
> The client only needs the paginated `items` + single-`comment` shapes to match.

---

## Conversations & Messages

> **Field Naming:** All JSON fields use snake_case (client decodes with `.convertFromSnakeCase`)

### GET /v1/conversations?page=1&perPage=20

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "50000000-0000-4000-8000-000000000001",
        "is_group": false,
        "group_name": null,
        "group_avatar": null,
        "created_at": "2026-08-01T10:00:00.000Z",
        "updated_at": "2026-08-04T14:00:00.000Z",
        "members": [
          {
            "id": "member-uuid-1",
            "conversation_id": "50000000-0000-4000-8000-000000000001",
            "user_id": "user-uuid-1",
            "is_muted": false,
            "last_read_at": "2026-08-04T14:00:00.000Z",
            "joined_at": "2026-08-01T10:00:00.000Z",
            "user": {
              "id": "user-uuid-1",
              "username": "dev_user",
              "full_name": "Dev User",
              "avatar_url": "https://i.pravatar.cc/400?u=dev_user"
            }
          },
          {
            "id": "member-uuid-2",
            "conversation_id": "50000000-0000-4000-8000-000000000001",
            "user_id": "user-uuid-2",
            "is_muted": false,
            "last_read_at": null,
            "joined_at": "2026-08-01T10:00:00.000Z",
            "user": {
              "id": "user-uuid-2",
              "username": "alice",
              "full_name": "Alice Nguyen",
              "avatar_url": "https://i.pravatar.cc/400?u=alice"
            }
          }
        ],
        "messages": [
          {
            "id": "60000000-0000-4000-8000-000000000010",
            "conversation_id": "50000000-0000-4000-8000-000000000001",
            "sender_id": "user-uuid-2",
            "content_type": "TEXT",
            "text_content": "See you tomorrow!",
            "media_url": null,
            "media_thumbnail": null,
            "media_duration": null,
            "reference_id": null,
            "reply_to_id": null,
            "status": "SENT",
            "created_at": "2026-08-04T14:00:00.000Z"
          }
        ]
      }
    ],
    "page": 1,
    "perPage": 20,
    "total": 5,
    "has_more": false
  }
}
```

### POST /v1/conversations

**Body:**
```json
{
  "participant_ids": ["user-uuid-2", "user-uuid-3"],
  "group_name": "My Group Chat"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "conversation": {
      "id": "new-conversation-uuid",
      "is_group": true,
      "group_name": "My Group Chat",
      "group_avatar": null,
      "created_at": "2026-08-04T15:00:00.000Z",
      "updated_at": "2026-08-04T15:00:00.000Z",
      "members": [
        {
          "id": "member-uuid",
          "conversation_id": "new-conversation-uuid",
          "user_id": "user-uuid",
          "is_muted": false,
          "last_read_at": null,
          "joined_at": "2026-08-04T15:00:00.000Z",
          "user": {
            "id": "user-uuid",
            "username": "dev_user",
            "full_name": "Dev User",
            "avatar_url": "https://i.pravatar.cc/400?u=dev_user"
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
        "conversation_id": "50000000-0000-4000-8000-000000000001",
        "sender_id": "user-uuid",
        "content_type": "TEXT",
        "text_content": "Hey! How are you?",
        "media_url": null,
        "media_thumbnail": null,
        "media_duration": null,
        "reference_id": null,
        "reply_to_id": null,
        "status": "SENT",
        "created_at": "2026-08-04T12:00:00.000Z",
        "sender": {
          "id": "user-uuid",
          "username": "dev_user",
          "avatar_url": "https://i.pravatar.cc/400?u=dev_user"
        }
      }
    ],
    "page": 1,
    "perPage": 20,
    "total": 30,
    "has_more": true
  }
}
```

### POST /v1/conversations/:id/messages

**Body:**
```json
{
  "content_type": "TEXT",
  "text_content": "Hello!",
  "reply_to_id": "optional-message-uuid"
}
```

Or for media:
```json
{
  "content_type": "IMAGE",
  "media_url": "https://storage.example.com/uploads/user-id/photo.jpg",
  "media_thumbnail": "https://storage.example.com/uploads/user-id/photo_thumb.jpg"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "message": {
      "id": "new-message-uuid",
      "conversation_id": "conversation-uuid",
      "sender_id": "user-uuid",
      "content_type": "TEXT",
      "text_content": "Hello!",
      "media_url": null,
      "media_thumbnail": null,
      "media_duration": null,
      "reference_id": null,
      "reply_to_id": null,
      "status": "SENT",
      "created_at": "2026-08-04T15:00:00.000Z",
      "sender": {
        "id": "user-uuid",
        "username": "dev_user",
        "avatar_url": "https://i.pravatar.cc/400?u=dev_user"
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

### DELETE /v1/conversations/messages/:message_id

**Response (204):** No content

---

## Notifications

> **Field Naming:** All JSON fields use snake_case (client decodes with `.convertFromSnakeCase`)

### GET /v1/notifications?page=1&perPage=20

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "notification-uuid",
        "recipient_id": "user-uuid",
        "actor_id": "actor-uuid",
        "type": "LIKE",
        "post_id": "10000000-0000-4000-8000-000000000001",
        "post_thumbnail_url": "https://picsum.photos/seed/post-1-0/200/200",
        "comment_text": null,
        "is_read": false,
        "created_at": "2026-08-04T12:00:00.000Z",
        "actor": {
          "id": "actor-uuid",
          "username": "alice",
          "full_name": "Alice Nguyen",
          "avatar_url": "https://i.pravatar.cc/400?u=alice"
        }
      },
      {
        "id": "notification-uuid-2",
        "recipient_id": "user-uuid",
        "actor_id": "actor-uuid-2",
        "type": "COMMENT",
        "post_id": "10000000-0000-4000-8000-000000000002",
        "post_thumbnail_url": "https://picsum.photos/seed/post-2-0/200/200",
        "comment_text": "Great photo!",
        "is_read": true,
        "created_at": "2026-08-03T18:00:00.000Z",
        "actor": {
          "id": "actor-uuid-2",
          "username": "bob",
          "full_name": "Bob Tran",
          "avatar_url": "https://i.pravatar.cc/400?u=bob"
        }
      },
      {
        "id": "notification-uuid-3",
        "recipient_id": "user-uuid",
        "actor_id": "actor-uuid-3",
        "type": "FOLLOW",
        "post_id": null,
        "post_thumbnail_url": null,
        "comment_text": null,
        "is_read": false,
        "created_at": "2026-08-03T10:00:00.000Z",
        "actor": {
          "id": "actor-uuid-3",
          "username": "carol",
          "full_name": "Carol Le",
          "avatar_url": "https://i.pravatar.cc/400?u=carol"
        }
      }
    ],
    "page": 1,
    "perPage": 20,
    "total": 25,
    "has_more": true
  }
}
```

**NotificationType enum:** `LIKE`, `COMMENT`, `FOLLOW`, `FOLLOW_REQUEST`, `MENTION`, `TAGGED_IN_POST`, `STORY_MENTION`, `LIVE_VIDEO`

`post_thumbnail_url` is a small thumbnail of the related post (present for
post-related types like `LIKE`, `COMMENT`, `TAGGED_IN_POST`; `null` for
`FOLLOW`). Lets the client render the post preview without an extra fetch.

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

> **Field Naming:** All JSON fields use snake_case (client decodes with `.convertFromSnakeCase`)

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
    "pending_upload_id": "pending-upload-uuid"
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
    "thumbnail_url": "https://storage.googleapis.com/bucket/uploads/user-id/uuid_thumb.jpg",
    "duration": 15.5,
    "width": 1080,
    "height": 1920,
    "pending_upload_id": "pending-upload-uuid"
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
