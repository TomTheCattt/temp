# Splash - Màn hình khởi động

## Mô tả

Module hiển thị splash screen khi ứng dụng khởi động. Hiển thị logo Instagram với animation fade-in + scale, sau đó chuyển sang `ContentView`.

## Danh sách file

| File | Vai trò |
|------|---------|
| `SplashView.swift` | Màn hình splash với logo animation + auto-navigate |

## Tính năng chính

- **Logo animation**: scale 0.7→1.0 + opacity 0→1 với smooth animation
- **Auto transition**: sau 2 giây tự động chuyển sang `ContentView`
- **Adaptive background**: `ColorTokens.backgroundPrimary` (hỗ trợ dark/light mode)
- **2 assets**:
  - `splashIcon`: logo camera/gradient (88x88pt)
  - `splashFooter`: chữ "Instagram" / Meta branding (77x39pt)
- **Layout**: Spacer + Icon + Footer với spacing 283pt
- **Preview**: có preview cho cả Light và Dark mode

## Architecture

- Đây là View đơn lẻ, không có ViewModel
- State: `isActive` (switch sang ContentView), `logoScale`, `logoOpacity`
- Transition: animated `isActive = true` sau 2s delay
- Entry point: đây là view đầu tiên được render (wrap `ContentView`)

## Flow

```
App launch → SplashView
→ onAppear: animate logo (0.3s smooth)
→ delay 2.0s
→ withAnimation: isActive = true → render ContentView
```

## Constants

| Property | Value |
|----------|-------|
| splashIconSize | 88pt |
| splashFooterWidth | 77pt |
| splashFooterHeight | 39pt |
| spacing | 283pt |
| paddingBottom | 51pt |
| animationDelay | 2.0s |
