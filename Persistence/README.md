# Persistence

Layer lưu trữ dữ liệu local (offline caching, offline-first support). Thiết kế theo abstraction pattern — Domain layer không biết cụ thể dùng framework nào (SwiftData, CoreData, Realm...).

## Cấu trúc

```
Persistence/
├── LocalStorageProtocol.swift      # Abstract interface
├── InMemoryStorage.swift           # In-memory implementation (dev/test)
└── SwiftData/
    ├── SwiftDataContainerFactory.swift  # ModelContainer setup
    ├── SwiftDataStorage.swift           # Concrete SwiftData implementation
    └── Models/
        ├── SDCachedUser.swift           # @Model cho User
        ├── SDCachedPost.swift           # @Model cho Post
        └── SDCachedMessage.swift        # @Model cho Message/Conversation
```

---

## LocalStorageProtocol.swift

Interface trừu tượng cho persistence layer. Bất kỳ feature module nào cần lưu trữ local đều dùng protocol này.

### Protocol Definition

```swift
protocol LocalStorageProtocol: Sendable {
    func fetchAll<T: Storable>(_ type: T.Type, predicate: StoragePredicate?, sortBy: [StorageSortDescriptor]) async throws -> [T]
    func fetch<T: Storable>(_ type: T.Type, id: String) async throws -> T?
    func save<T: Storable>(_ object: T) async throws
    func saveAll<T: Storable>(_ objects: [T]) async throws
    func delete<T: Storable>(_ type: T.Type, id: String) async throws
    func deleteAll<T: Storable>(_ type: T.Type, predicate: StoragePredicate?) async throws
    func count<T: Storable>(_ type: T.Type, predicate: StoragePredicate?) async throws -> Int
}
```

### Supporting Types

| Type | Mô tả |
|------|--------|
| `Storable` | Protocol cho domain objects có thể persist (yêu cầu `id: String`) |
| `StoragePredicate` | Framework-agnostic predicate: field + operation + value |
| `StoragePredicate.Operation` | equals, notEquals, greaterThan, lessThan, contains, in |
| `AnySendableValue` | Type-erased Sendable value (string, int, double, bool, date, none) |
| `StorageSortDescriptor` | Sort by field + ascending/descending |

**Storable conformance:** `Post` và `User` đã conform `Storable` (extension trong SwiftDataStorage.swift).

---

## InMemoryStorage.swift

Implementation đơn giản lưu trữ trong RAM. Dùng cho:
- Unit testing (isolated, nhanh)
- SwiftUI Previews
- Development trước khi SwiftData models sẵn sàng

**Thread safety:** `NSLock` bảo vệ mọi read/write — tránh actor-isolation crossing warnings khi dùng từ `@MainActor`.

**Behavior:**
- `save()` — upsert (update nếu tồn tại, insert nếu chưa)
- `delete()` — remove by id
- `deleteAll(predicate: nil)` — xóa toàn bộ type
- Dữ liệu mất khi app terminate (chỉ tồn tại trong session)

---

## SwiftData/

### SwiftDataContainerFactory.swift

Factory tạo `ModelContainer` với schema versioning.

- `create(inMemory:)` — tạo container cho production (persisted) hoặc testing (in-memory)
- `createPreview()` — shorthand cho in-memory container (dùng trong #Preview)
- `SchemaV1` — versioned schema chứa list `@Model` types

**Schema models hiện tại:**
- `SDCachedUser`
- `SDCachedPost`
- `SDCachedConversation`
- `SDCachedMessage`

**Migration:** Khi thêm model mới, tạo `SchemaV2` kế thừa cho migration support.

### SwiftDataStorage.swift

Concrete implementation của `LocalStorageProtocol` sử dụng SwiftData.

- `@ModelActor actor` — đảm bảo thread-safe access tới `ModelContext`
- Type-dispatching: generic calls được route tới typed SwiftData operations dựa trên runtime type check
- Upsert pattern: delete existing → insert new (đảm bảo data consistency)

**Supported types:**
| Domain Entity | SwiftData Model | Operations |
|---------------|----------------|------------|
| `Post` | `SDCachedPost` | fetchAll (sorted by feedIndex), fetch by id, save, delete |
| `User` | `SDCachedUser` | fetchAll (sorted by cachedAt desc), fetch by id, save, delete |

### Models/

`@Model` classes — SwiftData persistent models. Đây là internal representation, không expose ra ngoài Persistence layer.

| File | Model | Mô tả |
|------|-------|--------|
| `SDCachedUser.swift` | `SDCachedUser` | Cache user profile data |
| `SDCachedPost.swift` | `SDCachedPost` | Cache feed posts (với feedIndex cho ordering) |
| `SDCachedMessage.swift` | `SDCachedMessage` | Cache messages/conversations |

Mỗi model có:
- `init(from: DomainEntity)` — convert từ domain entity sang SwiftData model
- `toEntity()` — convert ngược lại sang domain entity

---

## Cách sử dụng

```swift
// Resolve từ DI container
let storage = DIContainer.shared.resolve(LocalStorageProtocol.self)

// Lưu posts
try await storage.saveAll(posts)

// Đọc cached posts
let cachedPosts: [Post] = try await storage.fetchAll(Post.self)

// Xóa 1 post
try await storage.delete(Post.self, id: "post_123")
```

## Chiến lược cache

- **InMemoryStorage** được đăng ký mặc định trong DI (nhanh, đủ cho MVP)
- **SwiftDataStorage** sẵn sàng thay thế khi cần offline-first — chỉ cần đổi đăng ký trong `ServiceAssembly`
- Domain entities không cần thay đổi gì — polymorphism qua protocol
