# Core

Chứa tất cả infrastructure và core services của ứng dụng. Đây là layer cung cấp khả năng kỹ thuật (technical capabilities) mà các feature module sử dụng.

## Cấu trúc

```
Core/
├── Calling/            # Tích hợp CallKit cho voice/video call
├── DI/                 # Dependency Injection container (Swinject)
├── ImageFilter/        # Camera filters (Metal + CoreImage)
├── Logging/            # Structured logging (OSLog)
├── Networking/         # HTTP client (Alamofire)
├── PermissionHandler/  # Quản lý quyền hệ thống (camera, mic, photos...)
├── PushNotification/   # APNs + VoIP push
├── Security/           # Auth, Keychain, Biometrics
├── Video/              # Video playback & thumbnail generation
└── WebSocket/          # Real-time messaging (URLSessionWebSocketTask)
```

---

## Calling/

Tích hợp iOS CallKit để hiển thị native call UI và quản lý audio/video call.

### CallManager.swift

Singleton quản lý `CXProvider` và `CXCallController`.

**Chức năng:**
- Report incoming call (hiển thị native call UI khi nhận VoIP push)
- Start outgoing call (request hệ thống bắt đầu cuộc gọi)
- End/Mute call actions
- Cấu hình audio session (`.playAndRecord`, `.voiceChat`, Bluetooth A2DP)
- Phát sự kiện `CallKitEvent` qua Combine publisher cho `CallService` lắng nghe

**Thread safety:** Serial `DispatchQueue` bảo vệ `activeCalls` dictionary.

### CallService.swift

State machine quản lý toàn bộ lifecycle cuộc gọi.

**Call States (FSM):**
```
Outgoing: idle → initiating → ringing → connecting → connected → ended
Incoming: idle → incomingRinging → connecting → connected → ended
```

**Chức năng:**
- `initiateCall(to:name:hasVideo:)` — bắt đầu cuộc gọi đi
- `acceptIncomingCall()` / `rejectIncomingCall()` — xử lý cuộc gọi đến
- `hangup()` — kết thúc cuộc gọi
- `toggleMute()` / `toggleSpeaker()` — điều khiển audio
- Ring timeout: 45 giây tự động kết thúc nếu không có ai trả lời
- Subscribe to WebSocket signaling + CallKit events

---

## DI/ (Dependency Injection)

Sử dụng **Swinject** làm DI container. Tất cả dependencies được đăng ký tại app launch.

### DIContainer.swift

- `DIContainer.shared` — singleton container
- `resolve<T>(_:)` — resolve dependency, crash (fatalError) nếu không tìm thấy (fail-fast trong DEBUG)
- `resolveOptional<T>(_:)` — trả về nil nếu không đăng ký
- `@Injected<T>` property wrapper — shorthand cho resolve

### Assembly files

| File | Đăng ký |
|------|---------|
| `NetworkAssembly` | Alamofire `Session` (với AuthInterceptor + EventMonitor), `NetworkServiceProtocol` |
| `ServiceAssembly` | `KeychainManager`, `AuthManagerProtocol`, `BiometricAuthenticator`, `ImageLoading`, `WebSocketServiceProtocol`, `LocalStorageProtocol` |
| `RepositoryAssembly` | 8 repositories: Auth, User, Post, Story, Notification, Message, Comment, Reel |
| `UseCaseAssembly` | Tất cả domain use cases (Login, Register, FetchFeed, ToggleLike, etc.) |
| `ViewModelAssembly` | Tất cả ViewModels (Auth, Feed, Explore, Notifications, DirectMessages, Reels, CreatePost, EditProfile, Settings) |

**Object Scopes:**
- `.container` — singleton (services, repositories, network)
- `.transient` (default) — new instance mỗi lần resolve (ViewModels)

---

## ImageFilter/

Hệ thống filter ảnh Instagram-style, render real-time trên camera preview.

### FilterEngine.swift

Singleton rendering engine sử dụng **Metal GPU**.

- Duy nhất 1 `CIContext` backed by Metal command queue — tránh tạo nhiều context
- `apply(filter:to:intensity:)` — áp dụng filter lên CIImage (lazy, chưa render thực)
- `renderToUIImage(_:)` — render CIImage → UIImage (trigger GPU work)
- `renderThumbnail(_:size:)` — render thumbnail 150x150
- Hỗ trợ blend intensity (0.0 → 1.0) giữa ảnh gốc và filtered

### CameraFilterRenderer.swift

Real-time camera preview với filter applied.

**Architecture:** `AVCaptureSession → CMSampleBuffer → CIImage → apply filter → render to MTKView`

- Render ở camera resolution (không downscale) cho preview sắc nét
- `CIContext.render(to: MTLTexture)` — tránh CPU roundtrip
- Switch camera (front/back), capture filtered photo
- SwiftUI wrapper: `CameraFilterView` (UIViewRepresentable + MTKView)

### ImageFilter.swift

Protocol + 12 built-in filters:

| Filter | Style |
|--------|-------|
| Original | Không filter |
| Clarendon | Boost contrast + saturation, cool shadows |
| Gingham | Soft, faded vintage, warm |
| Moon | B&W, high contrast, cool tones |
| Lark | Bright, desaturated greens, boosted blues |
| Juno | Warm, high saturation, vignette |
| Valencia | Warm vintage, slight fade |
| Aden | Soft pastel, desaturated, light haze |
| Nashville | Warm highlights, purple shadows, vignette |
| Inkwell | Classic B&W, strong contrast |
| Lo-Fi | High saturation + contrast, strong vignette |
| Sierra | Soft, slightly desaturated, warm |

### FilterThumbnailGenerator.swift

Batch generate thumbnail previews cho filter picker.
- Downscale ảnh nguồn 1 lần trước khi apply tất cả filters
- Cache kết quả trong memory — re-open picker là instant

### LUTLoader.swift

Load 3D LUT (Look-Up Table) files cho color grading chuyên nghiệp.
- Hỗ trợ `.png` LUT images (grid layout) và `.cube` files (industry standard)
- Cache parsed data via `NSCache`
- `LUTFilter` struct — filter backed by CIColorCube

---

## Logging/

### AppLogger.swift

Structured logging wrapper trên `OSLog` (Apple's unified logging system).

**Categories:**
| Category | Sử dụng cho |
|----------|------------|
| `AppLogger.general` | Logic chung, lifecycle |
| `AppLogger.network` | API requests, responses |
| `AppLogger.storage` | Persistence operations |
| `AppLogger.auth` | Authentication flow |
| `AppLogger.ui` | UI events |

**Log levels:** `debug`, `info`, `notice`, `error`, `fault`

Mỗi log entry tự động include: `[file:line] function → message`

---

## Networking/

HTTP client layer sử dụng **Alamofire**.

### APIEndPoint.swift

- `APIEndpoint` protocol: `baseURL`, `path`, `method`, `headers`, `parameters`, `encoding`
- Default `baseURL` từ `AppConfig.shared.baseURL`
- Default encoding: GET → URLEncoding, POST/PUT → JSONEncoding
- `APIEnvelope<T>` — generic server response wrapper (`success`, `data`, `error`, `message`)
- Định nghĩa nhiều endpoint enums: `AuthEndpoint`, `UserEndpoint`, `PostEndpoint`, etc.

### NetworkService.swift

Concrete HTTP client implementation.

**Methods:**
| Method | Mô tả |
|--------|--------|
| `request<T>(_:)` | Request + decode response thành T |
| `requestEnvelope<T>(_:)` | Request + unwrap `APIEnvelope<T>.data` |
| `requestVoid(_:)` | Request không cần response body (DELETE, 204) |
| `upload<T>(_:multipartFormData:)` | Upload multipart form data |
| `download(_:to:)` | Download file về temporary URL |

- JSONDecoder: `convertFromSnakeCase` + `iso8601WithFractionalSeconds`
- Combine support: `requestPublisher<T>`, `requestEnvelopePublisher<T>`

### RequestInterceptor.swift

**AuthInterceptor:**
- `adapt()` — inject Bearer token + client version + environment vào mọi request
- `retry()` — tự động refresh token khi nhận 401, retry 1 lần, logout nếu refresh thất bại

**NetworkEventMonitor:**
- Log chi tiết request/response (method, URL, headers, body, status code)
- Chỉ active khi `isEnabled = true`

---

## PermissionHandler/

### PermissionService.swift

Protocol abstraction cho system permissions.

**PermissionType:** camera, photoLibrary, microphone, location, locationAlways, notifications, contacts, faceID, tracking

**PermissionStatus:** notDetermined, restricted, limited, denied, authorized, authorizedWhenInUse, provisional

**Convenience methods:** `isGranted(_:)`, `canRequest(_:)`, `statuses(for:)`

### SystemPermissionService.swift

Concrete implementation sử dụng real system APIs: AVFoundation, Photos, Contacts, CoreLocation, LocalAuthentication, UserNotifications, AppTrackingTransparency.

---

## PushNotification/

### PushNotificationService.swift

Quản lý APNs push notifications.

- Request authorization (alert, badge, sound, provisional)
- Handle device token registration
- Parse `PushNotificationPayload` từ userInfo (type, routing info: userId, postId, conversationId)
- Notification categories: MESSAGE (reply inline), LIKE (view post), FOLLOW (view profile)
- Badge management
- `UNUserNotificationCenterDelegate`: foreground display + tap handling

**PushNotificationType:** message, like, comment, follow, mention, liveVideo, callMissed, generic

### VoIPPushService.swift

PushKit VoIP push handler cho incoming calls.

- Register `PKPushRegistry` với `.voIP` type
- **Critical:** PHẢI report call to CallKit trong cùng callback — nếu không iOS terminate app
- Parse call metadata (callId, callerName, hasVideo) từ payload
- Forward tới `CallManager` + `CallService`

### NotificationRouter.swift

Điều hướng navigation khi user tap notification.
- Subscribe to `PushNotificationService.notificationTapped`
- Route theo type: message → DM, like/comment → post detail, follow → profile

---

## Security/

### AuthManager.swift

Quản lý authentication state.

- Store/retrieve access token + refresh token via KeychainManager
- `refreshToken()` — gọi API refresh (hiện tại mock)
- `logout()` — xóa tokens, clear SessionStore, reset AppRouter

### KeychainManager.swift

Wrapper an toàn cho iOS Keychain (Security framework).

- `set(value:key:)` — lưu string (UTF-8 encoded, accessible when unlocked this device only)
- `get(key:)` — đọc string
- `delete(key:)` / `clear()` — xóa

### BiometricAuthenticator.swift

Face ID / Touch ID authentication.

- `canAuthenticate(policy:)` — kiểm tra thiết bị có hỗ trợ không
- `authenticate(reason:policy:)` — trigger biometric prompt
- Policies: `.biometricsOnly`, `.biometricsOrDevicePasscode`

### SessionStore.swift

Lưu thông tin user hiện tại đang đăng nhập.

- `currentUserId` — ID user hiện tại
- `currentUser` — full `User` entity
- Set sau khi login thành công, clear khi logout
- `@MainActor` — chỉ truy cập từ main thread

---

## Video/

### VideoPlayerManager.swift

Quản lý tập trung video playback lifecycle.

**Tối ưu hiệu suất:**
- Giới hạn tối đa 3 AVPlayer concurrent (LRU eviction)
- Preload video tiếp theo (buffer `AVPlayerItem` trước)
- Tự động pause khi app vào background, resume khi active
- `handleMemoryWarning()` — giải phóng tài nguyên khi hệ thống cảnh báo memory

### VideoThumbnailGenerator.swift

Tạo thumbnail từ video URL.

- NSCache (max 50 thumbnails)
- Generate ở background thread (`DispatchQueue.utility`)
- Resolution: 540x960 (half resolution cho performance)
- Time: 0.1s (tránh black frame đầu tiên)

---

## WebSocket/

### WebSocketService.swift

Native WebSocket implementation sử dụng `URLSessionWebSocketTask`.

**Features:**
- Auto-reconnect với exponential backoff + jitter (tránh thundering herd)
- Max 5 reconnect attempts, base delay 2s
- Ping/pong keep-alive mỗi 25 giây
- Thread-safe via serial DispatchQueue
- Connection states: disconnected → connecting → connected → reconnecting(attempt)

### WebSocketMessageHandler.swift

Parse và route WebSocket messages thành typed events.

**Incoming message types:**
- Chat: newMessage, typing, stopTyping, messageRead, messageDeleted
- Presence: userOnline, userOffline
- Call signaling: callIncoming, callOffer, callAnswer, callIceCandidate, callHangup, callReject, callBusy, callRinging
- Notifications

**Outgoing message types:**
- Chat: sendMessage, startTyping, stopTyping, markRead, deleteMessage
- Call signaling: callInitiate, callOffer, callAnswer, callIceCandidate, callHangup, callReject, callBusy, callRinging
- Subscription: subscribe, unsubscribe

**Filtered streams (publishers):**
- `.callSignaling` — chỉ call-related messages
- `.chatMessages` — chỉ chat-related messages
