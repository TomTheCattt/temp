# Config

Quản lý cấu hình môi trường (environment), backend plug-and-play và API mode cho toàn bộ ứng dụng. Đây là single source of truth cho mọi thông số runtime.

## Cấu trúc

```
Config/
├── Configurations/
│   ├── Base.xcconfig
│   ├── Debug.xcconfig
│   ├── Staging.xcconfig
│   ├── Release.xcconfig
│   └── Secrets.xcconfig.template
├── AppEnvironment.swift
└── CONFIG.md
```

## Chi tiết

### 1. Hệ thống Configuration Files (.xcconfig)

| File | Build Configuration | Môi trường | App Display Name | Base URL | Debug Logging |
|------|---------------------|------------|------------------|----------|---------------|
| `Debug.xcconfig` | `Debug` | `dev` | `Instagram (Dev)` | `https://dev-api.example.com` | ✅ YES (`DEBUG=1`) |
| `Staging.xcconfig` | `Staging` | `staging` | `Instagram (Staging)` | `https://staging-api.example.com` | ✅ YES (`STAGING=1`) |
| `Release.xcconfig` | `Release` | `prod` | `Instagram` | `https://api.example.com` | ❌ NO (Strip symbols) |
| `Base.xcconfig` | *(Dùng chung)* | — | Bundle ID & Version | — | `SLASH = /` token |
| `Secrets.xcconfig` | *(Bảo mật)* | — | API Keys nhạy cảm | — | Đã vào `.gitignore` |

---

### 2. AppEnvironment (enum)

Định nghĩa 3 môi trường triển khai tương ứng:

| Case | Raw Value | Base URL | Debug Logging | Mục đích |
|------|-----------|----------|---------------|----------|
| `.development` | `"dev"` | `https://dev-api.example.com` | ✅ | Lập trình viên code hàng ngày (`-Onone`) |
| `.staging` | `"staging"` | `https://staging-api.example.com` | ✅ | QA & Tester kiểm thử nội bộ trên TestFlight (`-O`) |
| `.production` | `"prod"` | `https://api.example.com` | ❌ | Phát hành chính thức lên App Store (`-O`) |

**Thứ tự ưu tiên xác định môi trường (`AppEnvironment.current`):**
1. Ưu tiên 1: Biến môi trường `APP_ENVIRONMENT` trong Scheme
2. Ưu tiên 2: Key `APP_ENVIRONMENT` trong `Info.plist` (inject từ `.xcconfig`)
3. Mặc định: `.production`

---

### 3. BackendType (enum)

Độc lập Backend (Backend-Agnostic): Hỗ trợ chuyển đổi backend chỉ bằng cách đổi biến `BACKEND_TYPE` trong `.xcconfig` tương ứng:

| Case | Mô tả |
|------|--------|
| `.firebase` | Kết nối Cloud Firebase (Firestore, Storage, Auth) |
| `.live` | Kết nối Custom REST API qua `APP_BASE_URL` (hoặc Local Server) |

---

### 4. Hệ thống Xcode Schemes

| Scheme | Build Configuration | Môi trường | Backend mặc định |
|--------|---------------------|------------|------------------|
| `Instagram (Dev)` | `Debug` | `dev` | `firebase` |
| `Instagram (Staging)` | `Staging` | `staging` | `firebase` |
| `Instagram (Prod)` / `Instagram` | `Release` | `prod` | `firebase` |
| `Instagram (Local BE)` | `Debug` | `dev` | `live` (`localhost:8787`) |
