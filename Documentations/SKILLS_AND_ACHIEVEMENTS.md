# Skills & Achievements — Instagram Clone Project

> Tài liệu thể hiện các kiến thức, kỹ năng và tính năng đã triển khai thành công trong dự án.  
> Last updated: 2026-07-26

---

## Tổng quan dự án

Xây dựng bản sao đầy đủ của Instagram trên iOS, từ kiến trúc nền tảng đến UI/UX hoàn chỉnh. Dự án thể hiện khả năng thiết kế hệ thống, quản lý kiến trúc phần mềm quy mô lớn, và triển khai các tính năng phức tạp trên nền tảng Apple.

---

## Kiến trúc & Design Patterns

### Đã triển khai

- [x] **Clean Architecture** — Tách biệt rõ ràng Domain / Data / Presentation layers
- [x] **MVVM** — ViewModel đóng vai trò trung gian giữa View và UseCase
- [x] **Repository Pattern** — Abstraction layer giữa Domain và Data sources
- [x] **UseCase Pattern** — Mỗi business action là một UseCase riêng biệt, dễ test
- [x] **Dependency Injection** — Swinject với module-based Assembly, hỗ trợ testability
- [x] **Protocol-Oriented Design** — Mọi dependency đều thông qua protocol, không phụ thuộc concrete type
- [x] **Observer Pattern** — Combine publishers cho reactive data flow
- [x] **State Machine** — Call state machine với finite states rõ ràng
- [x] **Singleton (có kiểm soát)** — DIContainer, AppRouter, CallManager, FilterEngine với clear ownership
- [x] **Actor Pattern** — FilterThumbnailGenerator, InMemoryStorage dùng Swift actor cho thread safety

### Sẽ triển khai

- [ ] **Coordinator Pattern** (nếu cần mở rộng navigation phức tạp hơn)
- [ ] **Factory Pattern** cho ViewModel creation
- [ ] **Strategy Pattern** cho caching policies

---

## Swift & iOS Platform Skills

### Swift Language

- [x] Swift Concurrency (async/await, Task, TaskGroup)
- [x] Actors (`@ModelActor` cho SwiftData, actor-based InMemoryStorage + FilterThumbnailGenerator)
- [x] Sendable compliance cho toàn bộ Domain entities
- [x] `@Observable` macro (iOS 17+) thay thế ObservableObject
- [x] Property Wrappers (`@Injected` custom wrapper)
- [x] Generics (LocalStorageProtocol, UseCase protocol với associated types)
- [x] Protocol extensions với default implementations
- [x] Opaque types (`some View`, `some ChangeEffect`)
- [x] Result builders (`@ViewBuilder`)

### SwiftUI

- [x] NavigationStack với type-safe routing
- [x] TabView với per-tab navigation state
- [x] LazyVStack / LazyVGrid cho performance
- [x] Pull-to-refresh (`refreshable`)
- [x] Searchable modifier
- [x] Sheet / FullScreenCover management
- [x] Custom ViewModifiers (Toast, HUD, Shimmer)
- [x] Animation (implicit, explicit, matched geometry)
- [x] Gesture handling (double-tap like)
- [x] UIViewRepresentable (MTKView for camera filter preview)

### Frameworks & APIs

- [x] **Metal** — MTLDevice, MTLCommandQueue, MTLTexture rendering cho image filters
- [x] **Core Image** — CIFilter chains, CIContext, CIColorCube, real-time processing pipeline
- [x] **AVFoundation** — AVCaptureSession, video data output, audio session management
- [x] **MetalKit** — MTKView cho real-time camera filter preview
- [x] **CallKit** — CXProvider, CXCallController, native call UI
- [x] **PushKit** — VoIP push notifications, background wake
- [x] **UserNotifications** — APNs registration, categories, actions (inline reply)
- [x] **URLSession WebSocket** — Native WebSocket với auto-reconnect
- [x] **SwiftData** — ModelContainer, @ModelActor, persistence abstraction
- [x] **Security** — Keychain Services API (SecItem)
- [x] **LocalAuthentication** — Biometric (Face ID / Touch ID)
- [x] **OSLog** — Structured logging với categories
- [x] **Combine** — Publishers, Subjects, operators, cancellables

---

## Image Processing & Filters

### Đã triển khai

- [x] **Metal-backed CIContext** — Single GPU context cho toàn app, optimized options
- [x] **12 Instagram-style filter presets** — CIFilter chain (colorControls, toneCurve, temperatureAndTint, colorMatrix, vignette, hueAdjust, sharpenLuminance)
- [x] **LUT (Look-Up Table) support** — Load từ .png grid và .cube text files
- [x] **CIColorCubeWithColorSpace** — GPU-accelerated LUT application
- [x] **LUT caching** — NSCache cho parsed LUT data (parse once, reuse)
- [x] **Filter intensity control** — Dissolve blend giữa original và filtered (0–100%)
- [x] **Thumbnail generation** — Concurrent TaskGroup, downscale once then batch apply
- [x] **Real-time camera filter** — AVCapture → CIImage → CIFilter → MTLTexture → MTKView
- [x] **Zero-copy pipeline** — CIImage từ CVPixelBuffer (Metal-backed), render trực tiếp to texture
- [x] **Frame drop prevention** — `alwaysDiscardsLateVideoFrames` cho camera stream

### Sẽ triển khai

- [ ] **Custom Metal shaders** cho advanced effects (distortion, AR-like)
- [ ] **Video filter export** — Apply filter chain to video via AVAssetWriter
- [ ] **LUT generation tool** — Export custom LUTs từ app
- [ ] **Adjustments UI** — Brightness, contrast, saturation, warmth manual sliders

---

## Networking & Real-time Communication

### Đã triển khai

- [x] **RESTful API client** (Alamofire) với generic request/response handling
- [x] **Request interceptor** — Tự động attach auth token + refresh khi 401
- [x] **API Endpoint abstraction** — Protocol-based, type-safe endpoint definitions
- [x] **Error handling** — Typed errors, HTTP status mapping, network error classification
- [x] **WebSocket** — Thread-safe (serial DispatchQueue), auto-reconnect với exponential backoff + jitter
- [x] **Connection state tracking** — `.disconnected`, `.connecting`, `.connected`, `.reconnecting(attempt:)`
- [x] **Real-time messaging** — Typed incoming/outgoing messages qua WebSocket
- [x] **Call signaling** — Full WebRTC signaling protocol (offer/answer/ICE/hangup/reject/busy/ringing)
- [x] **Presence** — User online/offline events
- [x] **Multipart upload** support
- [x] **Download** với custom destination

### Sẽ triển khai

- [ ] **WebRTC** — Actual peer-to-peer audio/video media
- [ ] **Certificate pinning** cho production security
- [ ] **Offline queue** — Retry failed requests khi có network lại
- [ ] **GraphQL** (nếu backend yêu cầu)

---

## Calling (VoIP)

### Đã triển khai

- [x] **CallKit integration** — Native iOS call UI (incoming/outgoing)
- [x] **Call state machine** — idle → initiating → ringing → connecting → connected → ended
- [x] **Call signaling via WebSocket** — offer, answer, ICE candidate, hangup, reject, busy, ringing
- [x] **VoIP Push** — Wake app từ background cho incoming calls (PushKit)
- [x] **Audio session management** — voiceChat mode, Bluetooth, speaker toggle
- [x] **Call UI** — Full-screen call view (audio + video layout), incoming/active controls
- [x] **Ring timeout** — Auto-end sau 45s không trả lời
- [x] **Mute / Speaker toggle**
- [x] **Camera switch** (front/back) preparation

### Sẽ triển khai

- [ ] **WebRTC PeerConnection** — Actual media streaming
- [ ] **ICE/TURN/STUN** server configuration
- [ ] **Video rendering** — RTCMTLVideoView integration
- [ ] **Screen sharing**
- [ ] **Group calls**

---

## Push Notifications

### Đã triển khai

- [x] **APNs registration** & token management
- [x] **Permission request** flow
- [x] **Notification categories** — MESSAGE (reply action), LIKE (view post), FOLLOW (view profile)
- [x] **Inline reply** action cho tin nhắn
- [x] **Foreground display** — Banner + sound khi app đang mở
- [x] **Tap navigation** — Route đến đúng screen khi user tap notification
- [x] **Badge management**
- [x] **VoIP push** — Riêng biệt, wake app cho incoming calls
- [x] **Silent push** handling (background fetch)
- [x] **Payload parsing** — Typed PushNotificationPayload struct

### Sẽ triển khai

- [ ] **Rich notifications** — Image/video preview trong notification
- [ ] **Notification Service Extension** — Decrypt/modify content trước khi hiển thị
- [ ] **Notification grouping** — Thread identifiers
- [ ] **Communication notifications** (iOS 15+) — Avatar trong notification

---

## Data & Persistence

### Đã triển khai

- [x] **Persistence abstraction** — Protocol-based, framework-agnostic (dễ swap SwiftData ↔ CoreData)
- [x] **SwiftData** setup (ModelContainer, @ModelActor)
- [x] **In-memory storage** — Cho development và unit tests
- [x] **Mock data layer** — Realistic fake data cho UI development (simulated delay)
- [x] **Keychain** — Secure token storage

### Sẽ triển khai

- [ ] **SwiftData models** — Cache posts, messages, user profiles offline
- [ ] **Sync strategy** — Last-write-wins hoặc conflict resolution
- [ ] **Image disk cache** (đã có via Nuke, cần fine-tune policy)
- [ ] **Data migration** strategy

---

## UI/UX Implementation

### Đã triển khai

- [x] **Feed** — Infinite scroll, pull-to-refresh, double-tap like animation
- [x] **Profile** — Stats, bio, photo grid (3-col), follow/unfollow, grid picker (posts/reels/tagged)
- [x] **Explore** — 3-column grid, user search with `.searchable`
- [x] **Stories bar** — Horizontal scroll, gradient ring (viewed/unviewed), "Your Story"
- [x] **Notifications** — Typed rows (like, comment, follow, mention), unread highlight, post thumbnail
- [x] **Direct Messages** — Conversation list, unread badge, last message preview, muted indicator
- [x] **Call screen** — Audio/video layout, incoming/active states, duration timer, PiP local video
- [x] **Auth** — Login/register form, validation, error feedback, password visibility toggle
- [x] **Filter picker** — Full preview + horizontal thumbnail strip + intensity slider
- [x] **Design System** — Toast, HUD, Skeleton, Animations (reusable across app)

### Sẽ triển khai

- [ ] **Chat bubbles** — Message list, input bar, media messages
- [ ] **Story viewer** — Full-screen, auto-advance, progress bars
- [ ] **Create post full flow** — Photo picker, crop, filters, caption, share
- [ ] **Reels** — Vertical paging video player
- [ ] **Comments** — Threaded, like, reply
- [ ] **Dark mode** — Full theming support
- [ ] **iPad** — Adaptive layout

---

## Security

### Đã triển khai

- [x] Keychain storage cho tokens (kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
- [x] Biometric authentication (Face ID / Touch ID)
- [x] Auth token auto-refresh khi expired
- [x] Secure headers (Bearer token, client version, environment)
- [x] AuthManager — centralized token lifecycle management

### Sẽ triển khai

- [ ] Certificate pinning
- [ ] App Transport Security customization
- [ ] Jailbreak detection
- [ ] Data encryption at rest
- [ ] Secure enclave cho sensitive keys

---

## Testing (Planned)

- [ ] Unit tests cho UseCases (pure logic, no dependencies)
- [ ] Unit tests cho ViewModels (mock repositories)
- [ ] Integration tests cho Repositories (mock vs real data sources)
- [ ] Snapshot tests cho UI components (swift-snapshot-testing — already in deps)
- [ ] UI tests cho critical flows (login, post, message)

---

## DevOps & Tooling

- [x] Xcode 26.3 project configuration
- [x] SPM dependency management
- [x] Multi-environment support (dev/staging/prod via xcconfig)
- [x] Structured logging (OSLog)
- [x] Technical documentation (PROJECT_STATUS.md + SKILLS_AND_ACHIEVEMENTS.md)

### Sẽ triển khai

- [ ] CI/CD pipeline
- [ ] Fastlane automation
- [ ] Crash reporting (Firebase Crashlytics hoặc Sentry)
- [ ] Analytics
- [ ] Feature flags

---

## Soft Skills thể hiện

- **System Design** — Thiết kế kiến trúc toàn bộ app từ đầu, phân chia layer rõ ràng
- **Technical Decision Making** — Chọn đúng pattern cho đúng problem (Clean Arch cho scalability, MVVM cho testability, Metal cho GPU performance)
- **Performance Engineering** — Filter pipeline tối ưu (lazy CIImage, single CIContext, zero-copy camera), thumbnail batch generation
- **Code Organization** — Folder structure có logic, naming convention nhất quán, separation of concerns
- **Forward Thinking** — Thiết kế persistence layer dễ swap, mock data layer cho parallel UI development, protocol-first design
- **Production Mindset** — Error handling, retry logic, timeout, reconnect strategy, thread safety
- **Real-time Systems** — WebSocket lifecycle management, call state machine, signaling protocol
- **Documentation** — Self-documenting code + technical documentation

---

## Summary

| Category | Completed | Planned | Total |
|----------|-----------|---------|-------|
| Architecture & Patterns | 10 | 3 | 13 |
| Swift & iOS Skills | 30 | 0 | 30 |
| Image Processing | 10 | 4 | 14 |
| Networking | 10 | 4 | 14 |
| Calling (VoIP) | 9 | 5 | 14 |
| Push Notifications | 10 | 4 | 14 |
| Data & Persistence | 5 | 4 | 9 |
| UI/UX Screens | 10 | 7 | 17 |
| Security | 5 | 5 | 10 |
| **Total** | **99** | **36** | **135** |

> **Tiến độ tổng thể: ~73% foundation + core features hoàn thành.**  
> Remaining: chủ yếu là UI screens chi tiết, WebRTC media, real API integration, và polish.
