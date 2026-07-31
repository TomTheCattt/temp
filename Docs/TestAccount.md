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
AppRouter.shared.isAuthenticated = true  ← Auto-login
    │
    ▼
ContentView → MainTabView (skip LoginView hoàn toàn)
```

**Không cần nhập credentials.** App tự động vào trang chính với full mock data.

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
User tap "Login" → MockAuthDataSource chấp nhận mọi email/password hợp lệ
    │
    ▼
handleAuthSuccess() → router.isAuthenticated = true → MainTabView
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
| Feed | 10 posts với images từ picsum.photos |
| Stories | 5 stories từ users khác nhau |
| Reels | 8 reels với captions |
| Notifications | 5 notifications (like, comment, follow, mention) |
| Direct Messages | 5 conversations với last messages |
| Comments | 8 comments với replies |
| Explore | Grid posts (shuffled) |
| Profile | Full profile với stats |

**Mock users:** 5 users ngoài currentUser (`jane_doe`, `john_smith`, `sara_design`, `mike_dev`, `lisa_art`)

---

## Files Liên Quan

| File | Vai trò |
|------|---------|
| `Application/InstagramApp.swift` | Auto-login logic |
| `Presentations/Auth/AuthViewModel.swift` | Pre-fill credentials |
| `Data/DataSources/Mock/MockData.swift` | Test credentials + all mock data |
| `Data/DataSources/Mock/MockAuthDataSource.swift` | Mock login/register (accepts any valid input) |
| `Config/AppEnvironment.swift` | `AppConfig.isMockAPI` flag |
| `Core/Security/AuthManager.swift` | Token storage (skipped in mock) |

---

## Lưu Ý

1. **Mock mode chấp nhận BẤT KỲ email/password hợp lệ** — không validate credentials thật
2. **Auto-login skip KeychainManager** — tokens không được lưu persistent trong mock mode
3. **Logout sẽ quay về LoginView** — cần restart app hoặc tap Login lại
4. **Tất cả API calls trong mock mode** trả về fake data với simulated delay (0.3–0.8s)
5. **Không bao giờ deploy mock mode lên production** — check `API_MODE` trong release config
