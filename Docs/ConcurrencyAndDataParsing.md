# Concurrency & Data Parsing — Phân Tích Chi Tiết Dự Án Instagram Clone

> Tài liệu phân tích toàn bộ kiến trúc xử lý dữ liệu, luồng concurrency, cách sử dụng `@MainActor`,
> `Sendable`, `nonisolated`, và các vấn đề hiện tại trong dự án.

---

## Mục Lục

1. [Tổng Quan Kiến Trúc](#1-tổng-quan-kiến-trúc)
2. [Data Pipeline — Luồng Dữ Liệu](#2-data-pipeline--luồng-dữ-liệu)
3. [Concurrency Model](#3-concurrency-model)
4. [Tại Sao Dùng @MainActor](#4-tại-sao-dùng-mainactor)
5. [Isolated vs Non-Isolated](#5-isolated-vs-non-isolated)
6. [Sendable & Thread Safety](#6-sendable--thread-safety)
7. [Vấn Đề Hiện Tại & Warnings](#7-vấn-đề-hiện-tại--warnings)
8. [Giải Pháp Đề Xuất](#8-giải-pháp-đề-xuất)
9. [Changelog — Các Fix Đã Áp Dụng](#9-changelog--các-fix-đã-áp-dụng)

---

## 1. Tổng Quan Kiến Trúc

Dự án sử dụng **Clean Architecture** với 4 layer chính:

```
┌─────────────────────────────────────────────────────────────┐
│  Presentation Layer (SwiftUI Views + ViewModels)            │
│  ─ @MainActor @Observable                                   │
├─────────────────────────────────────────────────────────────┤
│  Domain Layer (Entities + UseCases + Repository Protocols)  │
│  ─ Sendable value types, async throws                       │
├─────────────────────────────────────────────────────────────┤
│  Data Layer (Repositories + DataSources + DTOs + Mappers)   │
│  ─ @unchecked Sendable, nonisolated structs                 │
├─────────────────────────────────────────────────────────────┤
│  Core Layer (Networking + WebSocket + Auth + DI)            │
│  ─ @unchecked Sendable, DispatchQueue, @MainActor           │
└─────────────────────────────────────────────────────────────┘
```

**Nguyên tắc cốt lõi:**
- Dữ liệu chảy **một chiều**: Network → DTO → Mapper → Entity → ViewModel → View
- Mỗi layer chỉ phụ thuộc vào layer bên dưới thông qua protocol (Dependency Inversion)
- UI state chỉ được mutate trên **Main Actor** (thread chính)

---

## 2. Data Pipeline — Luồng Dữ Liệu

### 2.1 Tổng quan pipeline

```
API Response (JSON)
    │
    ▼
PostDTO (Decodable, Sendable, nonisolated struct)
    │  ← JSONDecoder với .convertFromSnakeCase
    ▼
PostMapper.toEntity(_:) (enum, static method)
    │  ← Chuyển đổi kiểu dữ liệu (String → Date, String → URL, etc.)
    ▼
Post (Domain Entity — struct, Sendable, Identifiable)
    │
    ▼
PostRepository (orchestrates Mock/Remote DataSource)
    │
    ▼
FetchFeedUseCase (thin wrapper, single responsibility)
    │
    ▼
FeedViewModel (@MainActor, @Observable)
    │  ← Cập nhật UI state trên main thread
    ▼
SwiftUI View (auto-rerender nhờ @Observable)
```

### 2.2 DTO — Data Transfer Object

**File mẫu:** `Data/DTOs/PostDTO.swift`

```swift
nonisolated struct PostDTO: Decodable, Sendable {
    let id: String
    let author: UserDTO
    let caption: String?
    let mediaItems: [MediaItemDTO]
    let location: PostLocationDTO?
    let likesCount: Int
    let commentsCount: Int
    let createdAt: String        // ← String, chưa parse thành Date
    let isLiked: Bool
    let isSaved: Bool
    let isSponsored: Bool
}
```

**Đặc điểm thiết kế:**
- `nonisolated struct`: Đánh dấu rõ ràng rằng struct không thuộc isolation domain nào
- `Decodable`: Cho phép JSONDecoder parse tự động từ JSON
- `Sendable`: An toàn khi truyền qua các concurrency domain (Task, actor boundary)
- Tất cả property là `let` → immutable → thread-safe tự nhiên
- `createdAt` là `String` (chưa parse) — việc parse để Mapper xử lý

### 2.3 Mapper — Chuyển đổi kiểu dữ liệu

**File mẫu:** `Data/Mappers/PostMapper.swift`

```swift
enum PostMapper {
    static func toEntity(_ dto: PostDTO) -> Post {
        Post(
            id: dto.id,
            author: UserMapper.toEntity(dto.author),
            caption: dto.caption,
            mediaItems: dto.mediaItems.map { toMediaItem($0) },
            location: dto.location.map { toLocation($0) },
            likesCount: dto.likesCount,
            commentsCount: dto.commentsCount,
            createdAt: DateMapper.toDate(dto.createdAt),  // String → Date
            isLiked: dto.isLiked,
            isSaved: dto.isSaved,
            isSponsored: dto.isSponsored
        )
    }
}
```

**Tại sao dùng `enum` thay vì `class`/`struct`?**
- `enum` không có case → không thể tạo instance → đảm bảo stateless
- Chỉ chứa `static func` → thuần functional, không side effect
- Thread-safe tự nhiên vì không có mutable state

**DateMapper — Parse ngày tháng:**

```swift
enum DateMapper {
    private static let iso8601Formatter: ISO8601DateFormatter = { ... }()

    static func toDate(_ string: String) -> Date {
        // Thử ISO8601 with fractional seconds
        // Fallback: ISO8601 without fractional seconds
        // Fallback: Unix timestamp
        // Last resort: .now
    }
}
```

- Formatter được cache static → tránh tạo mới mỗi lần parse (expensive operation)
- `ISO8601DateFormatter` thread-safe (Foundation guarantee)
- Fail-safe: trả về `.now` thay vì crash nếu parse thất bại

### 2.4 Domain Entity

**File mẫu:** `Domain/Entities/Post.swift`

```swift
struct Post: Identifiable, Hashable, Sendable {
    let id: String
    let author: User
    let caption: String?
    let mediaItems: [MediaItem]
    let location: PostLocation?
    let likesCount: Int
    let commentsCount: Int
    let createdAt: Date           // ← Đã là Date, không còn String
    let isLiked: Bool
    let isSaved: Bool
    let isSponsored: Bool
}
```

**Nguyên tắc:**
- Tất cả `let` → immutable → `Sendable` an toàn
- `Identifiable` → SwiftUI List/ForEach optimization
- `Hashable` → NavigationPath, Set operations
- Không có business logic — chỉ là data container

### 2.5 Repository — Orchestration Layer

**File mẫu:** `Data/Repositories/PostRepository.swift`

```swift
final class PostRepository: PostRepositoryProtocol, @unchecked Sendable {
    private let remoteDataSource: RemotePostDataSource
    private let mockDataSource: MockPostDataSource

    func fetchFeed(page: Int, perPage: Int) async throws -> [Post] {
        guard !AppConfig.shared.isMockAPI else {
            return try await mockDataSource.fetchFeed(page: page, perPage: perPage)
        }
        return try await remoteDataSource.fetchFeed(page: page, perPage: perPage)
    }
}
```

**Vai trò:**
- Quyết định data source (Mock vs Remote) dựa trên config
- Abstract hóa cho Domain layer — UseCase không cần biết data từ đâu
- `@unchecked Sendable`: Compiler không kiểm tra — developer tự chịu trách nhiệm

### 2.6 UseCase — Business Logic

**File mẫu:** `Domain/UseCases/Feed/FetchFeedUseCase.swift`

```swift
protocol FetchFeedUseCaseProtocol: Sendable {
    func execute(_ input: PaginationInput) async throws -> [Post]
}

final class FetchFeedUseCase: FetchFeedUseCaseProtocol, Sendable {
    private let postRepository: PostRepositoryProtocol

    func execute(_ input: PaginationInput) async throws -> [Post] {
        try await postRepository.fetchFeed(page: input.page, perPage: input.perPage)
    }
}
```

**Tại sao UseCase mỏng (thin)?**
- Single Responsibility: mỗi UseCase = 1 business action
- Dễ test, dễ compose
- Khi logic phức tạp hơn (validation, caching, combining), UseCase sẽ grow tự nhiên
- Protocol `Sendable` → an toàn truyền qua actor boundary

### 2.7 NetworkService — Async Networking

**File mẫu:** `Core/Networking/NetworkService.swift`

```swift
final class NetworkService: NetworkServiceProtocol, @unchecked Sendable {
    private let session: Session  // Alamofire Session

    nonisolated func request<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint
    ) async throws -> sending T {
        let urlRequest = try endpoint.asURLRequest()
        let response = await session
            .request(urlRequest)
            .validate(statusCode: 200..<300)
            .serializingDecodable(T.self, decoder: decoder)
            .response

        switch response.result {
        case .success(let value): return value
        case .failure(let afError): throw mapError(afError, response: response.response)
        }
    }
}
```

**Keywords quan trọng:**
- `nonisolated func`: Không thuộc isolation domain nào → gọi được từ bất kỳ context nào
- `async throws -> sending T`: `sending` đảm bảo giá trị trả về được "chuyển ownership" an toàn
- `@unchecked Sendable`: Alamofire `Session` thread-safe nội bộ nhưng compiler không biết

---

## 3. Concurrency Model

### 3.1 Tổng quan mô hình concurrency trong dự án

```
┌────────────────────────────────────────────────────────────────┐
│                    MAIN ACTOR (Main Thread)                      │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ FeedViewModel│  │ AuthViewModel│  │ AppRouter             │  │
│  │ @MainActor   │  │ @MainActor   │  │ @MainActor            │  │
│  │ @Observable  │  │ @Observable  │  │ @Observable           │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────────────────┘  │
│         │                  │                                     │
├─────────┼──────────────────┼─────────────────────────────────────┤
│         │ async/await      │ async/await                         │
│         ▼                  ▼                                     │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │         BACKGROUND (Cooperative Thread Pool)              │   │
│  │                                                           │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐  │   │
│  │  │ UseCase      │  │ Repository   │  │ NetworkService│  │   │
│  │  │ Sendable     │  │ @unchecked   │  │ @unchecked    │  │   │
│  │  │              │  │ Sendable     │  │ Sendable      │  │   │
│  │  └──────────────┘  └──────────────┘  └───────────────┘  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │         SERIAL DISPATCH QUEUE (Thread Safety)             │   │
│  │                                                           │   │
│  │  ┌──────────────────────────────────────────────────┐    │   │
│  │  │ WebSocketService                                  │    │   │
│  │  │ queue = DispatchQueue(label: "...websocket")      │    │   │
│  │  │ Mutable state chỉ access trên queue này           │    │   │
│  │  └──────────────────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────┘
```

### 3.2 Luồng thực thi một request điển hình

```
User tap "Refresh" (Main Thread)
    │
    ▼
FeedViewModel.refresh() — @MainActor async
    │  isRefreshing = true  ← UI update (main thread ✓)
    │
    ▼
fetchFeedUseCase.execute(input) — suspension point, nhảy sang background
    │
    ▼
postRepository.fetchFeed() — background thread (cooperative pool)
    │
    ▼
remoteDataSource.fetchFeed() — vẫn background
    │
    ▼
networkService.request(endpoint) — Alamofire async, background
    │  ← JSON decode xảy ra ở đây (background ✓, không block UI)
    │
    ▼
PostMapper.toEntity() — pure function, background
    │  ← String → Date, String → URL conversions
    │
    ▼ (return, hop back to MainActor)
    │
FeedViewModel — posts = result  ← UI update (main thread ✓)
    │  isRefreshing = false
    │
    ▼
SwiftUI re-render (main thread ✓)
```

**Điểm quan trọng:** Swift concurrency tự động "hop" giữa các isolation domain:
- Khi `@MainActor` function gọi `async` function không isolated → chuyển sang background
- Khi background function return cho `@MainActor` caller → tự động hop về main thread

---

## 4. Tại Sao Dùng @MainActor

### 4.1 Lý do cốt lõi

`@MainActor` được áp dụng cho **tất cả ViewModels** và **AppRouter** vì:

1. **SwiftUI yêu cầu UI updates trên main thread**
   - Bất kỳ thay đổi `@Observable` property nào cũng trigger view re-render
   - Nếu thay đổi từ background thread → crash hoặc undefined behavior

2. **Compiler enforcement**
   - Không có `@MainActor`, compiler không đảm bảo `posts = result` chạy trên main thread
   - Với `@MainActor`, mọi property access/mutation đều được compiler verify

3. **Eliminates `DispatchQueue.main.async`**
   - Trước Swift concurrency: `DispatchQueue.main.async { self.posts = result }`
   - Với `@MainActor`: tự động, không cần boilerplate

### 4.2 Tại sao @MainActor ở class level (không phải từng method)?

```swift
// ✅ Cách dự án đang dùng — toàn bộ class isolated
@MainActor
@Observable
final class FeedViewModel {
    private(set) var posts: [Post] = []      // MainActor isolated
    private(set) var isLoading = false        // MainActor isolated

    func loadFeed() async { ... }             // MainActor isolated
}
```

**Tại sao không đánh dấu từng method?**
```swift
// ❌ Không nên — dễ quên, không đồng nhất
final class FeedViewModel {
    var posts: [Post] = []  // ← Không isolated! Race condition nguy hiểm

    @MainActor func loadFeed() async { ... }
}
```

**Lý do:**
- ViewModel **toàn bộ state** phục vụ UI → toàn bộ nên trên main thread
- Class-level annotation = "mọi thứ trong class này chạy trên main" — rõ ràng, an toàn
- Tránh tình huống một property được access từ nhiều thread

### 4.3 AuthManager — Tại sao cũng là @MainActor?

```swift
@MainActor
protocol AuthManagerProtocol: AnyObject, Sendable {
    var accessToken: String? { get }
    var refreshToken: String? { get }
    var isAuthenticated: Bool { get }
    func storeSession(_ session: AuthSession)
    func refreshToken() async throws
    func logout()
}

@MainActor
final class AuthManager: AuthManagerProtocol { ... }
```

**Lý do:**
- `isAuthenticated` được bind trực tiếp vào UI (navigation logic)
- `logout()` cần reset `AppRouter` (cũng @MainActor)
- `accessToken` được đọc bởi `RequestInterceptor.adapt()` → cần consistent access
- Đơn giản hóa: thay vì lock/actor, dùng main thread làm serialization point

### 4.4 AppRouter — Navigation state

```swift
@MainActor
@Observable
final class AppRouter {
    static let shared = AppRouter()
    var selectedTab: AppTab = .feed
    var feedPath = NavigationPath()
    // ...
}
```

- `NavigationPath` là SwiftUI type → **bắt buộc** main thread
- Mọi navigation action (push, pop, switchTab) đều trigger UI change
- Singleton `shared` + `@MainActor` = thread-safe access pattern

---

## 5. Isolated vs Non-Isolated

### 5.1 Khái niệm

| Thuật ngữ | Nghĩa | Ví dụ trong dự án |
|-----------|--------|-------------------|
| **Isolated** | Thuộc một actor/isolation domain cụ thể | `@MainActor class FeedViewModel` |
| **Non-isolated** | Không thuộc actor nào, chạy trên caller's context | `nonisolated func request<T>(...)` |
| **`nonisolated` keyword** | Opt-out khỏi isolation của class/actor cha | Dùng trên NetworkService methods |
| **`@unchecked Sendable`** | Tự claim thread-safe, compiler không kiểm tra | Repositories, NetworkService |

### 5.2 `nonisolated` trên NetworkService

```swift
final class NetworkService: NetworkServiceProtocol, @unchecked Sendable {

    // Tại sao nonisolated?
    nonisolated func request<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint
    ) async throws -> sending T { ... }
}
```

**Lý do dùng `nonisolated`:**
- NetworkService **không thuộc actor nào** (không phải @MainActor)
- Nhưng protocol `NetworkServiceProtocol` khai báo methods là `nonisolated`
- Mục đích: cho phép bất kỳ isolation domain nào gọi — @MainActor ViewModel, background Task, etc.
- Nếu không có `nonisolated`: compiler có thể infer isolation từ context → gây conflict

**`sending T` return type:**
- Đảm bảo giá trị trả về không bị shared reference
- Cho phép cross-isolation boundary mà không cần `Sendable` cho container type
- Quan trọng khi return generic `T` mà compiler chưa verify Sendable tại call site

### 5.3 `nonisolated struct` trên DTOs

```swift
nonisolated struct PostDTO: Decodable, Sendable { ... }
```

**Phân tích:**
- `nonisolated` trên struct là **redundant** (thừa) trong Swift 6
- Struct đã mặc định không isolated (value types không có actor affinity)
- Tuy nhiên, nó **explicit intent**: "DTO này không và sẽ không bao giờ thuộc actor nào"
- Có thể giúp tránh future compiler inference issues khi dự án migrate lên strict concurrency

### 5.4 Khi nào dùng Isolated vs Non-Isolated?

```
┌─────────────────────────────────────────────────────────────┐
│  ISOLATED (@MainActor)              │ NON-ISOLATED          │
├─────────────────────────────────────┼───────────────────────┤
│ ViewModels (UI state)               │ DTOs                  │
│ AppRouter (navigation)              │ Mappers               │
│ AuthManager (token state)           │ NetworkService methods │
│ PushNotification (UIApplication)    │ Repositories          │
│                                     │ UseCases              │
│                                     │ Domain Entities       │
│                                     │ WebSocket (serial Q)  │
└─────────────────────────────────────┴───────────────────────┘
```

**Quy tắc:**
- Nếu property/method ảnh hưởng trực tiếp UI → `@MainActor`
- Nếu là pure data transformation hoặc I/O → non-isolated
- Nếu cần thread safety nhưng không liên quan UI → serial DispatchQueue hoặc actor

### 5.5 WebSocketService — Serial Queue thay vì Actor

```swift
final class WebSocketService: NSObject, WebSocketServiceProtocol, @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.instagram.websocket", qos: .userInitiated)

    private var _connectionState: WebSocketConnectionState = .disconnected
    private var webSocketTask: URLSessionWebSocketTask?

    func connect(url: URL, headers: [String: String]) async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                // Mọi mutable state access ở đây — thread-safe
                self?.tearDown()
                self?.updateState(.connecting)
                // ...
                continuation.resume()
            }
        }
    }
}
```

**Tại sao dùng DispatchQueue thay vì Swift Actor?**
1. `URLSessionWebSocketTask` yêu cầu `URLSessionWebSocketDelegate` — delegate pattern khó fit với actor
2. Timer (`DispatchSourceTimer`) chạy trên specific queue
3. `NSObject` inheritance — actors không thể inherit NSObject
4. Reconnect logic cần `queue.asyncAfter` — actors không có delay scheduling native
5. Đã thread-safe nhờ serial queue → `@unchecked Sendable` hợp lý

---

## 6. Sendable & Thread Safety

### 6.1 Sendable Protocol — Ý nghĩa

`Sendable` = "Giá trị này an toàn khi truyền qua concurrency boundary (actor, Task, etc.)"

**Tự động Sendable:**
- Value types (struct, enum) với tất cả stored properties là Sendable
- Actors (luôn Sendable)
- `@Sendable` closures

**Trong dự án:**

| Type | Sendable Strategy | Lý do |
|------|------------------|-------|
| `Post`, `User`, `Reel` | `struct: Sendable` | Immutable value types, all `let` |
| `PostDTO`, `UserDTO` | `struct: Decodable, Sendable` | Immutable, cross-boundary decode |
| `NetworkService` | `@unchecked Sendable` | Alamofire Session thread-safe internally |
| `PostRepository` | `@unchecked Sendable` | DataSources immutable after init |
| `DIContainer` | `@unchecked Sendable` | Singleton, Container thread-safe |
| `WebSocketService` | `@unchecked Sendable` | Serial queue protects state |
| `FeedViewModel` | Không cần Sendable | @MainActor isolated, không cross boundary |

### 6.2 `@unchecked Sendable` — Khi nào hợp lý?

```swift
// ✅ Hợp lý: Alamofire Session internal thread-safe
final class NetworkService: @unchecked Sendable {
    private let session: Session  // Thread-safe internally
}

// ✅ Hợp lý: Serial queue protects all state
final class WebSocketService: @unchecked Sendable {
    private let queue = DispatchQueue(label: "...")
    private var _connectionState: ...  // Only accessed on queue
}

// ⚠️ Nguy hiểm: Không có synchronization mechanism
final class PostRepository: @unchecked Sendable {
    private let remoteDataSource: RemotePostDataSource  // let → OK
    private let mockDataSource: MockPostDataSource      // let → OK
    // Hiện tại an toàn vì chỉ có let properties
    // Nhưng nếu thêm mutable cache → race condition!
}
```

### 6.3 `@preconcurrency` — Legacy Interop

```swift
final class AuthInterceptor: @preconcurrency RequestInterceptor, Sendable {
    // Alamofire's RequestInterceptor chưa adopt Sendable
    // @preconcurrency: "Tôi biết protocol này chưa Sendable, nhưng tôi tự đảm bảo"
}
```

- Dùng khi adopt protocol từ library chưa update cho Swift 6 concurrency
- Sẽ phát warning nếu bỏ `@preconcurrency` vì Alamofire protocol chưa Sendable-annotated

### 6.4 `User` entity — Vấn đề `var` trong Sendable struct

```swift
struct User: Identifiable, Hashable, Sendable {
    let id: String
    let username: String
    // ...
    var isFollowing: Bool      // ⚠️ var trong Sendable struct
    var isFollowedBy: Bool     // ⚠️ var
    var isBlocked: Bool        // ⚠️ var
}
```

**Tại sao có `var`?**
- ViewModel cần mutate trực tiếp: `currentUser.isFollowing = !wasFollowing`
- Struct copy semantics → mỗi copy independent → thực tế an toàn
- Compiler cho phép vì struct value type tạo copy khi assign

**Tuy nhiên:** Nếu muốn strict immutability, nên tạo mới:
```swift
// Thay vì: user.isFollowing = true
// Dùng: User(..., isFollowing: true) — nhưng boilerplate nhiều với 17 properties
```

---

## 7. Vấn Đề Hiện Tại & Warnings

### 7.1 Warning: "Main actor-isolated property cannot be referenced from non-isolated context"

**Nguyên nhân:** Khi property của `@MainActor` class được access từ nơi không isolated.

**Ví dụ cụ thể — AuthInterceptor:**

```swift
// AuthManager: @MainActor
// AuthInterceptor.retry(): KHÔNG @MainActor

func retry(_ request: Request, ..., completion: @escaping (RetryResult) -> Void) {
    Task {
        do {
            try await authManager.refreshToken()  // ⚠️ Gọi @MainActor method từ unstructured Task
            // ...
        } catch {
            await MainActor.run { authManager.logout() }  // ✅ Phải dùng MainActor.run
        }
    }
}
```

**Vấn đề pattern:**
- `AuthManagerProtocol` là `@MainActor` → tất cả properties/methods isolated
- `RequestInterceptor.retry()` chạy trên background (Alamofire callback)
- Access `authManager.accessToken` từ non-MainActor context → warning

### 7.2 Warning: `private(set)` properties trong @MainActor + @Observable

**Kịch bản gây warning:**

```swift
@MainActor
@Observable
final class FeedViewModel {
    private(set) var posts: [Post] = []  // Getter = MainActor isolated
}

// Ở nơi khác, nếu access từ non-isolated context:
let vm = FeedViewModel(...)
let posts = vm.posts  // ⚠️ Warning: actor-isolated property accessed from non-isolated
```

**Root cause:**
- `@Observable` tạo synthesized getter/setter qua macro
- `private(set)` nghĩa là getter public, setter private
- Public getter vẫn MainActor-isolated
- Nếu access property từ non-isolated code (ví dụ: trong Task không inherit isolation) → warning

### 7.3 Vấn đề `private(set)` → `var` (thiếu tính đồng nhất)

**Bạn đã sửa:**
```swift
// Trước (đúng thiết kế):
private(set) var isLoading = false

// Sau (để thoả mãn compiler nhưng phá vỡ encapsulation):
var isLoading = false
```

**Tại sao đây là vấn đề:**
1. `private(set)` = "Chỉ class này được thay đổi, bên ngoài chỉ đọc" — encapsulation
2. Bỏ `private(set)` → View có thể vô tình `vm.isLoading = true` — sai architecture
3. Nếu tất cả ViewModel đều bỏ `private(set)` → mất kiểm soát state mutation
4. Không đồng nhất: một số file có `private(set)`, một số không

**Root cause thực sự không phải `private(set)`** — mà là cách access property từ context sai.

### 7.4 `@unchecked Sendable` trên Repository — Rủi ro tiềm ẩn

```swift
final class PostRepository: PostRepositoryProtocol, @unchecked Sendable {
    private let remoteDataSource: RemotePostDataSource
    private let mockDataSource: MockPostDataSource
}
```

**Hiện tại an toàn** vì:
- Chỉ có `let` properties (immutable references)
- Không có mutable state

**Nguy hiểm trong tương lai** nếu:
- Thêm cache: `private var cache: [String: Post] = [:]` → race condition!
- Thêm retry counter → data race
- `@unchecked` nghĩa là compiler im lặng — developer phải tự track

### 7.5 ServiceAssembly — Resolution timing issue

```swift
container.register(AuthManagerProtocol.self) { resolver in
    AuthManager(keychainManager: resolver.resolve(KeychainManager.self)!)
}.inObjectScope(.container)
```

- `AuthManager` là `@MainActor` → init phải chạy trên main thread
- Swinject resolve có thể chạy từ bất kỳ thread nào
- Potential issue: nếu resolve lần đầu từ background → compiler warning/error

---

## 8. Giải Pháp Đề Xuất

### 8.1 Giữ `private(set)` — Fix đúng cách

**Vấn đề:** Access `@MainActor` property từ non-isolated context gây warning.

**Giải pháp 1: Đảm bảo caller cũng MainActor**
```swift
// ❌ Gây warning:
Task {
    let posts = viewModel.posts  // Non-isolated Task
}

// ✅ Fix:
Task { @MainActor in
    let posts = viewModel.posts  // MainActor Task
}
```

**Giải pháp 2: Dùng `nonisolated` computed property cho read-only access**
```swift
@MainActor
@Observable
final class FeedViewModel {
    private(set) var posts: [Post] = []

    // Nếu cần access từ non-isolated context:
    nonisolated var postsCopy: [Post] {
        // ⚠️ Cẩn thận: Chỉ an toàn nếu [Post] là Sendable (đúng trong case này)
        MainActor.assumeIsolated { posts }
    }
}
```

**Giải pháp 3 (Recommended): Giữ nguyên `private(set)`, fix call site**

Trong phần lớn trường hợp, warning xuất hiện vì View/code bên ngoài access property
từ context không đúng. Fix ở call site thay vì thay đổi ViewModel:

```swift
// SwiftUI View tự động MainActor → không bao giờ warning
struct FeedView: View {
    let viewModel: FeedViewModel

    var body: some View {
        List(viewModel.posts) { ... }  // ✅ View body là MainActor
    }
}
```

### 8.2 AuthManager — Tách non-UI logic ra khỏi @MainActor

**Hiện tại:**
```swift
@MainActor
final class AuthManager {
    private(set) var accessToken: String?
    func refreshToken() async throws { ... }  // Không cần main thread
}
```

**Đề xuất: Hybrid approach**
```swift
@MainActor
final class AuthManager: AuthManagerProtocol {
    private(set) var accessToken: String?

    // UI-related: giữ MainActor
    func logout() { ... }

    // Non-UI: có thể dùng nonisolated
    nonisolated func getAccessToken() -> String? {
        // Cần mechanism khác để access safely
        // Option A: actor (tốt nhất)
        // Option B: lock
    }
}
```

**Hoặc refactor thành Actor:**
```swift
actor TokenStore {
    private(set) var accessToken: String?
    private(set) var refreshToken: String?

    func store(_ session: AuthSession) { ... }
    func refresh() async throws { ... }
}

@MainActor
final class AuthManager {
    private let tokenStore = TokenStore()
    var isAuthenticated: Bool { /* check tokenStore */ }
    func logout() { ... }  // UI navigation
}
```

### 8.3 Repository — Chuẩn bị cho mutable state

**Nếu cần thêm cache sau này:**
```swift
// Option A: Actor (recommended)
actor PostCache {
    private var cache: [String: Post] = [:]
    func get(_ id: String) -> Post? { cache[id] }
    func set(_ post: Post) { cache[post.id] = post }
}

// Option B: NSLock (nếu cần synchronous access)
final class PostRepository: @unchecked Sendable {
    private let lock = NSLock()
    private var _cache: [String: Post] = [:]

    private func cachedPost(_ id: String) -> Post? {
        lock.withLock { _cache[id] }
    }
}
```

### 8.4 Bỏ `nonisolated` redundant trên DTOs

```swift
// Trước (redundant):
nonisolated struct PostDTO: Decodable, Sendable { ... }

// Sau (cleaner):
struct PostDTO: Decodable, Sendable { ... }
```

- Structs mặc định non-isolated
- Bỏ `nonisolated` keyword giảm noise, code sạch hơn
- **Lưu ý:** Nếu project đang target Swift 5 language mode → giữ lại để explicit

### 8.5 Quy tắc đồng nhất (Consistency Rules)

Để tránh tình trạng "một số file có `private(set)`, một số không":

| Rule | Áp dụng |
|------|---------|
| ViewModel state → `private(set) var` | Luôn luôn |
| ViewModel input (user-editable) → `var` | `email`, `password`, `searchText` |
| ViewModel computed → `var` (computed) | `isLoginValid`, `canPublish` |
| ViewModel dependency → `private let` | UseCases, Repositories |
| Domain Entity → `let` | Trừ khi cần local mutation (User relationship) |
| DTO → `let` | Luôn luôn |

---

## Phụ Lục A: Bảng Tóm Tắt Concurrency Annotations

| Annotation | Ý nghĩa | File áp dụng |
|------------|----------|--------------|
| `@MainActor` | Toàn bộ class chạy trên main thread | ViewModels, AppRouter, AuthManager |
| `@Observable` | SwiftUI observation macro | ViewModels |
| `Sendable` | An toàn truyền cross-boundary | Entities, DTOs, UseCases, Protocols |
| `@unchecked Sendable` | Tự claim safe, compiler skip check | NetworkService, Repositories, DIContainer |
| `nonisolated` | Opt-out isolation, chạy trên caller context | NetworkService methods, DTO structs |
| `sending T` | Ownership transfer khi return | NetworkService generic returns |
| `@preconcurrency` | Suppress warning cho legacy protocol | AuthInterceptor (Alamofire) |
| `async throws` | Asynchronous, có thể fail | Tất cả data fetching methods |
| `private(set)` | External read-only, internal read-write | ViewModel state properties |

---

## Phụ Lục B: File Map — Concurrency Pattern per Layer

```
Presentations/
├── Feed/FeedViewModel.swift            → @MainActor @Observable
├── Auth/AuthViewModel.swift            → @MainActor @Observable
├── Chat/ChatViewModel.swift            → @MainActor @Observable
├── Reels/ReelsViewModel.swift          → @MainActor @Observable
├── Explore/ExploreViewModel.swift      → @MainActor @Observable
├── Profile/ProfileViewModel.swift      → @MainActor @Observable
├── CreatePost/CreatePostViewModel.swift → @MainActor @Observable
├── Notifications/NotificationsViewModel.swift → @MainActor @Observable
├── DirectMessages/DirectMessagesViewModel.swift → @MainActor @Observable
└── Navigation/AppRouter.swift          → @MainActor @Observable (singleton)

Domain/
├── Entities/*.swift                    → struct, Sendable (value types)
├── UseCases/*.swift                    → final class, Sendable
└── Repositories/*Protocol.swift        → protocol: Sendable

Data/
├── DTOs/*.swift                        → nonisolated struct, Decodable, Sendable
├── Mappers/*.swift                     → enum (stateless, static methods)
├── Repositories/*.swift                → @unchecked Sendable
└── DataSources/Remote/*.swift          → @unchecked Sendable (via NetworkService)
    DataSources/Mock/*.swift            → Sendable (immutable data)

Core/
├── Networking/NetworkService.swift     → @unchecked Sendable, nonisolated methods
├── Networking/RequestInterceptor.swift → @preconcurrency, Sendable
├── WebSocket/WebSocketService.swift    → @unchecked Sendable, serial DispatchQueue
├── Security/AuthManager.swift          → @MainActor
├── DI/DIContainer.swift                → @unchecked Sendable (singleton)
└── PushNotification/*.swift            → @unchecked Sendable, @MainActor methods
```

---

## Phụ Lục C: Common Warning Messages & Fixes

| Warning | Nguyên nhân | Fix |
|---------|-------------|-----|
| "Main actor-isolated property 'X' can not be referenced from a non-isolated context" | Access @MainActor property từ Task/background | Dùng `Task { @MainActor in ... }` hoặc `await MainActor.run { }` |
| "Passing argument of non-sendable type across actor boundary" | Truyền non-Sendable type vào/ra actor | Conform type to Sendable hoặc copy value |
| "Capture of 'self' with non-sendable type in @Sendable closure" | `self` (class) captured trong async closure | Dùng `[weak self]` hoặc conform class to Sendable |
| "Non-sendable type returned by implicitly asynchronous call" | Async function return non-Sendable | Add Sendable conformance hoặc dùng `sending` return |
| "Static property 'shared' is not concurrency-safe" | Singleton access across threads | Add `@MainActor` hoặc `nonisolated(unsafe)` |

---

> **Ghi chú cuối:** Document này phản ánh trạng thái code tại thời điểm phân tích.
> Khi Swift 6 strict concurrency mode được bật (upcoming feature flag), một số pattern
> hiện đang là warning sẽ trở thành error. Khuyến nghị fix sớm để chuẩn bị migration.

---

## 9. Changelog — Các Fix Đã Áp Dụng

> Commit: `efb5bdd` — "TomTheCat: Resolve warning"
> 13 files changed, 126 insertions(+), 88 deletions(-)

### 9.1 Default Parameter Pattern (MainActor Singleton)

**Vấn đề:** `@MainActor` class có `static let shared` — khi dùng làm default parameter
trong `init`, compiler evaluate default value trong non-isolated context → warning.

| File | Trước | Sau |
|------|-------|-----|
| `AuthViewModel.swift` | `router: AppRouter = .shared` | `router: AppRouter? = nil` + `?? AppRouter.shared` trong body |
| `CallViewModel.swift` | `callService: CallService = .shared` | `callService: CallService? = nil` + `?? CallService.shared` |
| `CallService.swift` | `callManager: CallManager = .shared` | `callManager: CallManager? = nil` + `?? CallManager.shared` |
| `NotificationRouter.swift` | `pushService: PushNotificationService = .shared` | `pushService: PushNotificationService? = nil` + `?? .shared` |

**Pattern tổng quát:**
```swift
// ❌ Warning: MainActor-isolated static property in default param
init(dep: SomeMainActorClass = .shared) { ... }

// ✅ Fix: resolve inside body (body inherits @MainActor)
init(dep: SomeMainActorClass? = nil) {
    self.dep = dep ?? SomeMainActorClass.shared
}
```

### 9.2 Actor → Class + NSLock (Non-Sendable Type Crossing)

**Vấn đề:** Actor boundary yêu cầu mọi giá trị cross boundary phải `Sendable`.
`CIImage`, `UIImage`, `[any ImageFilter]` không conform `Sendable`.

| File | Trước | Sau |
|------|-------|-----|
| `FilterThumbnailGenerator.swift` | `actor` + `withTaskGroup` | `final class @unchecked Sendable` + `NSLock` + sequential |
| `InMemoryStorage.swift` | `actor` | `final class @unchecked Sendable` + `NSLock` |

**Pattern tổng quát:**
```swift
// ❌ Actor gây warning khi làm việc với non-Sendable types (CIImage, etc.)
actor FilterThumbnailGenerator {
    func generate(image: UIImage) async -> [Thumbnail] { // UIImage cross boundary!
        ...
    }
}

// ✅ Class + lock — không có boundary crossing
final class FilterThumbnailGenerator: @unchecked Sendable {
    private let lock = NSLock()
    private var cache: [String: [Thumbnail]] = [:]

    func generate(image: UIImage) async -> [Thumbnail] { // No boundary issue
        ...
    }
}
```

### 9.3 Static Property Concurrency Safety

**Vấn đề:** `static let` trên enum/struct chứa non-Sendable existential array
gây warning "Static property is not concurrency-safe".

| File | Trước | Sau |
|------|-------|-----|
| `ImageFilter.swift` | `static let allFilters: [ImageFilter]` | `nonisolated(unsafe) static let allFilters: [any ImageFilter]` |

**Giải thích `nonisolated(unsafe)`:**
- Khai báo rằng static property không cần concurrency protection
- An toàn khi: property là `let`, chỉ chứa immutable data (stateless filter structs)
- Compiler bỏ qua isolation checking cho property này

### 9.4 Combine Sink + @MainActor Method

**Vấn đề:** `.sink` closure không tự động inherit `@MainActor` isolation dù có
`.receive(on: DispatchQueue.main)`.

| File | Trước | Sau |
|------|-------|-----|
| `NotificationRouter.swift` | `self?.pushService.navigateFromPayload(payload)` | `Task { @MainActor in self.pushService.navigateFromPayload(payload) }` |

**Pattern:**
```swift
// ❌ .receive(on: .main) đảm bảo runtime main thread, nhưng compiler không biết
publisher.receive(on: DispatchQueue.main).sink { payload in
    self.mainActorMethod(payload)  // Warning: not proven to be MainActor
}

// ✅ Explicit MainActor Task
publisher.receive(on: DispatchQueue.main).sink { [weak self] payload in
    guard let self else { return }
    Task { @MainActor in
        self.mainActorMethod(payload)
    }
}
```

### 9.5 Synthesized Equatable + MainActor Inference

**Vấn đề:** Compiler synthesize `==` cho enum và có thể infer MainActor isolation.
Khi `==` được gọi từ non-isolated context (serial queue) → warning.

| File | Trước | Sau |
|------|-------|-----|
| `WebSocketService.swift` | `enum State: Sendable, Equatable` (synthesized ==) | Explicit `nonisolated static func ==` trong extension |

```swift
// ❌ Synthesized == có thể inherit MainActor isolation
enum WebSocketConnectionState: Sendable, Equatable { ... }

// ✅ Explicit nonisolated == — gọi được từ bất kỳ context nào
extension WebSocketConnectionState: Equatable {
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) { ... }
    }
}
```

### 9.6 @Sendable Closure trong Sendable Struct

**Vấn đề:** `Shape` protocol inherits `Sendable`. Struct conform `Shape` phải có
tất cả stored properties là `Sendable`. Closure `(CGRect) -> Path` không mặc định Sendable.

| File | Trước | Sau |
|------|-------|-----|
| `CreateReelView.swift` | `private let _path: (CGRect) -> Path` | `private let _path: @Sendable (CGRect) -> Path` |

### 9.7 Task Capture trong DispatchQueue Closure

**Vấn đề:** `Task { await self.method() }` bên trong `queue.asyncAfter` capture `self`
không rõ ràng — compiler cảnh báo về implicit strong capture across isolation boundary.

| File | Trước | Sau |
|------|-------|-----|
| `WebSocketService.swift` (ping timer) | `Task { await self?.ping() }` | `guard let self` + `Task { [weak self] in await self?.ping() }` |
| `WebSocketService.swift` (reconnect) | `Task { await self.connect(...) }` | `Task { [weak self] in guard let self ... }` |

### 9.8 Misc Fixes

| File | Fix |
|------|-----|
| `PushNotificationService.swift` | `if let userId` → `if let _` (unused variable warning) |
| `AuthManager.swift` | `guard let currentRefresh` → `guard let _` (unused variable) |
| `ImagePipelineManager.swift` | `let pipeline` → `let _` (unused variable) |
| `NetworkService.swift` | `try endpoint.asURLRequest()` → `try await endpoint.asURLRequest()` (async requirement) |

---

## Phụ Lục D: Quy Tắc Phòng Tránh Warning (Áp Dụng Cho Code Mới)

| # | Quy tắc | Ví dụ |
|---|---------|-------|
| 1 | Không dùng `@MainActor` singleton làm default parameter | `init(x: X? = nil)` + resolve trong body |
| 2 | Không dùng `actor` khi cần truyền non-Sendable types (CIImage, UIImage) | Dùng `final class @unchecked Sendable` + lock |
| 3 | Static property chứa existential cần `nonisolated(unsafe)` nếu immutable | `nonisolated(unsafe) static let x: [any P]` |
| 4 | Combine `.sink` gọi `@MainActor` method → wrap trong `Task { @MainActor in }` | Không dựa vào `.receive(on: .main)` cho compile-time safety |
| 5 | Enum với `Sendable` + `Equatable` cần explicit `nonisolated static func ==` | Tránh synthesized conformance bị actor-isolation inference |
| 6 | Struct conform protocol `: Sendable` — tất cả closure property phải `@Sendable` | `let closure: @Sendable (X) -> Y` |
| 7 | `Task` trong DispatchQueue closure → luôn dùng `[weak self]` capture list | Tránh implicit strong capture warning |
