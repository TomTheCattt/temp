# Common

Chứa các thành phần dùng chung (shared utilities) xuyên suốt toàn bộ project: hằng số, error types, và extensions.

## Cấu trúc

```
Common/
├── Constants/
│   └── AppConstants.swift
├── Errors/
│   └── APIErrors.swift
└── Extensions/
    ├── BaseViewModifier.swift
    ├── CombineExtHelpers.swift
    └── Extensions.swift
```

---

## Constants/

### AppConstants.swift

Tập trung tất cả hằng số cấp ứng dụng vào một nơi duy nhất.

| Namespace | Nội dung |
|-----------|----------|
| `AppConstants.App` | Tên app, bundleID, deepLink scheme, universal link host |
| `AppConstants.Storage` | Đường dẫn SQLite file (Documents directory) |
| `AppConstants.Keychain` | Service identifier cho Keychain (= bundleID) |
| `KeychainKeys` | Các key lưu trong Keychain: `accessToken`, `refreshToken`, `biometricEnabled` |

**Thiết kế:**
- Tất cả key đều prefix bằng `bundleID` để tránh xung đột trong shared keychain (App Extensions)
- `sqlitePath` tự động fallback sang `NSTemporaryDirectory()` nếu không tìm được Documents

---

## Errors/

### APIErrors.swift

Enum `APIError` — định nghĩa tất cả lỗi có thể xảy ra khi gọi API.

**Các case:**

| Case | Mô tả |
|------|--------|
| `invalidURL` | URL không hợp lệ |
| `unauthorized` | 401 — cần đăng nhập lại |
| `forbidden` | 403 — không có quyền truy cập |
| `notFound` | 404 — resource không tồn tại |
| `serverError(String)` | 5xx — lỗi server |
| `networkError(Error)` | Lỗi mạng chung |
| `decodingError(Error)` | JSON parse thất bại |
| `timeout` | Request quá thời gian |
| `noInternetConnection` | Không có kết nối mạng |
| `cannotConnectToHost` | Không thể kết nối tới server |
| `unknown(Int?)` | Lỗi không xác định |

**Factory method:** `APIError.from(_ error: AFError, response: HTTPURLResponse?)` — chuyển đổi từ Alamofire error sang `APIError` dựa trên HTTP status code và NSError code.

---

## Extensions/

### BaseViewModifier.swift

Các ViewModifier áp dụng toàn cục cho app.

**Components:**

| Component | Chức năng |
|-----------|-----------|
| `EdgeSwipePopModifier` | Giữ interactive pop gesture (vuốt từ trái) hoạt động ngay cả khi dùng custom back button |
| `BaseViewModifier` | Tổ hợp tất cả base modifier (hiện tại chỉ có edge swipe) |
| `KeyboardHelper` | Static helper dismiss keyboard từ bất kỳ đâu |

**View Extensions:**
- `.withBaseFeatures()` — áp dụng ở root level (`InstagramApp`)
- `.dismissKeyboardOnTap()` — áp dụng cho screen có text input (Login, Search, Chat)
- `.disableInteractivePop()` — tắt swipe back cho flow quan trọng (payment, onboarding)

### CombineExtHelpers.swift

Extensions tiện ích cho Combine framework.

**Publisher Extensions:**
- `.asVoid()` — bỏ output, chỉ giữ completion
- `.assignWeak(to:on:)` — assign với weak reference, tránh retain cycle
- `.retryWithDelay(retries:delay:)` — retry với exponential backoff
- `.onMain()` — receive on main queue (shorthand)
- `.sinkValue(_:)` — sink chỉ với value handler (khi `Failure == Never`)
- `.negate()` — đảo giá trị Bool

**Collection Extension:**
- `.mergeAll()` — merge tất cả publishers trong collection

**CancellableStore:**
- Class quản lý `AnyCancellable` subscriptions, tự động cancel khi deinit

### Extensions.swift

Extensions tiện ích cho Foundation types.

**String:**
- `.isValidEmail` — validate email regex
- `.digitsOnly` — chỉ giữ ký tự số
- `.isValidPhone` — validate số điện thoại
- `.normalizedPhone(languageCode:)` — normalize về format E.164 (hỗ trợ VN: +84)
- `.isValidVerificationCode` — validate mã OTP 6 chữ số
- `.isNotEmpty` — negation của `.isEmpty`

**Publisher:**
- `.receiveOnMain()` — shorthand receive on main thread

**View:**
- `.hideKeyboard()` — dismiss keyboard

**Date:**
- `.iso8601String` — convert Date sang ISO 8601 string

**JSONDecoder.DateDecodingStrategy:**
- `.iso8601WithFractionalSeconds` — custom strategy hỗ trợ cả `2026-04-07T06:26:43Z` và `2026-04-07T06:26:43.263Z`
