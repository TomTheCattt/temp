# Application

Entry point của ứng dụng Instagram Clone. Folder này chứa file khởi tạo app và root view điều hướng.

## Cấu trúc

```
Application/
├── InstagramApp.swift      # @main entry point
└── ContentView.swift       # Root view xử lý điều hướng auth
```

## Chi tiết từng file

### InstagramApp.swift

File `@main` — điểm khởi chạy của toàn bộ ứng dụng.

**Chức năng chính:**
- Khởi tạo `DIContainer.shared` (Dependency Injection) — trigger đăng ký tất cả assembly
- Cấu hình `ImagePipelineManager` cho image loading/caching
- Tự động login mock user khi `AppConfig.shared.isMockAPI == true` (phục vụ dev/testing)
- Hiển thị `SplashView` làm root view, áp dụng `.withBaseFeatures()` và `.withAppTheme()`

**Mock Auto-Login flow:**
1. Sử dụng `MockAuthDataSource` để gọi `login(email:password:)`
2. Populate `SessionStore.shared` với user data
3. Set `AppRouter.shared.isAuthenticated = true`

### ContentView.swift

Root view quyết định hiển thị màn hình nào dựa trên trạng thái authentication.

**Logic điều hướng:**
- `router.isAuthenticated == true` → Hiển thị `MainTabView()` (app chính)
- `router.isAuthenticated == false` → Hiển thị `LoginView` (đăng nhập)
- Cả hai đều wrap `.withToast()` để hỗ trợ hiển thị toast notification
- Transition animation `.easeInOut(duration: 0.3)` khi chuyển trạng thái

**Dependencies:**
- `AppRouter.shared` — quản lý trạng thái navigation toàn app
- `DIContainer.shared` — resolve `LoginUseCaseProtocol` và `RegisterUseCaseProtocol` cho `AuthViewModel`

## Luồng khởi động app

```
InstagramApp.init()
  ├── DIContainer.shared (đăng ký tất cả dependencies)
  ├── ImagePipelineManager.configure()
  └── performMockAutoLogin() (nếu mock mode)
      ↓
SplashView → ContentView
  ├── Authenticated → MainTabView
  └── Not Authenticated → LoginView
```

## Lưu ý

- `DIContainer` phải được khởi tạo trước khi bất kỳ view nào resolve dependency
- Mock auto-login chạy trên `@MainActor` via `Task` — non-blocking
- `AppRouter` sử dụng `@Observable` (iOS 17+) nên ContentView tự động re-render khi state thay đổi
