# Test Account — Hướng Dẫn Sử Dụng

> Tài liệu hướng dẫn cách sử dụng tài khoản test mặc định để truy cập đầy đủ tính năng
> ứng dụng trong quá trình phát triển.

---

## Thông Tin Tài Khoản Test

| Field | Value |
|-------|-------|
| Email | `tom@example.com` |
| Password | `password123` |
| Username | `tomthecat` |
| Full Name | Tom The Cat |
| Verified | Yes |
| Posts | 42 |
| Followers | 1,234 |
| Following | 567 |

> Credentials được định nghĩa tại `Data/DataSources/Mock/MockData.swift`
> (`MockData.testEmail`, `MockData.testPassword`)

---

## Cách Hoạt Động

### Chế độ 1: Auto-Login (Mock API Mode)

Khi `API_MODE = mock` trong build settings (hoặc Info.plist):

```
App Launch
    │
    ▼
InstagramApp.init()
    │  AppConfig.shared.isMockAPI == true
    │
    ▼
performMockAutoLogin()
    │  MockAuthDataSource.login(email, password)
    │  → AuthSession(user: MockData.currentUser)
    │
    ▼
SessionStore.shared.setSession(user: session.user)
    │  → currentUserId = "user_current"
    │  → currentUser = User(...)
    │
    ▼
AppRouter.shared.isAuthenticated = true
    │
    ▼
SplashView (2s animation) → ContentView → MainTabView
```

**Không cần nhập credentials.** App tự động vào trang chính với full mock data.
**SessionStore được populate** giống hệt production flow — đảm bảo tất cả features
sử dụng `SessionStore.shared.currentUserId` hoạt động đúng.

### Chế độ 2: Manual Login (Live API Mode hoặc test login flow)

Khi `API_MODE = live` nhưng chạy DEBUG build:

```
App Launch
    │
    ▼
ContentView → LoginView
    │  Email/Password đã được pre-fill sẵn (DEBUG + mock only)
    │
    ▼
User tap "Login" → AuthRepository → Remote API (hoặc MockAuthDataSource)
    │
    ▼
handleAuthSuccess(session)
    │  → SessionStore.shared.setSession(user: session.user)
    │  → router.isAuthenticated = true
    │
    ▼
MainTabView
```

### Logout Flow

```
SettingsView → Tap "Log Out"
    │
    ▼
SettingsViewModel.logout()
    │  → authRepository.logout() (API call)
    │  → SessionStore.shared.clear()  ← Xóa user session
    │  → AppRouter.shared.isAuthenticated = false
    │  → AppRouter.shared.reset()
    │
    ▼
ContentView → LoginView
```

---

## Cấu Hình

### Bật/Tắt Mock Mode

**File:** Xcode Build Settings hoặc `Info.plist`

| Key | Value | Hiệu ứng |
|-----|-------|-----------|
| `API_MODE` | `mock` | Auto-login, dùng fake data |
| `API_MODE` | `live` | Cần login thủ công, gọi real API |

**Code reference:** `Config/AppEnvironment.swift`
```swift
enum APIMode: String {
    case live
    case mock
    static var current: APIMode { ... } // reads from Info.plist
}

struct AppConfig {
    var isMockAPI: Bool { apiMode == .mock }
}
```

### Pre-fill Credentials (chỉ DEBUG)

**File:** `Presentations/Auth/AuthViewModel.swift`
```swift
#if DEBUG
if AppConfig.shared.isMockAPI {
    email = MockData.testEmail      // "tom@example.com"
    password = MockData.testPassword // "password123"
}
#endif
```

- Chỉ hoạt động trong DEBUG build
- Chỉ khi mock mode bật
- Production build không bao giờ pre-fill

---

## Mock Data Đi Kèm

Sau khi login, tài khoản test có đầy đủ:

| Feature | Mock Data |
|---------|-----------|
| Feed | 10 posts (7 images + 3 videos) từ picsum.photos và Google Storage |
| Stories | 5 stories (other users, 2-4 items each) + 1 My Story (image + video), stickers |
| Reels | 8 reels với video thật (Google Storage MP4), captions, audio tracks |
| Notifications | 5 notifications (like, comment, follow, mention) |
| Direct Messages | 5 conversations với last messages |
| Comments | 8 comments với replies |
| Explore | Grid posts (shuffled) |
| Profile | Full profile với stats |

**Mock users:** 5 users ngoài currentUser (`jane_doe`, `john_smith`, `sara_design`, `mike_dev`, `lisa_art`)

**Video URLs:** Sử dụng sample videos từ `https://storage.googleapis.com/gtv-videos-bucket/sample/` (public, HTTPS)

**Story Stickers:** location, mention, music, poll — hiển thị overlay trên story viewer

**My Story:** Current user có mock story riêng (2 items: image + video). StoriesBarView hiển thị "Your Story" riêng biệt — tap mở MyStoryView (viewers, close friends, delete) nếu đã đăng, hoặc Story Camera nếu chưa.

**Video Thumbnails:** `VideoThumbnailView` hiển thị thumbnail ưu tiên từ remote URL, fallback tự generate từ video frame đầu tiên (cached, half-resolution)

**Loading States:** Skeleton shimmer placeholders cho Feed và Reels trong lúc tải dữ liệu ban đầu

---

## Files Liên Quan

| File | Vai trò |
|------|---------|
| `Application/InstagramApp.swift` | Auto-login logic (calls MockAuthDataSource → SessionStore) |
| `Presentations/Auth/AuthViewModel.swift` | Pre-fill credentials, handleAuthSuccess → SessionStore |
| `Data/DataSources/Mock/MockData.swift` | Test credentials + all mock data (posts, stories, reels, etc.) |
| `Data/DataSources/Mock/MockAuthDataSource.swift` | Mock login/register (accepts any valid input, returns MockData.currentUser) |
| `Config/AppEnvironment.swift` | `AppConfig.isMockAPI` flag |
| `Core/Security/AuthManager.swift` | Token storage + logout (clears SessionStore) |
| `Core/Security/SessionStore.swift` | Current user session (currentUserId, currentUser) — single source of truth |

---

## Lưu Ý

1. **Mock mode chấp nhận BẤT KỲ email/password hợp lệ** — không validate credentials thật
2. **Auto-login skip KeychainManager** — tokens không được lưu persistent trong mock mode
3. **Logout sẽ quay về LoginView** — cần restart app hoặc tap Login lại
4. **Tất cả API calls trong mock mode** trả về fake data với simulated delay (0.3–0.8s)
5. **Không bao giờ deploy mock mode lên production** — check `API_MODE` trong release config
