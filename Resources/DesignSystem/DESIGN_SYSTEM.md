# Instagram iOS Design System Specification

## 1. Tổng Quan Kiến Trúc (Architecture Overview)

Design System của Instagram iOS được thiết kế theo nguyên tắc Atomic Design và Clean Architecture:
- **Primitives** (`PrimitiveColors.swift`): Bảng mã màu thô trích xuất từ Figma UI Kit.
- **Tokens** (`ColorTokens.swift`, `DesignConstants.swift`): Các hằng số ngữ nghĩa (`DS.*`, `ColorTokens.*`) thích ứng tự động giữa Light Mode và Dark Mode.
- **Typography** (`AppTypography.swift`): Hệ thống font tuỳ biến `Instagram Sans` (Regular, Medium, Headline, Bold).
- **Atomic Components** (`Resources/DesignSystem/Components/`): Các thành phần giao diện dùng chung (`InstagramButton`, `InstagramAvatarView`, `FloatingTextField`).
- **Feedback & Overlays** (`ToastManager`, `HUDManager`, `ShimmerModifier`): Phản hồi người dùng và skeleton shimmer.

---

## 2. Hệ Thống Màu Động & Dark/Light Mode (Dynamic Color System)

### 2.1. Cơ Chế Thích Ứng Thông Minh
Mọi màu sắc giao diện được phân giải qua `Color.dynamic(light:dark:)` hoặc Asset Catalog Semantic Colorset dựa trên `UITraitCollection.userInterfaceStyle`:

```swift
extension Color {
    static func dynamic(light: Color, dark: Color) -> Color
    static func dynamic(lightHex: UInt, darkHex: UInt) -> Color
}
```

### 2.2. Bảng Tra Cứu Token Màu Sắc (Color Tokens Mapping)

| Token | Light Mode | Dark Mode | Mục Đích Sử Dụng | Tỷ Lệ Tương Phản (WCAG) |
|---|---|---|---|---|
| `ColorTokens.backgroundPrimary` | `#FFFFFF` | `#000000` | Nền màn hình chính (OLED True Black) | N/A |
| `ColorTokens.backgroundSecondary` | `#F7F9F9` | `#1A1A1A` | Nền thẻ grouped, ô nhập search, thought bubble | > 1.2:1 so với primary bg |
| `ColorTokens.backgroundSubtler` | `#F3F4F6` | `#262626` | Nền placeholder avatar, skeleton | Mờ dịu |
| `ColorTokens.surface` | `#FFFFFF` | `#121212` | Nền cell / card nổi | Tách lớp tinh tế |
| `ColorTokens.surfaceElevated` | `#F7F9F9` | `#262626` | Nền modal / sheet | Nổi bật trên nền tối |
| `ColorTokens.textPrimary` | `#000000` | `#FFFFFF` | Tiêu đề chính, username, nội dung tin nhắn | **21:1** (Đạt AAA) |
| `ColorTokens.textSecondary` | `#737373` | `#A8A8A8` | Nhãn thời gian, phụ đề, số lượt like | **4.8:1** (Đạt AA) |
| `ColorTokens.textTertiary` | `#8E8E8E` | `#5E646D` | Placeholder, nhãn vô hiệu hóa | Nhẹ nhàng, không chói |
| `ColorTokens.buttonPrimary` | `#0098FD` | `#0098FD` | CTA chính (Đăng nhập, Đăng ký, Theo dõi) | Nổi bật thương hiệu |
| `ColorTokens.buttonSecondary` | `#EFEFEF` | `#262626` | Nút Đang theo dõi, Nhắn tin, Bong bóng chat đến | **11.2:1** (Đạt AAA) |
| `ColorTokens.buttonDisabled` | `#DBDFE4` | `#363636` | Nút trạng thái vô hiệu hóa | Mờ rõ rệt |
| `ColorTokens.stroke` | Black @ 12% | White @ 15% | Viền hairline, đường phân cách nhẹ | Tinh xảo, không gắt |

---

## 3. Hệ Thống Typography (`DS.Font.*`)

Dự án tích hợp bộ font chính hãng `Instagram Sans` với các kiểu dáng ngữ nghĩa:

| Token | Kích Thước | Font Family | Trọng Số | Sử Dụng |
|---|---|---|---|---|
| `DS.Font.largeTitle` | 28pt | Instagram Sans Headline | Bold | Tiêu đề lớn trang chính |
| `DS.Font.title1` | 22pt | Instagram Sans Bold | Bold | Tiêu đề trang, Header Profile |
| `DS.Font.title2` | 20pt | Instagram Sans Medium | Medium | Tiêu đề nhóm nội dung |
| `DS.Font.headline` | 16pt | Instagram Sans Medium | Medium | Tên tài khoản, nút CTA |
| `DS.Font.body` | 14pt | Instagram Sans | Regular | Nội dung bài viết, comment |
| `DS.Font.subheadline` | 13pt | Instagram Sans | Regular | Thông báo, thông tin phụ |
| `DS.Font.subheadlineBold` | 13pt | Instagram Sans Medium | Bold | Nhãn nút hành động phụ |
| `DS.Font.caption` | 12pt | Instagram Sans | Regular | Nhãn thời gian, địa điểm |
| `DS.Font.captionBold` | 12pt | Instagram Sans Bold | Bold | Tag, pill label |
| `DS.Font.caption2` | 11pt | Instagram Sans Light | Light | Chú thích nhỏ, watermark |

> [!IMPORTANT]
> **Quy Tắc Bắt Buộc Khi Sử Dụng Custom Font (Zero Font Descriptor Error)**:
> Bộ font `Instagram Sans` bao gồm các tệp font tĩnh riêng rẽ (`InstagramSans`, `InstagramSans-Medium`, `InstagramSans-Bold`). Tuyệt đối **KHÔNG** gọi modifier `.fontWeight(...)` hoặc `.bold()` lên các token `DS.Font.*`. CoreText trên iOS không thể biến đổi trọng số động của font descriptor tĩnh, dẫn tới lỗi runtime warning `Unable to update Font Descriptor's weight to Weight(...)`.
> - **ĐÚNG**: Sử dụng token tương ứng đã định nghĩa sẵn: `DS.Font.subheadlineBold`, `DS.Font.bodyBold`, `DS.Font.captionBold`, `DS.Font.title`, v.v.
> - **SAI**: `.font(DS.Font.subheadline).fontWeight(.semibold)` hoặc `.font(DS.Font.caption).fontWeight(.bold)`.
> - **Với Text Concatenation**: Khai báo font riêng cho từng Text: `Text(username).font(DS.Font.subheadlineBold) + Text(body).font(DS.Font.subheadline)`.

---

## 4. Hệ Thống Spacing & Kích Thước Chuẩn HIG

### 4.1. Spacing (`DS.Spacing.*`)
- `DS.Spacing.hairline` (1pt): Đường kẻ viền mảnh.
- `DS.Spacing.xxxs` (2pt): Khoảng cách cực nhỏ (ring padding, page dots).
- `DS.Spacing.xxs` (4pt): Khoảng cách giữa avatar và text lân cận.
- `DS.Spacing.iconGap` (6pt): Khoảng cách giữa icon và nhãn chữ.
- `DS.Spacing.xs` (8pt): Khoảng cách tiêu chuẩn giữa các phần tử phụ.
- `DS.Spacing.inputVertical` (10pt): Padding dọc của ô nhập liệu và chip button.
- `DS.Spacing.sm` (12pt): Khoảng cách nhỏ giữa các dòng.
- `DS.Spacing.formGap` (14pt): Khoảng cách giữa các trường trong form.
- `DS.Spacing.md` (16pt): Khoảng cách tiêu chuẩn lề màn hình ngang (`DS.Padding.horizontal`).
- `DS.Spacing.lg` (20pt): Khoảng cách giữa các section lớn.
- `DS.Spacing.xl` (24pt): Khoảng cách giữa các khối giao diện độc lập.

### 4.2. Avatar Sizes (`DS.Size.avatar*`)
- `avatarXSmall` (24pt): Tiny inline replies.
- `avatarSmall` (28pt): Message bubble avatar.
- `avatarCompact` (32pt): Story header, comment row.
- `avatarMedium` (36pt): Post card header avatar.
- `avatarList` (44pt): Followers/Following list row avatar.
- `avatarStoryCircle` (56pt): Story circle trong Stories bar.
- `avatarLarge` (64pt): Hashtag, Profile header icon.
- `avatarHero` (120pt): Profile page hero avatar.

### 4.3. Button Heights (`DS.Size.button*`)
- `buttonSmallHeight` (30pt): Nút pill nhỏ gọn trong danh sách.
- `buttonCompactHeight` (36pt): Nút theo dõi / nhắn tin tiêu chuẩn.
- `buttonDefaultHeight` (44pt): Chuẩn Apple HIG minimum tap target.
- `buttonLargeHeight` (50pt): Nút CTA chính trang Auth / Checkout.

---

## 5. Hướng Dẫn Sử Dụng Atomic Components

### 5.1. `InstagramButton`
Nút bấm chuẩn hóa toàn app, tự động xử lý haptic feedback, loading spinner và kích thước chạm 44pt HIG:

```swift
// Nút CTA chính (Primary)
InstagramButton("Đăng nhập", style: .primary, size: .standard, isLoading: viewModel.isLoading) {
    Task { await viewModel.login() }
}

// Nút Đang theo dõi (Secondary thích ứng Dark/Light mode)
InstagramButton("Đang theo dõi", style: .secondary, size: .compact, isFullWidth: false) {
    Task { await viewModel.toggleFollow() }
}

// Nút Xóa / Huỷ (Destructive)
InstagramButton("Xóa bài viết", style: .destructive, size: .standard) {
    viewModel.deletePost()
}
```

### 5.2. `InstagramAvatarView`
Hiển thị avatar tối ưu tài nguyên qua NukeUI, tự động bao quanh bằng viền Story Instagram gradient hoặc viền xám:

```swift
InstagramAvatarView(
    url: user.avatarURL,
    size: DS.Size.avatarStoryCircle,
    hasStory: user.hasActiveStory,
    isStoryViewed: user.isStoryViewed,
    showPlusBadge: user.isCurrentUser && !user.hasActiveStory
) {
    AppRouter.shared.present(fullScreen: .storyViewer(stories: user.stories))
}
```

### 5.3. `FloatingTextField`
Ô nhập liệu với nhãn nổi hoạt họa mượt mà, bọc `UITextField` để tránh mất focus khi toggle mật khẩu, hỗ trợ text color thích ứng dynamic:

```swift
FloatingTextField(
    placeholder: "Tên người dùng hoặc email",
    text: $viewModel.email,
    keyboardType: .emailAddress,
    textContentType: .emailAddress
)
```

---

## 6. Quy Tắc Bắt Buộc Khi Phát Triển UI (Do's & Don'ts)

### ✅ NÊN LÀM (DO's):
1. **Luôn sử dụng `ColorTokens.*`**: Dùng `ColorTokens.backgroundPrimary`, `backgroundSecondary`, `buttonSecondary` để đảm bảo giao diện thích ứng 100% Dark/Light mode.
2. **Luôn dùng `DS.Spacing.*` & `DS.Size.*`**: Nghiêm cấm hard-code bất kỳ số ma thuật nào (`.padding(14)` $\rightarrow$ `.padding(DS.Spacing.formGap)`).
3. **Ưu tiên Atomic Components**: Sử dụng `InstagramButton` và `InstagramAvatarView` thay vì tự dựng lại `Button` hay `AsyncImage` thủ công.
4. **Vùng chạm tối thiểu 44pt**: Dù kích thước hiển thị của icon/nút có nhỏ hơn (24pt/30pt), luôn đảm bảo `.contentShape(Rectangle())` đạt tối thiểu 44pt x 44pt.

### ❌ KHÔNG ĐƯỢC LÀM (DON'Ts):
1. **Không dùng màu tĩnh thô**: Không sử dụng trực tiếp `Color.white`, `Color.black`, `Color.gray` cho text hoặc nền vì sẽ làm hỏng khả năng đảo màu Dark/Light Mode.
2. **Không dùng inline NavigationLink**: Bắt buộc điều hướng qua `AppRouter.shared.push/present`.
3. **Không tạo mới UIColor liên tục trong render loop**: Tận dụng static cache của `ColorTokens` để duy trì 60/120 FPS.
