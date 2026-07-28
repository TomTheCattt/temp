# Development Rules

> Quy tắc phát triển bắt buộc cho dự án. Mọi code mới PHẢI tuân thủ các quy tắc dưới đây.

---

## 1. Architecture Rules

### Layer Dependency (Strict)

```
Presentations → Domain ← Data
                  ↑
              Persistence
```

- **Domain** KHÔNG import bất kỳ layer nào khác. Đây là layer thuần Swift.
- **Presentations** chỉ phụ thuộc Domain (qua UseCases), KHÔNG trực tiếp gọi Repositories.
- **Data** implement Domain protocols, KHÔNG được import Presentations.
- **Core** là shared infrastructure — mọi layer đều có thể import Core.

### Violations sẽ KHÔNG chấp nhận

```swift
// ❌ WRONG: View gọi thẳng Repository
struct FeedView: View {
    let repo = PostRepository()
    func load() { repo.fetchFeed(...) }
}

// ✅ CORRECT: View → ViewModel → UseCase → Repository
struct FeedView: View {
    @State var viewModel: FeedViewModel  // ViewModel holds UseCase
}
```

---

## 2. Naming Conventions

### Files

| Type | Pattern | Example |
|------|---------|---------|
| Entity | `{Name}.swift` | `User.swift`, `Post.swift` |
| Protocol | `{Name}Protocol.swift` | `PostRepositoryProtocol.swift` |
| UseCase | `{Action}{Subject}UseCase.swift` | `FetchFeedUseCase.swift` |
| ViewModel | `{Feature}ViewModel.swift` | `FeedViewModel.swift` |
| View | `{Feature}View.swift` | `FeedView.swift` |
| Repository impl | `{Name}Repository.swift` | `PostRepository.swift` |
| Assembly | `{Module}Assembly.swift` | `RepositoryAssembly.swift` |

### Types

- Protocols: suffix `Protocol` (trừ `ImageFilter`, `UseCase` — base protocols)
- ViewModels: `@MainActor @Observable final class`
- Entities: `struct`, conform `Identifiable, Hashable, Sendable`
- Errors: `enum`, conform `LocalizedError`

### Properties & Methods

- `camelCase` cho properties và methods
- Prefix `is/has/should` cho Boolean: `isLoading`, `hasVideo`, `shouldReconnect`
- Prefix `fetch/load` cho data retrieval: `fetchFeed()`, `loadProfile()`
- Prefix `handle` cho event response: `handleIncomingCall()`
- Prefix `toggle` cho on/off actions: `toggleMute()`, `toggleFollow()`

---

## 3. Code Style

### MARK Comments (Required)

Mọi file phải có MARK sections:

```swift
// MARK: - Properties
// MARK: - Init
// MARK: - Public API / Actions
// MARK: - Private
```

### File Header

```swift
//
//  FileName.swift
//  Instagram
//
//  Created by {Author} on {date}.
//
```

### Access Control

- Entities: `struct` (implicit internal) — không cần `public`
- Protocols: `protocol` (internal)
- ViewModels: `final class` — properties dùng `private(set)` cho read-only state
- Private helpers: luôn đánh dấu `private`
- Không dùng `open` trừ khi cần subclass (hiếm khi cần)

### Concurrency

```swift
// ✅ ViewModel
@MainActor @Observable
final class SomeViewModel { ... }

// ✅ Entity
struct User: Identifiable, Hashable, Sendable { ... }

// ✅ Repository
final class PostRepository: PostRepositoryProtocol, @unchecked Sendable { ... }

// ✅ Actor for thread-safe shared state
actor FilterThumbnailGenerator { ... }
```

---

## 4. ViewModel Rules

### Structure Template

```swift
@MainActor
@Observable
final class {Feature}ViewModel {
    // MARK: - State (published to View)
    private(set) var items: [Item] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // MARK: - Dependencies
    private let someUseCase: SomeUseCaseProtocol

    // MARK: - Init
    init(someUseCase: SomeUseCaseProtocol) {
        self.someUseCase = someUseCase
    }

    // MARK: - Actions (called by View)
    func load() async { ... }
    func refresh() async { ... }
}
```

### Rules

- State mutations CHỈ xảy ra trong ViewModel, KHÔNG trong View.
- View chỉ đọc state và gọi action methods.
- Optimistic updates: update UI trước, revert nếu API fail.
- Error handling: catch trong ViewModel, expose `errorMessage` string cho View.
- Không hold strong reference đến View.

---

## 5. View Rules

### Structure

```swift
struct {Feature}View: View {
    @State private var viewModel: {Feature}ViewModel

    var body: some View { ... }

    // MARK: - Subviews (private computed properties)
    private var headerSection: some View { ... }
    private var contentSection: some View { ... }

    // MARK: - Actions (wrap Task calls)
    // Inline trong button closures, hoặc private func nếu phức tạp
}
```

### Rules

- View KHÔNG chứa business logic.
- Dùng `@State private var viewModel` (không dùng `@StateObject` — đã chuyển sang `@Observable`).
- Tách subviews thành private computed properties khi body quá dài (> 30 lines).
- Extract reusable components thành separate `struct` (e.g., `PostCardView`, `AuthTextField`).
- Navigation: gọi `AppRouter.shared.push(...)`, KHÔNG dùng `NavigationLink(destination:)`.

---

## 6. Repository & UseCase Rules

### Repository

```swift
// Protocol in Domain/Repositories/
protocol PostRepositoryProtocol: Sendable {
    func fetchFeed(page: Int, perPage: Int) async throws -> [Post]
}

// Implementation in Data/Repositories/
final class PostRepository: PostRepositoryProtocol, @unchecked Sendable {
    private let mockDataSource: MockPostDataSource
    // Later: private let remoteDataSource: RemotePostDataSource
    // Later: private let localStorage: LocalStorageProtocol
}
```

### UseCase

```swift
// One UseCase = One Business Action
protocol FetchFeedUseCaseProtocol: Sendable {
    func execute(_ input: PaginationInput) async throws -> [Post]
}

final class FetchFeedUseCase: FetchFeedUseCaseProtocol, Sendable {
    private let postRepository: PostRepositoryProtocol
    
    func execute(_ input: PaginationInput) async throws -> [Post] {
        // Business validation + call repository
    }
}
```

### Rules

- UseCase chứa business validation (email format, password length, etc.).
- Repository chỉ làm data fetching/storing — KHÔNG validation.
- Mỗi UseCase có riêng protocol để dễ mock trong tests.
- Input/Output types phải `Sendable`.

---

## 7. Error Handling

```swift
// ❌ WRONG: Generic catch
} catch {
    print(error)
}

// ✅ CORRECT: Typed error, expose to user
} catch let error as APIError {
    errorMessage = error.localizedDescription
} catch {
    errorMessage = "An unexpected error occurred."
}
```

### Rules

- Mọi error type conform `LocalizedError` với meaningful `errorDescription`.
- ViewModel catch errors và set `errorMessage` — View hiển thị.
- Network errors: map qua `APIError.from(_:response:)`.
- Silent fail CHỈ cho non-critical operations (pagination load more, analytics).

---

## 8. Navigation Rules

```swift
// ✅ Push within current tab
AppRouter.shared.push(.userProfile(userId: user.id))

// ✅ Switch tab and navigate
AppRouter.shared.switchTab(.feed, route: .postDetail(postId: id))

// ✅ Present modal
AppRouter.shared.present(sheet: .createPost)

// ❌ NEVER: Direct NavigationLink with destination view
NavigationLink(destination: ProfileView(userId: id)) // DON'T
```

### Rules

- Tất cả navigation qua `AppRouter.shared`.
- Routes phải defined trong `AppRoute` enum trước khi dùng.
- Sheet/FullScreen dùng `AppSheet` / `AppFullScreen` enum.
- `MainTabView` là nơi DUY NHẤT map `AppRoute` → destination View.

---

## 9. Dependency Injection Rules

### Registration

- Đăng ký trong đúng Assembly theo role:
  - Services → `ServiceAssembly`
  - Repositories → `RepositoryAssembly`
  - UseCases → `UseCaseAssembly`
  - ViewModels → `ViewModelAssembly`

### Resolution

```swift
// Option 1: Property wrapper (simple)
@Injected var postRepo: PostRepositoryProtocol

// Option 2: Direct resolve (in assemblies)
let repo = resolver.resolve(PostRepositoryProtocol.self)!
```

### Rules

- KHÔNG resolve trong View code — resolve trong ViewModel init hoặc Assembly.
- Container scopes: `.container` cho singletons, `.transient` (default) cho ViewModels.
- Force unwrap `!` khi resolve là ACCEPTABLE trong assemblies — fail-fast nếu missing registration.

---

## 10. Performance Rules

### Image Filters

- KHÔNG tạo `CIContext` mới — luôn dùng `FilterEngine.shared.ciContext`.
- Filter apply CHỈ build CIImage graph — actual render chỉ khi cần hiển thị.
- Thumbnail preview: render ở 150x150, KHÔNG full resolution.
- Camera: `alwaysDiscardsLateVideoFrames = true`.

### Lists

- Dùng `LazyVStack` / `LazyVGrid` cho scrollable content.
- Pagination: load more khi last item appears.
- Images: dùng `LazyImage` (NukeUI) — tự handle caching + cancellation.

### General

- KHÔNG block main thread — mọi I/O phải `async`.
- Heavy computation (filter, image processing) trên background queue.
- Cache expensive computations (LUT data, thumbnails).

---

## 11. Git Rules

- Branch naming: `feature/{feature-name}`, `fix/{bug-name}`, `refactor/{area}`
- Commit messages: imperative mood, short subject (< 72 chars)
  - `Add feed pagination support`
  - `Fix WebSocket reconnect race condition`
  - `Refactor filter engine to use single CIContext`
- Không commit generated files (`.xcuserstate`, build products).
- Không commit secrets (tokens, keys) — dùng xcconfig + .gitignore.
