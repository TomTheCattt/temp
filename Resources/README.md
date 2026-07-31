# Resources

Chứa tất cả tài nguyên UI: Design System (components, theme, typography, animations), image loading pipeline, localization, và asset catalogs.

## Cấu trúc

```
Resources/
├── Assets/
│   └── Assets.xcassets          # App icons, colors, images
├── DesignSystem/
│   ├── Animation/               # Animation utilities
│   ├── Components/              # Reusable UI components
│   ├── Font/                    # Custom fonts (Instagram Sans)
│   ├── HUD/                     # Loading indicator overlay
│   ├── Image/                   # Image loading pipeline
│   ├── Skeleton/                # Shimmer loading placeholder
│   ├── Theme/                   # Colors, spacing, design tokens
│   └── Toast/                   # Toast notification system
└── Localization/
    ├── L10n.swift               # Type-safe localization manager
    ├── String+Localization.swift # String extension helpers
    └── Localizable.xcstrings    # String Catalog (multilingual)
```

---

## Assets/

### Assets.xcassets

Xcode Asset Catalog chứa:
- App icons (các size)
- Color sets (named colors)
- Image assets (illustrations, placeholders)
- Symbol images

---

## DesignSystem/

Hệ thống thiết kế thống nhất cho toàn app — đảm bảo consistency về visual và interaction.

### Animation/

#### AnimationModifier.swift

ViewModifier utilities cho animations:
- Fade in/out transitions
- Scale animations
- Custom timing curves

### Components/

#### FloatingTextField.swift

Text field với floating label animation (Material Design style):
- Label float lên trên khi user bắt đầu nhập
- Validation state visual (error border, helper text)
- Dùng trong Login, Register, EditProfile screens

### Font/

#### AppTypography.swift

Định nghĩa type scale cho toàn app — map semantic names tới font instances.

#### Font files (5 variants):
| File | Weight |
|------|--------|
| `Instagram Sans.ttf` | Regular |
| `Instagram Sans Light.ttf` | Light |
| `Instagram Sans Medium.ttf` | Medium |
| `Instagram Sans Bold.ttf` | Bold |
| `Instagram Sans Headline.otf` | Headline (display) |

### HUD/

#### HUDManager.swift

Full-screen loading overlay (Head-Up Display):
- Show/hide loading spinner
- Optional message text
- Blocks user interaction while visible
- Singleton pattern, accessible from anywhere

### Image/

Hoàn chỉnh image loading pipeline — download, cache, process, display.

| File | Chức năng |
|------|-----------|
| `ImageLoader.swift` | Core image loading logic — async download + memory/disk cache lookup |
| `ImagePipelineManager.swift` | Configure image pipeline tại app launch (cache limits, processors) |
| `ImageCachePolicy.swift` | Cache eviction policies (memory limit, disk limit, TTL) |
| `ImagePrefetcher.swift` | Prefetch images cho scrolling performance (feed, grid) |
| `ImageProcessors.swift` | Image transformations: resize, round corners, blur, circle crop |
| `RemoteImageView.swift` | SwiftUI view component hiển thị remote image (loading state, placeholder, error state) |

**Sử dụng:**
```swift
RemoteImageView(url: user.avatarURL)
    .frame(width: 40, height: 40)
    .clipShape(Circle())
```

### Skeleton/

#### ShimmerModifier.swift

Shimmer loading placeholder effect (skeleton screen):
- Animated gradient sweep (giả lập loading)
- Apply cho bất kỳ view nào: `.shimmer(active: isLoading)`
- Dùng trong feed, profile grid, stories khi data đang load

### Theme/

Hệ thống design tokens — single source of truth cho visual styling.

| File | Nội dung |
|------|----------|
| `AppTheme.swift` | Theme manager — apply dark/light mode, ViewModifier `.withAppTheme()` |
| `ColorTokens.swift` | Semantic color tokens: `primary`, `secondary`, `background`, `surface`, `error`, `onPrimary`... Tự động adapt theo dark/light |
| `DesignConstants.swift` | Spacing scale, border radius, elevation/shadow, icon sizes, hit target sizes |
| `PrimitiveColors.swift` | Raw color palette — hex values trước khi map sang semantic tokens |

**Ví dụ sử dụng:**
```swift
Text("Hello")
    .foregroundColor(ColorTokens.primary)
    .font(AppTypography.bodyMedium)
    .padding(DesignConstants.Spacing.md)
```

### Toast/

#### ToastManager.swift

Toast notification system — hiển thị thông báo ngắn phía trên/dưới màn hình.

- Success / Error / Info / Warning styles
- Auto-dismiss sau duration (configurable)
- Queue system — hiển thị tuần tự nếu nhiều toast cùng lúc
- Apply global: `.withToast()` modifier ở root view

**Sử dụng:**
```swift
ToastManager.shared.show(message: "Post created!", type: .success)
```

---

## Localization/

Đa ngôn ngữ sử dụng **String Catalogs** (.xcstrings) — hệ thống localization mới của Apple (Xcode 15+).

### L10n.swift

Type-safe localization manager — truy cập string đã localize qua enum namespaces.

**Namespaces:**

| Namespace | Screens/Features |
|-----------|-----------------|
| `L10n.Common` | cancel, done, ok, error, loading, retry, follow, unfollow, message, reply... |
| `L10n.Auth` | login, register, logout, forgotPassword, placeholders... |
| `L10n.Feed` | title |
| `L10n.Profile` | posts, followers, following, editProfile |
| `L10n.EditProfile` | title, changePhoto, name, username, website, bio |
| `L10n.Comments` | title, addComment, replyPlaceholder, likesCount(Int) |
| `L10n.Notifications` | title, likedPost, startedFollowing, commented(String)... |
| `L10n.DirectMessages` | noMessages, sentPhoto, sentVideo, you... |
| `L10n.CreatePost` | title, filter, selectMedia, captionPlaceholder, itemsSelected(Int)... |
| `L10n.CreateReel` | title, addAudio |
| `L10n.Settings` | Tất cả items trong Settings screen (account, appearance, notifications, privacy, security, data, about) |
| `L10n.Chat` | messagePlaceholder, statusSent, statusDelivered, statusRead |
| `L10n.Tab` | feed, explore, reels, notifications, profile |

**Sử dụng:**
```swift
Text(L10n.Auth.login)                    // Static string
Text(L10n.Comments.likesCount(42))       // Format string
```

### String+Localization.swift

Convenience extensions:
- `.localized` — lấy localized version từ String Catalog
- `.localized(with:)` — format string với arguments

### Localizable.xcstrings

String Catalog file — chứa tất cả translations. Xcode tự động sync keys khi dùng `String(localized:)`.
