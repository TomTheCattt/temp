# Config

Quản lý cấu hình môi trường (environment) và API mode cho toàn bộ ứng dụng. Đây là single source of truth cho mọi thông số runtime.

## Cấu trúc

```
Config/
└── AppEnvironment.swift
```

## Chi tiết

### AppEnvironment.swift

File này chứa 3 thành phần chính:

---

### 1. AppEnvironment (enum)

Định nghĩa 3 môi trường triển khai:

| Case | Raw Value | Base URL | Debug Logging |
|------|-----------|----------|---------------|
| `.development` | `"dev"` | `https://dev-api.example.com` | ✅ |
| `.staging` | `"staging"` | `https://staging-api.example.com` | ✅ |
| `.production` | `"prod"` | `https://api.example.com` | ❌ |

**Cách xác định môi trường hiện tại (`AppEnvironment.current`):**
1. Ưu tiên 1: Biến môi trường `APP_ENVIRONMENT` (đặt trong Xcode Scheme)
2. Ưu tiên 2: Key `APP_ENVIRONMENT` trong Info.plist
3. Mặc định: `.production`

---

### 2. APIMode (enum)

Chuyển đổi giữa dữ liệu thật và mock:

| Case | Mô tả |
|------|--------|
| `.live` | Gọi API thật qua network |
| `.mock` | Sử dụng `MockDataSource` local (không cần backend) |

**Cách xác định:** Tương tự AppEnvironment — scheme env var → Info.plist → default `.live`

---

### 3. AppConfig (struct, singleton)

Single source of truth cho toàn bộ cấu hình runtime. Truy cập qua `AppConfig.shared`.

| Property | Mô tả |
|----------|--------|
| `environment` | Môi trường hiện tại (dev/staging/prod) |
| `apiMode` | Live hay Mock |
| `useLocalBackend` | Dùng local server (từ Info.plist key `APP_USE_LOCAL_BACKEND`) |
| `localBaseURL` | URL local server (từ Info.plist key `APP_LOCAL_BASE_URL`) |
| `baseURL` | URL cuối cùng được dùng — tự động resolve theo ưu tiên: local → plist → environment default |
| `isDebug` | True nếu environment không phải production hoặc đang dùng local backend |
| `isMockAPI` | True nếu apiMode == .mock |
| `timeoutInterval` | 30 giây |
| `clientVersion` | Từ `CFBundleShortVersionString` |
| `buildNumber` | Từ `CFBundleVersion` |

**Thứ tự ưu tiên resolve `baseURL`:**
1. `useLocalBackend == true` → dùng `localBaseURL` hoặc `http://localhost:3000`
2. Info.plist key `APP_BASE_URL` (từ xcconfig)
3. `environment.defaultBaseURL`

## Cách sử dụng

```swift
// Kiểm tra có đang chạy mock không
if AppConfig.shared.isMockAPI {
    // Dùng mock data
}

// Lấy base URL cho API calls
let url = AppConfig.shared.baseURL

// Kiểm tra có nên log debug không
if AppConfig.shared.isDebug {
    // Log chi tiết
}
```

## Cấu hình qua Xcode Scheme

Đặt Environment Variables trong Scheme > Run > Arguments:
- `APP_ENVIRONMENT` = `dev` | `staging` | `prod`
- `API_MODE` = `live` | `mock`
- `APP_USE_LOCAL_BACKEND` = `1` (optional)
- `APP_LOCAL_BASE_URL` = `http://192.168.1.x:3000` (optional)
