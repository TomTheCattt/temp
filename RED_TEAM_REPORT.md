# RED TEAM REPORT — Sprint 2: iOS Dev → BA Review of SPEC.md

**Reviewer:** iOS Developer (Red Team Rotation: Sprint 2 = iOS → BA)
**Date:** 2026-11-10
**Target:** SPEC.md (Instagram Clone Platform Specification)
**Role:** BA (Business Analyst) owns SPEC.md — iOS Dev reviews for ambiguity, missing edge cases, over-spec

---

## Executive Summary

The SPEC.md is a comprehensive API/backend specification with OpenAPI 3.1 contracts. As the iOS consumer, I've reviewed it for **client-side implementability**, **ambiguity**, **missing edge cases**, and **over-specification** that could hinder iOS development.

**Overall Assessment:** SPEC is well-structured but has **critical gaps** for iOS implementation — specifically around pagination patterns, real-time sync semantics, error handling contracts, and offline/optimistic UI requirements.

---

## 1. Ambiguity Findings (Must Clarify)

| # | Section | Issue | Impact on iOS | Clarification Needed |
|---|---------|-------|---------------|---------------------|
| A1 | 3.3 Posts / AC-POST-002 | Feed pagination uses `cursor` but `CursorParam` is timestamp-based. No clarity on whether cursor = `createdAt` of last item or opaque token. | FeedViewModel pagination logic can't be implemented correctly without knowing cursor semantics. | Define: Is cursor ISO8601 timestamp or opaque base64 token? If timestamp, how to handle duplicate timestamps? |
| A2 | 4.1 OpenAPI / PaginatedPosts | `nextCursor` type is `string` but no format specified. `hasMore` boolean but no total count. | Infinite scroll needs `hasMore`; pull-to-refresh needs total or first-page reset logic. | Add `totalCount` optional field. Specify cursor format (timestamp vs opaque). |
| A3 | 6.2 WebSocket / `send_message` | `contentType` enum includes `POST`, `STORY`, `REEL`, `LIKE` but no schema for their payload structure. | ChatViewModel can't serialize these message types without knowing the `mediaUrl`/`referenceId` contract. | Define payload shape per `contentType`: what fields required for POST vs STORY vs REEL vs LIKE? |
| A4 | 3.4 Realtime / AC-WS-003 | Typing indicator: "After 3s inactivity, `typing_stop` auto-sent" — is this server-side or client-side responsibility? | If server-side: client must not send `typing_stop`. If client-side: need timer management in ChatViewModel. | Explicitly state: **Client sends `typing_stop` after 3s local inactivity** OR **Server auto-broadcasts `typing_stop`**. |
| A5 | 3.4 Realtime / AC-WS-004 | Call signaling messages relayed but no guarantee of ordering or deduplication. | CallService state machine could receive duplicate/out-of-order ICE candidates. | Specify: Are signaling messages ordered? Deduplicated? Retransmission policy? |
| A6 | 5.1 Database / `messages` table | `contentType` enum has `POST`, `STORY`, `REEL`, `LIKE` but `referenceId` is nullable. When is it required? | MessageEntity mapping needs to know when `referenceId` is mandatory for deserialization. | Define: `referenceId` required for `POST`/`STORY`/`REEL`/`LIKE`, optional for `TEXT`/`IMAGE`/`VIDEO`/`AUDIO`. |
| A7 | 4.1 / `/conversations/{id}/messages` | Cursor pagination for messages but no `sortOrder` parameter. Default sort? | Message list could load newest-first or oldest-first — affects UI scroll position. | Add `sort` param (`asc`/`desc` default `desc` for newest-first). |
| A8 | 3.2 Profile / AC-PROF-002 | Two update endpoints: PUT `/v1/user/me` (full) and PUT `/v1/user/profile` (name only). No guidance on when to use which. | EditProfileViewModel needs to know which endpoint to call for partial vs full updates. | Document: Use `/user/profile` for name-only (iOS), `/user/me` for full profile (web/admin). |

---

## 2. Missing Edge Cases (Blocking for iOS)

| # | Area | Missing Edge Case | Why It Blocks iOS |
|---|------|-------------------|-------------------|
| M1 | **Offline / Optimistic UI** | No specification for offline mutation queue, conflict resolution, or sync protocol. | iOS **must** implement optimistic likes/saves/comments with rollback. Without spec, each feature invents its own — inconsistency. |
| M2 | **Image/Video Upload** | Presigned URL flow defined but no **resume/upload progress** WebSocket events. | Large video uploads (Reels) need progress UI. No way to show progress without server events. |
| M3 | **Push Notification Payload** | APNs payload structure not defined. Only `device_token` registration. | iOS needs exact payload keys for `UNNotificationContent` (badge, sound, custom data for routing). |
| M4 | **Story Viewer Pagination** | `/stories/feed` returns all story groups at once. No pagination for users with 500+ followed accounts. | StoriesBarView will OOM loading 500+ story groups with thumbnails. Need cursor pagination. |
| M5 | **Reel View Tracking** | `POST /reels/{id}/view` increments count but no debounce spec. Client could spam. | ReelsViewModel needs to know: call once per session? Once per 10s? Once per visible duration? |
| M6 | **WebSocket Reconnection** | Protocol mentions heartbeat but no **missed message catch-up** protocol. | After reconnect, ChatViewModel has gaps. Need `sync` message or `lastReadAt` based fetch. |
| M7 | **Blocked User Behavior** | Block API exists but no spec on: does block hide existing conversations? Remove follower? | DirectMessagesViewModel needs to know: hide conversation? Show "blocked" badge? Auto-delete messages? |
| M8 | **Close Friends Story** | Story creation has no `closeFriendsOnly` flag in `CreateStoryRequest`. | StoryCameraViewModel can't implement "Close Friends" audience selector. |
| M9 | **Message Edit/Unsend** | Only `delete_message` in WebSocket. No `edit_message` or `unsend` (delete for everyone). | Chat UX requires unsend (Instagram has it). Missing from spec = can't implement. |
| M10 | **Search Ranking** | `/user/search` and `/posts/explore` have no ranking signals (recency, relevance, graph distance). | ExploreViewModel can't implement "Top" vs "Recent" tabs without backend contract. |

---

## 3. Over-Specification (YAGNI for iOS)

| # | Section | Over-Spec Detail | Why It's Over-Spec for iOS |
|---|---------|------------------|---------------------------|
| O1 | 7. Security / Password Hashing | `scrypt (N=16384, r=16, p=1, dkLen=64)` | iOS never hashes passwords — backend concern. Remove from client-facing spec. |
| O2 | 7. Security / SQL Injection | "Drizzle ORM parameterized queries only" | iOS doesn't write SQL. Implementation detail. |
| O3 | 5.1 Database Schema | Full Drizzle table definitions with column types | iOS only needs entity shapes (already in OpenAPI schemas). DB schema leaks implementation. |
| O4 | 11.1 Environment Variables | Full `.env` with Neon, Better Auth, Resend, S3 keys | iOS only needs `APP_BASE_URL`, `API_MODE`. Secrets belong in backend. |
| O5 | 3.4 WebSocket / Message Format | Full JSON examples for every message type | OpenAPI `components/schemas` already defines shapes. Duplicate maintenance burden. |
| O6 | 8. Performance Baselines | Cold start < 2s, DB query p95 < 100ms | Backend SLOs. iOS cares about **API p95 < 200ms** (already listed) and **WS latency < 50ms**. |

---

## 4. iOS-Specific Gaps (Not in SPEC but Required)

| # | Gap | Required for iOS | Suggested Addition to SPEC |
|---|-----|------------------|---------------------------|
| G1 | **App Version / Force Update** | `AC-AUTH-002` mentions 426 force-update but no version check endpoint. | Add `GET /v1/app/version` returning `{ minVersion, currentVersion, forceUpdate }`. |
| G2 | **Maintenance Mode** | `AppState` checks 503 but no scheduled maintenance window API. | Add `GET /v1/app/maintenance` returning `{ isUnderMaintenance, message, estimatedEnd }`. |
| G3 | **Deep Link Contract** | Universal links for `instagram://post/{id}`, `instagram://user/{id}`, `instagram://reel/{id}`. | Define URL schemes + associated domains in SPEC. |
| G4 | **Localization Keys** | API returns English error messages only. | Add `Accept-Language` header contract; error responses include `errorCode` for client-side i18n. |
| G5 | **Rate Limit Headers** | No `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `Retry-After` in responses. | iOS needs to implement exponential backoff — requires headers. |
| G6 | **Media CDN / Thumbnail Variants** | `MediaItem` has `thumbnailUrl` but no size variants (small/medium/large). | Feed/Explore/Profile grids need different thumbnail sizes. Add `thumbnails: { small, medium, large }`. |
| G7 | **Story/Reel Expiry** | Stories have `expiresAt` but no `timeRemaining` for client countdown. | StoryViewerViewModel computes locally but server time drift causes bugs. Add `expiresInSeconds`. |
| G8 | **Conversation Unread Count** | `/conversations/` returns `lastMessage` but no `unreadCount` per conversation. | DirectMessagesViewModel shows badge — needs unread count without extra fetch. |

---

## 5. Contract Violations (SPEC vs Current iOS Code)

| # | SPEC Contract | Current iOS Implementation | Gap |
|---|---------------|---------------------------|-----|
| C1 | Cursor pagination (timestamp) | MockDataSource uses page-based `page`/`perPage` | Need to migrate Mock → Remote with cursor logic |
| C2 | WebSocket `typing_stop` auto-sent by server | ChatViewModel sends `typing_stop` on 3s timer | Double `typing_stop` if both client+server send |
| C3 | `Post` mediaItems include `thumbnailUrl` | PostCardView uses `RemoteImageView` with single URL | Need to use `thumbnailUrl` for feed, full `url` for detail |
| C4 | `Conversation` has `lastMessage` optional | DirectMessagesViewModel expects non-optional | Handle nil lastMessage (new conversation) |
| C5 | `User.isFollowing` / `isBlocked` computed | ProfileViewModel fetches separately | Use computed fields from API to reduce requests |

---

## 6. Recommendations (Priority Order)

### P0 — Must Fix Before Sprint 2 iOS Work
1. **Define cursor pagination format** (timestamp vs opaque) — blocks Feed/Reels/Chat infinite scroll
2. **Add WebSocket missed-message catch-up protocol** — blocks real-time chat reliability
3. **Define push notification APNs payload** — blocks notification routing
4. **Add `closeFriendsOnly` to Story creation** — blocks Story Camera feature
5. **Add message unsend/edit to WebSocket** — blocks Chat parity with Instagram

### P1 — Should Fix Early Sprint 2
6. **Add story feed pagination** — blocks StoriesBarView for power users
7. **Add conversation `unreadCount`** — blocks DM list badges
8. **Define media thumbnail variants** — blocks Feed/Explore/Profile image optimization
9. **Add rate limit headers** — blocks proper retry/backoff
10. **Add deep link contract** — blocks universal links

### P2 — Nice to Have
11. **Add app version/force update endpoint**
12. **Add maintenance window endpoint**
13. **Add `Accept-Language` + error codes for i18n**
14. **Remove over-spec sections (O1-O6) from client-facing SPEC**

---

## 7. Dissent Record

**iOS Dev Dissent:** SPEC.md mixes backend implementation details (DB schema, password hashing, env vars) with client contracts. This violates **SSOT (Single Source of Truth)** — client should consume a **client-facing API spec** (OpenAPI only), not backend internals.

**Recommendation:** Split SPEC.md into:
- `SPEC-API.md` — OpenAPI 3.1 + WebSocket protocol (client-facing)
- `SPEC-BACKEND.md` — DB schema, security internals, env vars (backend-only)

---

**Red Team Verdict:** SPEC.md is **NOT READY** for iOS Sprint 2 implementation without P0 clarifications. BA must resolve P0 items before iOS Dev can create accurate work plans.

**Next Step:** BA to address P0 items → iOS Dev creates Sprint 2 work plans → PM approval → Execution.

---

*End of RED_TEAM_REPORT.md*