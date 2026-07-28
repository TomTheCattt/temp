# Development Notes

> Ghi chú kỹ thuật, tips, pitfalls, và hướng dẫn cho quá trình phát triển.

---

## Khi thêm Feature mới

### Checklist (theo thứ tự)

1. **Entity** — Tạo struct trong `Domain/Entities/` (nếu cần model mới)
2. **Repository Protocol** — Thêm method vào protocol trong `Domain/Repositories/`
3. **UseCase** — Tạo file trong `Domain/UseCases/{Feature}/`
4. **Mock DataSource** — Thêm fake data/method vào `Data/DataSources/Mock/`
5. **Repository Implementation** — Implement method mới trong `Data/Repositories/`
6. **DI Registration** — Register UseCase trong `UseCaseAssembly`, ViewModel trong `ViewModelAssembly`
7. **ViewModel** — Tạo file trong `Presentations/{Feature}/`
8. **View** — Tạo file trong `Presentations/{Feature}/`
9. **Route** — Thêm case vào `AppRoute` enum, thêm destination vào `MainTabView`
10. **Test** — (khi ready) Viết unit test cho UseCase và ViewModel

### Ví dụ: Thêm "Block User" feature

```
1. User entity đã có `isBlocked` field ✓
2. UserRepositoryProtocol: đã có `block(userId:)` ✓
3. Tạo Domain/UseCases/Profile/BlockUserUseCase.swift
4. MockUserDataSource: đã có simulateDelay ✓
5. UserRepository: đã có block() ✓
6. UseCaseAssembly: register BlockUserUseCaseProtocol
7. ProfileViewModel: thêm func blockUser() async
8. ProfileView: thêm button trong menu
9. Route: không cần (action tại chỗ)
```

---

## Khi integrate Real API

### Migration Steps (per feature)

1. Tạo DTO struct trong `Data/DTOs/` (match JSON response)
2. Tạo Mapper trong `Data/Mappers/` (DTO → Entity)
3. Tạo Remote DataSource trong `Data/DataSources/Remote/`
4. Update Repository để dùng Remote (giữ Mock cho fallback/preview)

### Repository Pattern khi có cả Remote + Local

```swift
final class PostRepository: PostRepositoryProtocol {
    private let remoteDataSource: RemotePostDataSource
    private let localStorage: LocalStorageProtocol
    
    func fetchFeed(page: Int, perPage: Int) async throws -> [Post] {
        do {
            // Try remote first
            let posts = try await remoteDataSource.fetchFeed(page: page, perPage: perPage)
            // Cache locally
            try? await localStorage.saveAll(posts)
            return posts
        } catch {
            // Fallback to cached data
            if let cached = try? await localStorage.fetchAll(Post.self) {
                return cached
            }
            throw error
        }
    }
}
```

---

## Performance Tips

### Memory

- `LazyImage` (NukeUI) tự cancel khi cell đi khỏi viewport — không cần manual cancel.
- `LazyVStack` / `LazyVGrid` — Views chỉ tạo khi visible.
- Filter thumbnails cached trong `FilterThumbnailGenerator` — invalidate khi đổi ảnh nguồn.
- LUT data cached trong `NSCache` — tự evict khi memory pressure.

### CPU/GPU

- CIFilter chain = lazy graph. Không tốn CPU cho đến khi `.render()`.
- Camera preview: render trực tiếp CIImage → MTLTexture. Không qua UIImage/CGImage.
- Thumbnail generation: downscale ảnh gốc 1 lần, apply 12 filters trên ảnh nhỏ (150x150) — tổng < 100ms.
- Background rendering: sử dụng `Task { }` — không block main thread.

### Network

- Pagination: `page + perPage` pattern, load more khi last item visible.
- Optimistic updates: update UI ngay, revert nếu API fail.
- WebSocket: chỉ 1 connection, multiplex tất cả real-time features qua message types.

---

## Pitfalls & Gotchas

### 1. CIContext — NEVER create multiple

```swift
// ❌ WRONG: Creates new context PER FRAME — catastrophic perf
func processFrame(_ buffer: CVPixelBuffer) {
    let context = CIContext() // 💀
    ...
}

// ✅ CORRECT: Use singleton
let context = FilterEngine.shared.ciContext
```

### 2. @Observable + State init

```swift
// ❌ WRONG: ViewModel recreated every re-render
struct FeedView: View {
    var viewModel = FeedViewModel(...)  // Missing @State!
}

// ✅ CORRECT: @State preserves across re-renders
struct FeedView: View {
    @State private var viewModel = FeedViewModel(...)
}
```

### 3. NavigationPath type safety

```swift
// ❌ WRONG: Pushing a type not registered in .navigationDestination
router.push(.someNewRoute)  // But MainTabView doesn't handle it → crash

// ✅ CORRECT: Always add case to routeDestination() in MainTabView FIRST
```

### 4. VoIP Push — Must report call

```swift
// ❌ WRONG: Doing async work before reporting
func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPush...) {
    Task { 
        let user = await fetchUser(...)  // ⏰ Too slow — iOS kills app!
        try await CallManager.shared.reportIncomingCall(...)
    }
}

// ✅ CORRECT: Report IMMEDIATELY with available data
func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPush...) {
    let callId = payload["call_id"] as? String ?? UUID().uuidString
    let name = payload["caller_name"] as? String ?? "Unknown"
    Task {
        try await CallManager.shared.reportIncomingCall(uuid: UUID(), callId: callId, callerName: name, ...)
    }
}
```

### 5. Sendable compliance

```swift
// ❌ WRONG: Mutable class captured in async context
class DataManager {
    var items: [Item] = []  // Not Sendable!
}

// ✅ Options:
// A) Use actor
actor DataManager { var items: [Item] = [] }

// B) Use @unchecked Sendable with manual synchronization
final class DataManager: @unchecked Sendable {
    private let queue = DispatchQueue(...)
    private var items: [Item] = []
}
```

### 6. WebSocket reconnect race condition

WebSocket reconnect đã được handle bằng:
- Serial `DispatchQueue` cho mutable state
- `shouldReconnect` flag kiểm tra trước mỗi reconnect attempt
- `guard shouldReconnect else { return }` sau sleep delay

KHÔNG gọi `connect()` manually khi đang trong reconnect loop.

---

## Thêm Custom LUT Filter

### Bước 1: Chuẩn bị file

**PNG format (recommended):**
- Size: 512x512 pixels (cho 64-size cube: 8x8 grid, mỗi tile 64x64)
- Format: RGB hoặc RGBA, 8-bit per channel
- Tạo trong Photoshop/Lightroom: apply color grading lên identity LUT → export PNG

**Cube format:**
- Standard `.cube` text file (exported từ DaVinci Resolve, Photoshop, etc.)

### Bước 2: Add to project

Drop file vào `Resources/Assets/` hoặc bundle root.

### Bước 3: Load và register

```swift
// In FilterRegistry or a custom setup function:
do {
    let lutData = try LUTLoader.loadFromPNG(named: "my_custom_filter", dimension: 64)
    let filter = LUTFilter(id: "my_custom", displayName: "My Filter", lutData: lutData, dimension: 64)
    // Add to registry or use directly
} catch {
    AppLogger.general.error("Failed to load LUT: \(error)")
}
```

---

## SwiftData Integration (khi ready)

### Bước 1: Tạo @Model

```swift
// Persistence/SwiftData/Models/SDPost.swift
@Model
final class SDPost {
    @Attribute(.unique) var id: String
    var caption: String?
    var authorId: String
    var likesCount: Int
    var createdAt: Date
    // ... minimal fields for offline cache
}
```

### Bước 2: Mapper

```swift
// Data/Mappers/PostMapper.swift
enum PostMapper {
    static func toEntity(_ sdPost: SDPost, author: User) -> Post { ... }
    static func toModel(_ post: Post) -> SDPost { ... }
}
```

### Bước 3: Register in container factory

```swift
// SwiftDataContainerFactory.create()
let schema = Schema([SDPost.self, SDUser.self, ...])
```

---

## Testing Strategy (khi implement)

### Unit Test structure

```
Tests/
├── Domain/
│   └── UseCases/
│       ├── LoginUseCaseTests.swift      (mock AuthRepository)
│       └── FetchFeedUseCaseTests.swift   (mock PostRepository)
├── Data/
│   └── Repositories/
│       └── PostRepositoryTests.swift    (mock DataSources)
└── Presentations/
    └── ViewModels/
        └── FeedViewModelTests.swift     (mock UseCases)
```

### Mock strategy

```swift
// Mỗi protocol → tạo Mock class cho testing
final class MockPostRepository: PostRepositoryProtocol {
    var fetchFeedResult: [Post] = []
    var fetchFeedError: Error?
    
    func fetchFeed(page: Int, perPage: Int) async throws -> [Post] {
        if let error = fetchFeedError { throw error }
        return fetchFeedResult
    }
}
```

---

## Xcode Capabilities cần enable

- [x] Push Notifications
- [x] Background Modes:
  - [x] Voice over IP
  - [x] Remote notifications
  - [x] Background fetch
- [ ] Associated Domains (cho deep links — khi cần)
- [ ] App Groups (nếu có share extension)

---

## Environment Variables (xcconfig)

```
// Development.xcconfig
APP_ENVIRONMENT = dev
APP_BASE_URL = https://dev-api.example.com
APP_USE_LOCAL_BACKEND = 0
API_MODE = mock

// Staging.xcconfig
APP_ENVIRONMENT = staging
APP_BASE_URL = https://staging-api.example.com
API_MODE = live

// Production.xcconfig
APP_ENVIRONMENT = prod
APP_BASE_URL = https://api.example.com
API_MODE = live
```

Hiện tại dùng `API_MODE = mock` → tất cả data từ MockDataSources.  
Khi backend ready: đổi sang `live` → Repositories dùng RemoteDataSource.

---

## Folder nào cho file nào?

| Bạn đang tạo... | Đặt ở đâu |
|-----------------|-----------|
| Model mới (User, Post...) | `Domain/Entities/` |
| API method mới | `Domain/Repositories/{Name}Protocol.swift` |
| Business logic | `Domain/UseCases/{Feature}/` |
| Fake data | `Data/DataSources/Mock/` |
| API call implementation | `Data/DataSources/Remote/` (TODO) |
| Repository implementation | `Data/Repositories/` |
| Screen mới | `Presentations/{Feature}/` |
| Shared UI component | `Resources/DesignSystem/{Category}/` |
| Infrastructure utility | `Core/{Category}/` |
| DI registration | `Core/DI/{Module}Assembly.swift` |
| Offline cache model | `Persistence/SwiftData/Models/` |
| Route mới | `Presentations/Navigation/AppRoute.swift` |
