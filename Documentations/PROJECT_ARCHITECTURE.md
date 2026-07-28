# Project Architecture

> Tài liệu mô tả chi tiết kiến trúc phần mềm của dự án Instagram Clone.

---

## High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Presentations                              │
│   SwiftUI Views ←→ @Observable ViewModels                        │
│   (Navigation, Auth, Feed, Profile, Explore, Stories, Call, DM)  │
├──────────────────────────────────────────────────────────────────┤
│                          Domain                                   │
│   Entities (pure structs) + UseCases + Repository Protocols       │
│   ⚠️ NO framework imports — pure Swift only                      │
├──────────────────────────────────────────────────────────────────┤
│                           Data                                    │
│   Repository Impls → DataSources (Mock / Remote / Local)         │
│   DTOs + Mappers (khi integrate real API)                        │
├──────────────────────────────────────────────────────────────────┤
│                       Core (Shared)                               │
│   DI, Networking, WebSocket, Calling, PushNotification,          │
│   Security, Logging, ImageFilter, PermissionHandler              │
├──────────────────────────────────────────────────────────────────┤
│                       Persistence                                 │
│   LocalStorageProtocol ← SwiftData / InMemory                    │
├──────────────────────────────────────────────────────────────────┤
│                    Resources / DesignSystem                       │
│   Image, Toast, HUD, Skeleton, Animation, Assets, Localization   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### Typical Read Flow

```
View → ViewModel.loadData()
         → UseCase.execute(input)
             → Repository.fetch(...)
                 → DataSource (Mock/Remote/Local)
                     → returns Entity
             ← Entity
         ← update @Observable state
View re-renders
```

### Typical Write Flow (with optimistic update)

```
View → ViewModel.toggleLike()
         → Update local state immediately (optimistic)
         → UseCase.execute(input)
             → Repository.likePost(id)
                 → DataSource → API call
         ← Success: keep state
         ← Failure: revert state
```

### Real-time Flow (WebSocket)

```
WebSocketService receives frame
    → WebSocketMessageHandler parses type
        → emits typed WebSocketIncomingMessage via Combine
            → CallService / ChatViewModel / etc. subscribe and react
```

---

## Layer Details

### Domain Layer (`Domain/`)

```
Domain/
├── Entities/           Pure data models (struct, Sendable)
├── Repositories/       Protocols ONLY — no implementations
└── UseCases/           Business logic, one action per class
    ├── UseCase.swift   Base protocol + shared types
    ├── Auth/
    ├── Feed/
    ├── Profile/
    ├── Story/
    ├── Search/
    └── Notification/
```

**Rules:**
- Zero framework dependencies (no UIKit, SwiftUI, Alamofire, etc.)
- All types are `Sendable`
- UseCases contain validation logic
- Repositories are protocol-only here

### Data Layer (`Data/`)

```
Data/
├── DataSources/
│   ├── Mock/           Fake data for UI development
│   ├── Remote/         (TODO) Real API calls via NetworkService
│   └── Local/          (TODO) SwiftData queries
├── Repositories/       Concrete implementations
├── DTOs/               (TODO) API response models
└── Mappers/            (TODO) DTO ↔ Entity conversion
```

**Rules:**
- Repositories decide data source priority (remote-first, cache-first, etc.)
- Mock DataSources simulate network delay for realistic UI testing
- When adding real API: create Remote DataSource, keep Mock for preview/tests

### Presentation Layer (`Presentations/`)

```
Presentations/
├── Navigation/         AppRouter, Routes, MainTabView
├── Auth/               Login/Register
├── Feed/               Home feed
├── Profile/            User profiles
├── Explore/            Search + discover grid
├── Stories/            Stories bar
├── Notifications/      Activity feed
├── DirectMessages/     Chat list
├── Call/               Audio/video call UI
└── CreatePost/         Post creation + filters
```

**Rules:**
- Each feature has: `{Feature}View.swift` + `{Feature}ViewModel.swift`
- Shared UI components go in `Resources/DesignSystem/`
- Navigation ONLY via `AppRouter` — no inline `NavigationLink(destination:)`

### Core Layer (`Core/`)

```
Core/
├── Calling/            CallKit + CallService state machine
├── DI/                 Swinject container + assemblies
├── ImageFilter/        Metal CIContext + filters + camera renderer
├── Logging/            OSLog wrapper
├── Networking/         Alamofire + endpoints + interceptor
├── PermissionHandler/  System permissions
├── PushNotification/   APNs + PushKit + routing
├── Security/           Auth, Keychain, Biometric
└── WebSocket/          URLSession WebSocket + message handler
```

**Rules:**
- Core is shared infrastructure — any layer can import Core
- Core does NOT import Data, Domain, or Presentations
- Singletons are acceptable here (FilterEngine, CallManager, AppLogger)

### Persistence Layer (`Persistence/`)

```
Persistence/
├── LocalStorageProtocol.swift     Abstract interface
├── InMemoryStorage.swift          Dev/test implementation
└── SwiftData/
    ├── SwiftDataContainerFactory.swift
    └── SwiftDataStorage.swift     Production implementation
```

**Rules:**
- Domain never imports SwiftData directly
- Repositories access persistence via `LocalStorageProtocol`
- Easy to swap SwiftData → CoreData → Realm without touching other layers

---

## Dependency Injection

### Assembly Chain

```
DIContainer.init()
    → ServiceAssembly      (KeychainManager, AuthManager, ImageLoader, WebSocket, LocalStorage)
    → RepositoryAssembly   (AuthRepo, UserRepo, PostRepo, StoryRepo, NotificationRepo, MessageRepo)
    → UseCaseAssembly      (Login, Register, FetchFeed, ToggleLike, FetchProfile, ...)
    → ViewModelAssembly    (AuthVM, FeedVM, ExploreVM, NotificationsVM, DMVM)
```

### Scope

| Scope | Usage | Example |
|-------|-------|---------|
| `.container` | Singleton (shared instance) | AuthManager, Repositories, WebSocket |
| `.transient` | New instance per resolve | ViewModels |

---

## Navigation Architecture

### Structure

```
ContentView
├── (not authenticated) → LoginView
└── (authenticated) → MainTabView
    ├── Tab: Feed → NavigationStack(feedPath)
    ├── Tab: Explore → NavigationStack(explorePath)
    ├── Tab: Reels → NavigationStack(reelsPath)
    ├── Tab: Notifications → NavigationStack(notificationsPath)
    └── Tab: Profile → NavigationStack(profilePath)
```

### AppRouter (Centralized)

- `@Observable` singleton
- Holds `NavigationPath` per tab
- Methods: `push`, `pop`, `popToRoot`, `switchTab`, `present(sheet:)`, `present(fullScreen:)`, `dismiss`, `reset`
- Auth state: `isAuthenticated` controls root view toggle

### Route Types

| Type | Purpose | Example |
|------|---------|---------|
| `AppRoute` | Push navigation | `.userProfile(userId:)`, `.postDetail(postId:)` |
| `AppSheet` | Modal sheet | `.createPost`, `.sharePost(postId:)` |
| `AppFullScreen` | Full-screen cover | `.camera`, `.mediaViewer(url:)` |

---

## Real-time Architecture

### WebSocket

```
WebSocketService (transport layer)
    ↓ raw events
WebSocketMessageHandler (parsing layer)
    ↓ typed messages via Combine publishers
    ├── .chatMessages → ChatViewModel
    ├── .callSignaling → CallService
    └── .incomingMessages → any subscriber
```

### Call Flow

```
Incoming:
  VoIP Push / WebSocket signal
    → CallManager.reportIncomingCall (CXProvider)
    → iOS shows native call UI
    → User answers → CallService.acceptIncomingCall()
    → Exchange SDP offer/answer via WebSocket
    → Media flows (WebRTC — TODO)

Outgoing:
  User taps call button
    → CallService.initiateCall()
    → CallManager.startOutgoingCall (CXCallController)
    → Send call_initiate via WebSocket
    → Wait for call_ringing / call_answer
    → Exchange SDP → connected
```

---

## Image Filter Pipeline

```
Source (UIImage or CVPixelBuffer)
    → CIImage (zero-copy if Metal-backed)
    → ImageFilter.apply(to:) — builds lazy CIImage graph
    → FilterEngine.apply(filter:to:intensity:) — optional dissolve blend
    → Render target:
        ├── renderToUIImage() — for static preview / export
        ├── renderThumbnail() — for filter picker (150x150)
        ├── render(to: CVPixelBuffer) — for video export
        └── render(to: MTLTexture) — for camera live preview
```

**Key: NO pixel work happens until the final render call.**

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| `@Observable` over `ObservableObject` | Simpler, no need for `@Published`, auto-tracking |
| Per-tab `NavigationPath` | Prevents cross-tab navigation bugs |
| Protocol-first repositories | Easy to swap Mock ↔ Remote, enables testing |
| Single `CIContext` | Metal context is expensive — one per app is optimal |
| Actor for `FilterThumbnailGenerator` | Thread-safe cache without manual locking |
| Combine for WebSocket events | Natural fit for stream-based real-time data |
| UseCases as separate classes | Single responsibility, easy to unit test |
| `Sendable` on all entities | Required for Swift 6 strict concurrency |
| Mock delay simulation | UI behaves realistically during development |
| `@unchecked Sendable` on repositories | Safe because they hold only `Sendable` data sources |
