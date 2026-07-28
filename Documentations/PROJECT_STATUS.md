# Instagram Clone — Project Status

> Last updated: 2026-07-28

---

## Architecture

**Pattern:** Clean Architecture + MVVM  
**Min iOS:** 18.0  
**Swift:** 5.0  
**Xcode:** 26.3  
**Concurrency:** Swift Concurrency (async/await) + Combine  
**DI:** Swinject (module-based assemblies)  
**Navigation:** NavigationStack (per-tab) + centralized AppRouter  

---

## Dependencies

| Library | Version | Purpose | Wrapper Created |
|---------|---------|---------|-----------------|
| Alamofire | 5.12.0 | Networking | ✅ NetworkService |
| Nuke | 13.0.6 (local) | Image loading | ✅ ImageLoader, RemoteImageView, ImagePipeline |
| Swinject | 2.10.0 | DI Container | ✅ DIContainer + Assemblies |
| CombineExt | 1.9.0 | Reactive extensions | ✅ CombineExtHelpers |
| PopupView | 5.0.3 | Toast/popup UI | ✅ ToastManager |
| Pow | 1.0.6 | Animations | ✅ AnimationModifier |
| SkeletonUI | 2.0.2 | Loading placeholders | ✅ ShimmerModifier |
| ProgressHUD | 15.0.1 | Loading HUD | ✅ HUDManager |

---

## Layer Completion Status

### Core Infrastructure

- [x] AppConfig / Environment (dev/staging/prod)
- [x] AppLogger (OSLog categories)
- [x] KeychainManager
- [x] BiometricAuthenticator
- [x] PermissionService
- [x] DI Container (6 assemblies: Network, Service, Repository, UseCase, ViewModel)
- [x] NetworkService (request/requestEnvelope/requestVoid/upload/download + Combine)
- [x] APIEndpoint protocol + all endpoint enums
- [x] RequestInterceptor (auth token + retry)
- [x] AuthManager (token storage, refresh, logout)
- [x] WebSocket (thread-safe, auto-reconnect, exponential backoff + jitter, connection state)
- [x] WebSocket Message Handler (chat + call signaling + presence)
- [x] CallKit integration (CallManager + CXProvider)
- [x] CallService (state machine, coordinates WebSocket ↔ CallKit)
- [x] Push Notification Service (APNs registration, categories, routing)
- [x] VoIP Push Service (PushKit, incoming call handling)
- [x] Notification Router (tap → navigation)
- [x] Image Filter Engine (Metal-backed CIContext singleton)
- [x] Image Filter Presets (12 Instagram-style filters via CIFilter chains)
- [x] LUT Loader (.png + .cube file support, cached)
- [x] Filter Thumbnail Generator (concurrent, cached at 150x150)
- [x] Camera Filter Renderer (AVCapture → CIFilter → MTKView real-time)

### Domain Layer

- [x] Entities: User, Post, Story, Comment, Reel, Message, Conversation, AppNotification
- [x] Repository Protocols: Auth, User, Post, Story, Comment, Message, Notification, Reel
- [x] UseCases: Login, Register, FetchFeed, ToggleLike, FetchProfile, ToggleFollow, FetchStories, SearchUsers, FetchNotifications, FetchComments, AddComment, FetchPostDetail, CreatePost, FetchReels, ToggleLikeReel, FetchMessages, SendMessage, UpdateProfile, FetchFollowers, FetchFollowing
- [x] Base types: UseCase protocol, PaginationInput, NoInput, AuthSession
- [x] Error types: APIError, AuthError, ValidationError, CallServiceError, WebSocketError, LUTError

### Data Layer

- [x] MockData (users, posts, stories, comments, notifications, conversations)
- [x] Mock DataSources: Auth, User, Post, Story, Notification, Message, Comment, Reel
- [x] Repository implementations (all using Mock DataSources, including Comment + Reel)
- [x] Remote DataSources (real API calls via NetworkService): Post, User, Comment, Story, Reel, Message, Notification
- [x] DTOs (API response models): User, Post, Comment, Story, Reel, Message, Notification, PaginatedResponse
- [x] Mappers (DTO ↔ Entity): User, Post, Comment, Story, Reel, Message, Notification, Date
- [x] Repositories refactored: remote-first with mock fallback (AppConfig.isMockAPI toggle)
- [x] Instagram API Endpoints: Post, User, Comment, Story, Reel, Conversation, Notification

### Persistence Layer

- [x] LocalStorageProtocol (abstract)
- [x] InMemoryStorage (for dev/tests)
- [x] SwiftData container factory
- [x] SwiftData storage (skeleton)
- [ ] SwiftData @Model definitions (User, Post, Message cache)
- [ ] Offline sync strategy

### Presentation Layer

- [x] Navigation: AppRouter, AppRoute, AppTab, AppSheet, AppFullScreen
- [x] MainTabView (5 tabs with NavigationStack)
- [x] Auth: LoginView + AuthViewModel (login/register toggle)
- [x] Feed: FeedView + PostCardView + FeedViewModel (pagination, like)
- [x] Profile: ProfileView + ProfileViewModel (stats, grid, follow)
- [x] Explore: ExploreView + ExploreViewModel (grid + search)
- [x] Stories: StoriesBarView + StoryCircleView
- [x] Notifications: NotificationsView + NotificationsViewModel
- [x] Direct Messages: DirectMessagesView + DirectMessagesViewModel
- [x] Call: CallView + CallViewModel (audio/video, incoming/active controls)
- [x] Create Post: FilterSelectionView (preview + filter strip + intensity)
- [x] Post Detail View (full post + comments + like + add comment)
- [x] Comments View (threaded replies, reply indicator, pagination)
- [x] Create Post Flow (PhotosPicker, filter selection, caption, location, share)
- [x] Story Viewer (full-screen, progress bars, auto-advance, tap/swipe navigation)
- [x] Story Camera (capture photo/video, filters, edit tools, publish to story/close friends)
- [x] Chat/Conversation View (message bubbles, text/image/audio/video/like, status indicators)
- [x] Edit Profile View (avatar picker, name/bio/website, character counter)
- [x] Settings View (notifications, privacy, security, data, logout)
- [x] Reels Player (vertical paging, full-screen, action buttons, audio track)
- [x] Followers/Following List (searchable, follow/unfollow, pagination)
- [x] Likes List (user list with follow buttons, search)
- [x] Search Results (tabs: top/accounts/tags/places, grid + list)
- [x] Hashtag Page (header with post count, follow, post grid)
- [x] Location Page (map placeholder, directions, post grid)
- [x] Media Viewer (full-screen, pinch zoom, drag dismiss)
- [x] Share Post sheet (search contacts, quick share, send as DM, copy link)
- [x] Report Post sheet (10 report reasons, submit, confirmation)
- [x] Create Reel (camera + gallery picker, duration selector, editor, publish)
- [x] Dark Mode (ThemeManager, ColorTokens, theme picker in Settings)

### Design System

- [x] RemoteImageView (Nuke)
- [x] ImageLoader, ImagePrefetcher, ImageProcessors, ImageCachePolicy, ImagePipelineManager
- [x] ToastManager (PopupView wrapper)
- [x] HUDManager (ProgressHUD wrapper)
- [x] ShimmerModifier + SkeletonListView + SkeletonCardView
- [x] AnimationModifier + AppTransition + AppChangeEffect
- [x] CombineExt helpers
- [x] Theme system (AppTheme, ThemeManager, ColorTokens, FontTokens, SpacingTokens)

---

## What's Next (Priority Order)

### Phase 2: Core Feature Completion (Base UI Done ✅)

1. [x] Create Post full flow (photo picker, crop, filter, caption, post)
2. [x] Chat/Conversation screen (message bubbles, text input, send via WebSocket)
3. [x] Post Detail View (full post + comments)
4. [x] Comments View (list + add comment)
5. [x] Story Viewer (full-screen with progress, swipe between users)
6. [x] Edit Profile screen

### Phase 3: Advanced Features

7. [x] Reels Player (vertical paging, video playback — base UI done, needs AVPlayer)
8. [x] Story Camera (capture + filters + edit tools + publish — base UI done, needs real AVCaptureSession)
9. [x] Settings screen (notifications, privacy, account)
10. [ ] WebRTC integration (actual audio/video media for calls)
11. [x] Search: hashtags, locations, posts (SearchResultsView with tabs)
12. [x] Followers/Following list screens

### Phase 4: Polish & Production

13. [x] Real API integration (Remote DataSources + DTOs + Mappers + Endpoints — ready, switch API_MODE=live to activate)
14. [ ] SwiftData offline cache
15. [ ] Pagination improvements (cursor-based)
16. [ ] Deep link handling
17. [x] Dark mode / Theming (ThemeManager + ColorTokens + system/light/dark toggle)
18. [ ] Localization (Vietnamese + English)
19. [ ] Accessibility (VoiceOver, Dynamic Type)
20. [ ] Unit tests + snapshot tests
21. [ ] Performance optimization (lazy loading, prefetch)

---

## Technical Notes & Warnings

### Image Filters
- `FilterEngine.shared` uses a SINGLE `CIContext` backed by Metal — never create additional contexts.
- CIContext is configured with `cacheIntermediates: false` for video/camera performance.
- Filters build a lazy CIImage graph — no pixel work until `render()` is called.
- Thumbnail generation: source image is downscaled ONCE to 150x150, then each filter applies to the tiny image (fast).
- LUT data is parsed once and cached via `NSCache` — subsequent loads are O(1).
- Camera preview renders CIImage directly to `MTLTexture` via `CIContext.render(to:)` — zero CPU roundtrip.
- `alwaysDiscardsLateVideoFrames = true` prevents frame backup when filter is expensive.
- For custom LUT filters: place `.cube` or `.png` files in the app bundle, call `LUTLoader.loadFromPNG(named:)` or `LUTLoader.loadFromCubeFile(named:)`.

### WebSocket
- `WebSocketService` uses a serial `DispatchQueue` for all mutable state.
- `isConnected` is only true after `URLSessionWebSocketDelegate.didOpen` callback.
- Reconnect uses exponential backoff + random jitter (prevent thundering herd).
- Ping interval: 25 seconds.
- Max reconnect attempts: 5.
- `WebSocketConnectionState` enum tracks: `.disconnected`, `.connecting`, `.connected`, `.reconnecting(attempt:)`.

### CallKit / VoIP Push
- **CRITICAL:** VoIP push handler (`PKPushRegistryDelegate.didReceiveIncomingPush`) MUST report a call to `CXProvider` before the callback returns. Failure = app terminated by iOS.
- CallKit requires `Background Modes > Voice over IP` capability in Xcode.
- VoIP push requires a separate APNs VoIP certificate.
- `CallService` is `@MainActor` — all call state mutations happen on main thread.
- Ring timeout: 45 seconds.
- Call state machine: `idle → initiating → ringing → connecting → connected → ended`.

### Push Notifications
- Requires `Push Notifications` capability.
- Requires `Background Modes > Remote notifications` for silent pushes.
- Notification categories: MESSAGE (reply action), LIKE (view post), FOLLOW (view profile).
- Token (both APNs device token and VoIP token) must be sent to backend after registration.

### Navigation
- Each tab has its own `NavigationPath` — prevents cross-tab navigation conflicts.
- `AppRouter.shared` is `@Observable` — no need for `@EnvironmentObject`.
- Auth state check in `ContentView`: `isAuthenticated` toggles between LoginView ↔ MainTabView.

### DI Container
- `DIContainer.shared` initialized in `InstagramApp.init()`.
- Assembly order matters: Service → Repository → UseCase → ViewModel (dependency chain).
- `@Injected` property wrapper resolves from container at init time — not lazy.
- ViewModels currently instantiated directly in Views (for simplicity). Can be migrated to use `@Injected` when DI is fully wired.

### Mock Data
- All mock data sources simulate network delay (0.3–0.8s) via `Task.sleep`.
- Mock images use `picsum.photos` and `i.pravatar.cc` — requires internet.
- MockData is in `Data/DataSources/Mock/MockData.swift` — single source of truth for fake data.

### Concurrency
- Project uses `SWIFT_APPROACHABLE_CONCURRENCY = YES` and `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
- ViewModels are `@MainActor @Observable`.
- Repositories are `@unchecked Sendable` (safe because they delegate to stateless mock sources).
- Domain entities are all `Sendable`.
- `FilterThumbnailGenerator` is an `actor` — thread-safe by design.

---

## File Structure Overview

```
Instagram/
├── Application/
│   ├── ContentView.swift               (auth routing: Login ↔ MainTab)
│   └── InstagramApp.swift              (@main entry, DI init)
├── Common/
│   ├── Constants/AppConstants.swift
│   ├── Errors/APIErrors.swift
│   └── Extensions/
│       ├── Extensions.swift
│       └── CombineExtHelpers.swift
├── Config/
│   └── AppEnvironment.swift            (AppEnvironment + AppConfig)
├── Core/
│   ├── Calling/
│   │   ├── CallManager.swift           (CXProvider + CXCallController)
│   │   └── CallService.swift           (state machine + coordination)
│   ├── DI/
│   │   ├── DIContainer.swift           (singleton + @Injected)
│   │   ├── NetworkAssembly.swift
│   │   ├── RepositoryAssembly.swift
│   │   ├── ServiceAssembly.swift
│   │   ├── UseCaseAssembly.swift
│   │   └── ViewModelAssembly.swift
│   ├── ImageFilter/
│   │   ├── CameraFilterRenderer.swift  (AVCapture → CIFilter → MTKView)
│   │   ├── FilterEngine.swift          (Metal CIContext singleton)
│   │   ├── FilterThumbnailGenerator.swift
│   │   ├── ImageFilter.swift           (protocol + 12 presets)
│   │   └── LUTLoader.swift             (.png/.cube → CIColorCube)
│   ├── Logging/AppLogger.swift
│   ├── Networking/
│   │   ├── APIEndPoint.swift
│   │   ├── NetworkService.swift
│   │   ├── RequestInterceptor.swift
│   │   └── Endpoints/
│   │       ├── PostEndpoint.swift
│   │       ├── UserEndpoints.swift
│   │       ├── CommentEndpoint.swift
│   │       ├── StoryEndpoint.swift
│   │       ├── ReelEndpoint.swift
│   │       ├── MessageEndpoints.swift
│   │       └── NotificationEndpoint.swift
│   ├── PermissionHandler/
│   │   ├── PermissionService.swift
│   │   └── SystemPermissionService.swift
│   ├── PushNotification/
│   │   ├── NotificationRouter.swift
│   │   ├── PushNotificationService.swift
│   │   └── VoIPPushService.swift
│   ├── Security/
│   │   ├── AuthManager.swift
│   │   ├── BiometricAuthenticator.swift
│   │   └── KeychainManager.swift
│   └── WebSocket/
│       ├── WebSocketMessageHandler.swift
│       └── WebSocketService.swift
├── Data/
│   ├── DataSources/Mock/
│   │   ├── MockAuthDataSource.swift
│   │   ├── MockCommentDataSource.swift
│   │   ├── MockData.swift
│   │   ├── MockMessageDataSource.swift
│   │   ├── MockNotificationDataSource.swift
│   │   ├── MockPostDataSource.swift
│   │   ├── MockReelDataSource.swift
│   │   ├── MockStoryDataSource.swift
│   │   └── MockUserDataSource.swift
│   ├── DataSources/Remote/
│   │   ├── RemoteCommentDataSource.swift
│   │   ├── RemoteMessageDataSource.swift
│   │   ├── RemoteNotificationDataSource.swift
│   │   ├── RemotePostDataSource.swift
│   │   ├── RemoteReelDataSource.swift
│   │   ├── RemoteStoryDataSource.swift
│   │   └── RemoteUserDataSource.swift
│   ├── DTOs/
│   │   ├── CommentDTO.swift
│   │   ├── MessageDTO.swift
│   │   ├── NotificationDTO.swift
│   │   ├── PaginatedResponseDTO.swift
│   │   ├── PostDTO.swift
│   │   ├── ReelDTO.swift
│   │   ├── StoryDTO.swift
│   │   └── UserDTO.swift
│   ├── Mappers/
│   │   ├── CommentMapper.swift
│   │   ├── DateMapper.swift
│   │   ├── MessageMapper.swift
│   │   ├── NotificationMapper.swift
│   │   ├── PostMapper.swift
│   │   ├── ReelMapper.swift
│   │   ├── StoryMapper.swift
│   │   └── UserMapper.swift
│   └── Repositories/
│       ├── AuthRepository.swift
│       ├── CommentRepository.swift
│       ├── MessageRepository.swift
│       ├── NotificationRepository.swift
│       ├── PostRepository.swift
│       ├── ReelRepository.swift
│       ├── StoryRepository.swift
│       └── UserRepository.swift
├── Domain/
│   ├── Entities/
│   │   ├── Comment.swift
│   │   ├── Message.swift
│   │   ├── Notification.swift
│   │   ├── Post.swift
│   │   ├── Reel.swift
│   │   ├── Story.swift
│   │   └── User.swift
│   ├── Repositories/          (protocols only)
│   │   ├── AuthRepositoryProtocol.swift
│   │   ├── CommentRepositoryProtocol.swift
│   │   ├── MessageRepositoryProtocol.swift
│   │   ├── NotificationRepositoryProtocol.swift
│   │   ├── PostRepositoryProtocol.swift
│   │   ├── ReelRepositoryProtocol.swift
│   │   ├── StoryRepositoryProtocol.swift
│   │   └── UserRepositoryProtocol.swift
│   └── UseCases/
│       ├── UseCase.swift               (base protocol)
│       ├── Auth/LoginUseCase.swift
│       ├── Auth/RegisterUseCase.swift
│       ├── Comment/FetchCommentsUseCase.swift
│       ├── Comment/AddCommentUseCase.swift
│       ├── Feed/FetchFeedUseCase.swift
│       ├── Feed/FetchPostDetailUseCase.swift
│       ├── Feed/CreatePostUseCase.swift
│       ├── Feed/ToggleLikePostUseCase.swift
│       ├── Message/FetchMessagesUseCase.swift
│       ├── Message/SendMessageUseCase.swift
│       ├── Notification/FetchNotificationsUseCase.swift
│       ├── Profile/FetchProfileUseCase.swift
│       ├── Profile/ToggleFollowUseCase.swift
│       ├── Profile/UpdateProfileUseCase.swift
│       ├── Profile/FetchFollowersUseCase.swift
│       ├── Reel/FetchReelsUseCase.swift
│       ├── Reel/ToggleLikeReelUseCase.swift
│       ├── Search/SearchUsersUseCase.swift
│       └── Story/FetchStoriesUseCase.swift
├── Persistence/
│   ├── InMemoryStorage.swift
│   ├── LocalStorageProtocol.swift
│   └── SwiftData/
│       ├── SwiftDataContainerFactory.swift
│       └── SwiftDataStorage.swift
├── Presentations/
│   ├── Auth/
│   │   ├── AuthViewModel.swift
│   │   └── LoginView.swift
│   ├── Call/
│   │   ├── CallView.swift
│   │   └── CallViewModel.swift
│   ├── Chat/
│   │   ├── ChatView.swift
│   │   └── ChatViewModel.swift
│   ├── Comments/
│   │   ├── CommentsView.swift
│   │   └── CommentsViewModel.swift
│   ├── CreatePost/
│   │   ├── CreatePostView.swift
│   │   ├── CreatePostViewModel.swift
│   │   └── FilterSelectionView.swift
│   ├── DirectMessages/
│   │   ├── DirectMessagesView.swift
│   │   └── DirectMessagesViewModel.swift
│   ├── EditProfile/
│   │   ├── EditProfileView.swift
│   │   └── EditProfileViewModel.swift
│   ├── Explore/
│   │   ├── ExploreView.swift
│   │   └── ExploreViewModel.swift
│   ├── Feed/
│   │   ├── FeedView.swift
│   │   ├── FeedViewModel.swift
│   │   └── PostCardView.swift
│   ├── Navigation/
│   │   ├── AppRoute.swift
│   │   ├── AppRouter.swift
│   │   └── MainTabView.swift
│   ├── Notifications/
│   │   ├── NotificationsView.swift
│   │   └── NotificationsViewModel.swift
│   ├── PostDetail/
│   │   ├── PostDetailView.swift
│   │   └── PostDetailViewModel.swift
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   └── ProfileViewModel.swift
│   ├── Reels/
│   │   ├── ReelsView.swift
│   │   └── ReelsViewModel.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── SettingsViewModel.swift
│   ├── StoryCamera/
│   │   ├── StoryCameraView.swift
│   │   └── StoryCameraViewModel.swift
│   ├── FollowList/
│   │   ├── FollowListView.swift
│   │   └── FollowListViewModel.swift
│   ├── LikesList/
│   │   ├── LikesListView.swift
│   │   └── LikesListViewModel.swift
│   ├── Search/
│   │   ├── SearchResultsView.swift
│   │   └── SearchResultsViewModel.swift
│   ├── Hashtag/
│   │   ├── HashtagView.swift
│   │   └── HashtagViewModel.swift
│   ├── Location/
│   │   ├── LocationView.swift
│   │   └── LocationViewModel.swift
│   ├── MediaViewer/
│   │   └── MediaViewerView.swift
│   └── Stories/
│       ├── StoriesBarView.swift
│       ├── StoryViewerView.swift
│       └── StoryViewerViewModel.swift
├── Resources/
│   ├── Assets/Assets.xcassets/
│   ├── DesignSystem/
│   │   ├── Animation/AnimationModifier.swift
│   │   ├── HUD/HUDManager.swift
│   │   ├── Image/ (6 files)
│   │   ├── Skeleton/ShimmerModifier.swift
│   │   └── Toast/ToastManager.swift
│   └── Localization/
└── Documentations/
    ├── PROJECT_STATUS.md               ← You are here
    └── SKILLS_AND_ACHIEVEMENTS.md
```
