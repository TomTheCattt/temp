---
inclusion: auto
---

# Feature → File Map

When developing a feature, read ONLY the relevant files listed below. Do NOT scan the entire project.

---

## Authentication (Login, Register, Token, Logout)

- #[[file:Domain/Entities/User.swift]]
- #[[file:Domain/Repositories/AuthRepositoryProtocol.swift]]
- #[[file:Domain/UseCases/Auth/LoginUseCase.swift]]
- #[[file:Domain/UseCases/Auth/RegisterUseCase.swift]]
- #[[file:Data/DataSources/Mock/MockAuthDataSource.swift]]
- #[[file:Data/Repositories/AuthRepository.swift]]
- #[[file:Core/Security/AuthManager.swift]]
- #[[file:Core/Security/KeychainManager.swift]]
- #[[file:Presentations/Auth/AuthViewModel.swift]]
- #[[file:Presentations/Auth/LoginView.swift]]

---

## Feed (Home feed, posts, like)

- #[[file:Domain/Entities/Post.swift]]
- #[[file:Domain/Repositories/PostRepositoryProtocol.swift]]
- #[[file:Domain/UseCases/Feed/FetchFeedUseCase.swift]]
- #[[file:Domain/UseCases/Feed/ToggleLikePostUseCase.swift]]
- #[[file:Data/DataSources/Mock/MockPostDataSource.swift]]
- #[[file:Data/Repositories/PostRepository.swift]]
- #[[file:Presentations/Feed/FeedViewModel.swift]]
- #[[file:Presentations/Feed/FeedView.swift]]
- #[[file:Presentations/Feed/PostCardView.swift]]

---

## Profile (User profile, follow, edit)

- #[[file:Domain/Entities/User.swift]]
- #[[file:Domain/Repositories/UserRepositoryProtocol.swift]]
- #[[file:Domain/UseCases/Profile/FetchProfileUseCase.swift]]
- #[[file:Domain/UseCases/Profile/ToggleFollowUseCase.swift]]
- #[[file:Data/DataSources/Mock/MockUserDataSource.swift]]
- #[[file:Data/Repositories/UserRepository.swift]]
- #[[file:Presentations/Profile/ProfileViewModel.swift]]
- #[[file:Presentations/Profile/ProfileView.swift]]

---

## Explore & Search

- #[[file:Domain/Repositories/UserRepositoryProtocol.swift]]
- #[[file:Domain/Repositories/PostRepositoryProtocol.swift]]
- #[[file:Domain/UseCases/Search/SearchUsersUseCase.swift]]
- #[[file:Data/DataSources/Mock/MockUserDataSource.swift]]
- #[[file:Data/DataSources/Mock/MockPostDataSource.swift]]
- #[[file:Presentations/Explore/ExploreViewModel.swift]]
- #[[file:Presentations/Explore/ExploreView.swift]]

---

## Stories

- #[[file:Domain/Entities/Story.swift]]
- #[[file:Domain/Repositories/StoryRepositoryProtocol.swift]]
- #[[file:Domain/UseCases/Story/FetchStoriesUseCase.swift]]
- #[[file:Data/DataSources/Mock/MockStoryDataSource.swift]]
- #[[file:Data/Repositories/StoryRepository.swift]]
- #[[file:Presentations/Stories/StoriesBarView.swift]]

---

## Notifications

- #[[file:Domain/Entities/Notification.swift]]
- #[[file:Domain/Repositories/NotificationRepositoryProtocol.swift]]
- #[[file:Domain/UseCases/Notification/FetchNotificationsUseCase.swift]]
- #[[file:Data/DataSources/Mock/MockNotificationDataSource.swift]]
- #[[file:Data/Repositories/NotificationRepository.swift]]
- #[[file:Presentations/Notifications/NotificationsViewModel.swift]]
- #[[file:Presentations/Notifications/NotificationsView.swift]]

---

## Direct Messages (Chat)

- #[[file:Domain/Entities/Message.swift]]
- #[[file:Domain/Repositories/MessageRepositoryProtocol.swift]]
- #[[file:Data/DataSources/Mock/MockMessageDataSource.swift]]
- #[[file:Data/Repositories/MessageRepository.swift]]
- #[[file:Core/WebSocket/WebSocketService.swift]]
- #[[file:Core/WebSocket/WebSocketMessageHandler.swift]]
- #[[file:Presentations/DirectMessages/DirectMessagesViewModel.swift]]
- #[[file:Presentations/DirectMessages/DirectMessagesView.swift]]

---

## Calling (VoIP, CallKit)

- #[[file:Core/WebSocket/WebSocketMessageHandler.swift]] (call signaling messages)
- #[[file:Core/Calling/CallManager.swift]]
- #[[file:Core/Calling/CallService.swift]]
- #[[file:Core/PushNotification/VoIPPushService.swift]]
- #[[file:Presentations/Call/CallViewModel.swift]]
- #[[file:Presentations/Call/CallView.swift]]

---

## Push Notifications

- #[[file:Core/PushNotification/PushNotificationService.swift]]
- #[[file:Core/PushNotification/VoIPPushService.swift]]
- #[[file:Core/PushNotification/NotificationRouter.swift]]

---

## Image Filters & Camera

- #[[file:Core/ImageFilter/FilterEngine.swift]]
- #[[file:Core/ImageFilter/ImageFilter.swift]]
- #[[file:Core/ImageFilter/LUTLoader.swift]]
- #[[file:Core/ImageFilter/FilterThumbnailGenerator.swift]]
- #[[file:Core/ImageFilter/CameraFilterRenderer.swift]]
- #[[file:Presentations/CreatePost/FilterSelectionView.swift]]

---

## Navigation & Routing

- #[[file:Presentations/Navigation/AppRoute.swift]]
- #[[file:Presentations/Navigation/AppRouter.swift]]
- #[[file:Presentations/Navigation/MainTabView.swift]]
- #[[file:Application/ContentView.swift]]

---

## Dependency Injection

- #[[file:Core/DI/DIContainer.swift]]
- #[[file:Core/DI/ServiceAssembly.swift]]
- #[[file:Core/DI/RepositoryAssembly.swift]]
- #[[file:Core/DI/UseCaseAssembly.swift]]
- #[[file:Core/DI/ViewModelAssembly.swift]]
- #[[file:Core/DI/NetworkAssembly.swift]]

---

## Networking (API calls)

- #[[file:Core/Networking/APIEndPoint.swift]]
- #[[file:Core/Networking/NetworkService.swift]]
- #[[file:Core/Networking/RequestInterceptor.swift]]
- #[[file:Common/Errors/APIErrors.swift]]

---

## Persistence & Storage

- #[[file:Persistence/LocalStorageProtocol.swift]]
- #[[file:Persistence/InMemoryStorage.swift]]
- #[[file:Persistence/SwiftData/SwiftDataContainerFactory.swift]]
- #[[file:Persistence/SwiftData/SwiftDataStorage.swift]]
- #[[file:Core/Security/KeychainManager.swift]]

---

## Design System (shared UI components)

- #[[file:Resources/DesignSystem/Toast/ToastManager.swift]]
- #[[file:Resources/DesignSystem/HUD/HUDManager.swift]]
- #[[file:Resources/DesignSystem/Skeleton/ShimmerModifier.swift]]
- #[[file:Resources/DesignSystem/Animation/AnimationModifier.swift]]
- #[[file:Resources/DesignSystem/Image/RemoteImageView.swift]]
- #[[file:Resources/DesignSystem/Image/ImageLoader.swift]]

---

## WebSocket (shared real-time transport)

- #[[file:Core/WebSocket/WebSocketService.swift]]
- #[[file:Core/WebSocket/WebSocketMessageHandler.swift]]

---

## Mock Data (for all features)

- #[[file:Data/DataSources/Mock/MockData.swift]]

---

## App Configuration & Environment

- #[[file:Config/AppEnvironment.swift]]
- #[[file:Common/Constants/AppConstants.swift]]
- #[[file:Application/InstagramApp.swift]]

---

## How to use this map

1. Identify which feature area your task belongs to
2. Read ONLY the files listed under that section
3. If a task spans multiple features (e.g., "add message notification that navigates to chat"), read files from BOTH relevant sections
4. For DI changes, always also read the corresponding Assembly file
5. For new routes, always also read Navigation section files
