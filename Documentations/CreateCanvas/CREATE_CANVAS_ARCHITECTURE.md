# Kiến Trúc & Luồng Hoạt Động Của Màn Hình Sáng Tạo "Create-me" (CreateCanvasView)

Tài liệu này mô tả chi tiết kiến trúc, các chế độ tương tác, cơ chế quản lý vòng đời bàn phím (`UIResponder Chain`), công cụ vẽ Metal (`PencilKit`) và luồng xuất bản (Export Pipeline) của màn hình sáng tạo **CreateCanvasView** (chế độ **"Tạo" / Aa** trong Instagram Story).

---

## 1. Tổng Quan Chức Năng & Vị Trí Trong Hệ Thống

- **Tệp nguồn chính**: [`Presentations/CreatePost/CreativeModes/CreateCanvasView.swift`](file:///Users/tomthecat/temp/Presentations/CreatePost/CreativeModes/CreateCanvasView.swift)
- **Điểm kích hoạt**: Được mở từ nút công cụ thanh bên trái **"Tạo" (Aa)** của [`StoryCameraView.swift`](file:///Users/tomthecat/temp/Presentations/StoryCamera/StoryCameraView.swift).
- **Mục tiêu**:
  - Cung cấp không gian sáng tạo tự do trên nền Gradient động đa sắc thái.
  - Soạn thảo Typography tương tác thời gian thực với đầy đủ font, kiểu dáng, hoạt ảnh, hiệu ứng phát sáng và nền chữ.
  - Vẽ trực tiếp in-place với Apple PencilKit (Metal GPU acceleration).
  - Đính kèm Sticker ảnh (PIP Photo Sticker) và bài hát (Music Picker).
  - Tự động nhận diện nội dung động để xuất ra **Video MP4 1080x1920 30FPS** hoặc **Ảnh tĩnh 1080x1920**.

```mermaid
flowchart TD
    StoryCam["StoryCameraView (Nút Tạo Aa)"] --> CreateCanvas["CreateCanvasView (Root Container)"]
    
    subgraph States ["3 Chế Độ Trạng Thái Chính (ZStack Mutually Exclusive)"]
        Idle["1. idleOverlayUI (Chế độ Nghỉ)"]
        Typing["2. inlineTextEditorOverlay (Soạn Thảo Typography)"]
        Drawing["3. inlineDrawingOverlayUI (Vẽ Nét PencilKit)"]
    end
    
    CreateCanvas --> States
    
    subgraph Export ["Pipeline Xuất Bản (Export Engine)"]
        Detect{"Có Animation chữ hoặc Nhạc?"}
        VideoExport["CanvasVideoRenderer (Video MP4 1080x1920 30FPS)"]
        ImageExport["UIGraphicsImageRenderer (Ảnh tĩnh 1080x1920)"]
    end
    
    Idle -->|"Ấn Xuất bản / Xong"| Detect
    Detect -->|Có| VideoExport
    Detect -->|Không| ImageExport
    VideoExport --> StoryCam
    ImageExport --> StoryCam
```

---

## 2. Ba Chế Độ Giao Diện & Vòng Đời Tương Tác

`CreateCanvasView` sử dụng cơ chế chuyển đổi trạng thái giao diện phân cấp theo thứ tự ưu tiên:

```swift
if isDrawingMode {
    inlineDrawingOverlayUI
} else if isEditingText {
    inlineTextEditorOverlay
} else {
    idleOverlayUI
}
```

### A. Chế độ 1: Màn hình Nghỉ (`idleOverlayUI`)
- **Nền động (Dynamic Themes)**: Hỗ trợ danh sách các bảng màu Gradient thời gian thực (Cam/Hồng Instagram, Tím Neon, Xanh Đại Dương, Đen Đậm, Hoàng Hôn, v.v.). Người dùng có thể chạm nút bong bóng màu ở thanh bên phải để xoay vòng theme.
- **Thanh công cụ bên phải (`rightVerticalToolBar`)**:
  - Dạng thu gọn (Collapsed): Các nút tròn biểu tượng tối giản (Văn bản, Nhãn dán, Âm thanh, Vẽ, Đã lưu, Phông nền, Mũi tên mở rộng).
  - Dạng mở rộng (Expanded): Hiển thị đầy đủ nhãn văn bản tiếng Việt kèm icon (Văn bản, Nhãn dán, Âm thanh, Đã lưu, Phông nền, Nhắc đến `@`, Vẽ, Tải xuống, Khác).
- **Thanh hành động chân trang (`bottomActionBar`)**:
  - Nút gợi ý: *"Thêm chú thích..."* (chạm để mở chế độ gõ chữ).
  - 3 nút xuất bản chuẩn Instagram iOS: **Tin của bạn**, **Bạn thân (Close Friends)**, và **Nút tiếp theo `->`** màu xanh.

---

### B. Chế độ 2: Soạn Thảo Văn Bản Thời Gian Thực (`inlineTextEditorOverlay`)
Khi người dùng chạm vào nền canvas, chạm vào nút "Văn bản" hoặc chạm vào một nhãn chữ đã có trên màn hình:
1. **Thanh trượt cỡ chữ hình nêm (`verticalFontSizeSlider`)**:
   - Thanh trượt đặt dọc mép trái màn hình với rãnh hình nêm (Tapered Track): phần đỉnh rộng 16pt, vuốt nhọn dần xuống đáy 4pt.
   - Con trỏ tròn (Thumb) kích thước 28pt màu trắng có đổ bóng.
   - Vùng cảm ứng (Hitbox) rộng 48pt đảm bảo công thái học chạm hoàn hảo.
   - Dải kích cỡ chữ: từ `14pt` đến `64pt`.
2. **Khung chữ Hugging tự nhiên (`PersistentStoryTextView`)**:
   - Ô nhập văn bản tự động co giãn ôm sát nội dung (Text Hugging) theo chiều ngang và dọc.
   - Hỗ trợ đổi màu chữ, căn lề (Trái, Giữa, Phải) và bật/tắt nền badge chữ `[A]`.
3. **Thanh công cụ định dạng chữ (`keyboardFormattingToolbar`)**:
   - Nằm cố định ngay phía trên bàn phím ảo.
   - **Hàng 1 - Dynamic Carousel**:
     - Tab `Aa`: Băng chuyền chuyển đổi font chữ (Modern, Classic, Signature, Neon).
     - Tab `//A`: Băng chuyền hiệu ứng chữ chuyển động (Không hoạt ảnh, Chữ đánh máy Typewriter, Hiện ra Fade In, Nhảy Bouncing).
     - Tab `A✨`: Băng chuyền hiệu ứng ánh sáng (Không hiệu ứng, Lấp lánh Sparkle, Neon phát sáng, Lung linh, Pixel).
   - **Hàng 2 - Thanh nút chức năng**:
     - Nút `Aa` (chuyển sang carousel font).
     - Nút cầu vồng (mở bảng 9 màu swatch).
     - Nút `//A` (bật/tắt carousel chuyển động).
     - Nút căn lề (Trái -> Giữa -> Phải).
     - Nút nền chữ `[A]` (bật nền bo góc ôm sát văn bản).
     - Nút `A✨` (bật carousel hiệu ứng thị giác).

---

### C. Chế độ 3: Vẽ Nét Trực Tiếp In-Place (`inlineDrawingOverlayUI`)
Khác với luồng xử lý mở màn hình mới, tính năng vẽ hoạt động **trực tiếp ngay trên nền canvas hiện tại** (In-place drawing layer):
1. **Lớp vẽ Metal GPU (`StoryPKCanvasRepresentable`)**:
   - Sử dụng `PKCanvasView` của Apple PencilKit, đặt ở chế độ nền trong suốt (`backgroundColor = .clear`, `isOpaque = false`).
   - Tối ưu hóa render phần cứng bằng Metal, độ trễ cảm ứng tiệm cận 0ms.
2. **5 Loại cọ vẽ chuẩn Instagram iOS**:
   - **Bút nét (Pen)**: Nét vẽ chuẩn, sắc nét bằng `PKInkingTool(.pen)`.
   - **Mũi tên (Arrow)**: Nét vẽ có mũi tên điều hướng.
   - **Dạ quang (Marker)**: Nét mực bán trong suốt bằng `PKInkingTool(.marker)` với độ rộng nhân 2.2x.
   - **Phát sáng (Neon)**: Nét mực tỏa sáng rực rỡ với độ phủ alpha 0.9.
   - **Tẩy (Eraser)**: Tẩy vector (`PKEraserTool(.vector)`).
3. **Thanh trượt độ dày nét vẽ (`verticalDrawingStrokeWidthSlider`)**:
   - Đặt dọc mép trái với rãnh hình nêm tương tự thanh trượt font size.
   - Dải độ dày nét: từ `2pt` đến `40pt`.
4. **Bảng màu vẽ 9 màu Instagram**:
   - Trắng, Đen, Xanh dương, Xanh lá, Vàng, Cam, Đỏ san hô, Hồng đậm, Tím.
5. **Nút "Hoàn tác" (Undo)**:
   - Gọi trực tiếp `canvasView.undoManager?.undo()` để hoàn tác từng nét vẽ.
6. **Nút "Xong" (Done)**:
   - Lưu trữ lại nét vẽ trên canvas, chuyển `isDrawingMode = false` để trở về màn hình nghỉ.

---

## 3. Kiến Trúc Quản Lý Vòng Đời Bàn Phím (UIResponder Chain & UnyieldingTextView)

### A. Vấn đề cốt lõi cần giải quyết
1. **Giữ bàn phím**: Khi người dùng chạm vào các nút trên thanh công cụ định dạng (đổi font, chọn màu, chỉnh căn lề, kéo slider), bàn phím **TUYỆT ĐỐI KHÔNG ĐƯỢC ẨN ĐI HOẶC NHẤP NHÁY**.
2. **Đóng bàn phím dứt khoát**: Khi người dùng ấn nút **"Xong"** hoặc **chạm vào canvas nền**, bàn phím **PHẢI ĐÓNG LẬP TỨC**.
3. **Tránh lỗi kẹt Responder của SwiftUI**: Khi SwiftUI chuyển cờ `isEditingText = false`, view soạn thảo bị unmount ngay khỏi phân cấp view. Nếu `canResignFirstResponder` trả về `false`, UIKit sẽ từ chối hạ bàn phím, khiến bàn phím bị treo lơ lửng.

### B. Giải pháp Kỹ Thuật Chi Tiết Trong `UnyieldingTextView`

```mermaid
sequenceDiagram
    autonumber
    actor User as Người dùng
    participant Tool as Nút Format / Bảng màu
    participant Canvas as Nền Canvas / Nút Xong
    participant TextView as UnyieldingTextView
    participant KB as UIKit Keyboard Window

    Note over TextView: Đang soạn thảo: isEditingLocked = true, shouldAllowResign = false
    
    rect rgb(240, 248, 255)
        Note over User,Tool: Kịch bản 1: Tương tác thanh công cụ
        User->Tool: Chạm nút Aa / Chọn màu / Bật nền [A]
        Tool->>TextView: canResignFirstResponder?
        TextView-->>Tool: false (Từ chối hạ responder)
        Note over KB: Bàn phím giữ nguyên 100% không chớp tắt
    end

    rect rgb(255, 240, 245)
        Note over User,Canvas: Kịch bản 2: Hoàn tất soạn thảo
        User->Canvas: Chạm "Xong" hoặc Chạm canvas nền
        Canvas->>TextView: UnyieldingTextView.dismissKeyboard()
        TextView->>TextView: shouldAllowResign = true, isEditingLocked = false
        TextView->>KB: resignFirstResponder()
        Canvas->>Canvas: isEditingText = false (Hủy view overlay)
        Note over KB: Bàn phím hạ xuống mượt mà lập tức
    end
```

#### Mã nguồn triển khai:
```swift
final class UnyieldingTextView: UITextView {
    // 1. Theo dõi instance active hiện tại
    static weak var currentActiveInstance: UnyieldingTextView?

    var isEditingLocked: Bool = true
    var shouldAllowResign: Bool = false

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result { UnyieldingTextView.currentActiveInstance = self }
        return result
    }

    override func resignFirstResponder() -> Bool {
        if shouldAllowResign || !isEditingLocked {
            if UnyieldingTextView.currentActiveInstance === self {
                UnyieldingTextView.currentActiveInstance = nil
            }
            return super.resignFirstResponder()
        }
        return false
    }

    override var canResignFirstResponder: Bool {
        if shouldAllowResign || !isEditingLocked { return true }
        return false
    }

    // 2. Tự động mở khóa nếu SwiftUI unmount view khỏi superview/window
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            shouldAllowResign = true
            isEditingLocked = false
            _ = super.resignFirstResponder()
            if UnyieldingTextView.currentActiveInstance === self {
                UnyieldingTextView.currentActiveInstance = nil
            }
        }
    }

    // 3. Phương thức đóng bàn phím an toàn cấp Singleton
    static func dismissKeyboard() {
        if let active = currentActiveInstance {
            active.shouldAllowResign = true
            active.isEditingLocked = false
            _ = active.resignFirstResponder()
            currentActiveInstance = nil
        }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
```

---

## 4. Luồng Xuất Bản Nội Dung (Export & Rendering Pipeline)

Khi người dùng ấn **"Tin của bạn"** hoặc biểu tượng **`->`**:

```mermaid
flowchart TD
    Finish["finishAndExport()"] --> CheckAnim{"Có Text Animation (Typewriter, Bounce, Fade) hoặc Nhạc nền?"}
    
    CheckAnim -->|Có| VideoPath["Tạo Video MP4 (CanvasVideoRenderer)"]
    CheckAnim -->|Không| ImagePath["Tạo Ảnh JPEG (UIGraphicsImageRenderer)"]
    
    subgraph VideoEngine ["Video Rendering Engine"]
        RenderPK["renderPencilKitDrawing(targetSize: 1080x1920)"]
        AVWriter["AVAssetWriter + CVPixelBufferPool"]
        Pool["@autoreleasepool (Zero Memory Leak)"]
        RenderPK --> AVWriter
        AVWriter --> Pool
    end
    
    VideoPath --> VideoEngine
    VideoEngine --> ExportVid["Xuất Video MP4 (1080x1920, 30FPS, 5s)"]
    
    subgraph ImageEngine ["Image Rendering Engine"]
        StaticDraw["Chụp snapshot nền Gradient + Nét vẽ + Text overlay"]
        JPEGData["Nén Data JPEG 0.95 (1080x1920)"]
        StaticDraw --> JPEGData
    end
    
    ImagePath --> ImageEngine
    ImageEngine --> ExportImg["Xuất Ảnh JPEG"]
    
    ExportVid --> Dismiss["onComplete(data, isVideo: true) -> Đóng View"]
    ExportImg --> Dismiss2["onComplete(data, isVideo: false) -> Đóng View"]
```

### A. Xuất Video Động (`CanvasVideoRenderer.shared`)
- Áp dụng khi có hoạt ảnh chữ (Typewriter, Bounce, Fade) hoặc có chọn nhạc nền.
- Thời lượng mặc định: **5.0 giây**, tốc độ khung hình: **30 FPS**.
- **Tối ưu hóa bộ nhớ bắt buộc**:
  - Tái sử dụng `CVPixelBufferPool` cho mỗi khung hình render.
  - Toàn bộ vòng lặp nén khung hình được bọc trong `@autoreleasepool { ... }` để giải phóng RAM ngay lập tức, ngăn ngừa lỗi Out-Of-Memory (OOM).

### B. Xuất Ảnh Tĩnh (`exportStaticImage`)
- Áp dụng khi toàn bộ văn bản và nét vẽ là tĩnh và không có nhạc nền đính kèm.
- Kích thước canvas tiêu chuẩn: **1080 x 1920 pt (Tỉ lệ 9:16)**.
- Kết hợp cả 3 lớp: Nền Gradient theme + Nét vẽ PencilKit vector + Các khối Typography Overlay vào một tệp ảnh JPEG chất lượng cao.

---

## 5. Danh Sách Quy Tắc Hiệu Năng & Trải Nghiệm (Design System & Performance)

1. **Tuân thủ Design System**:
   - Sử dụng `DS.Spacing.*`, `DS.Size.*`, `DS.Radius.*` cho toàn bộ padding và khoảng cách.
   - Vùng cảm ứng (Hitbox) cho mọi nút công cụ tối thiểu **44x44pt** hoặc **48pt** (đối với thanh trượt slider).
2. **Haptic Safe**:
   - Toàn bộ phản hồi xúc giác khi chạm nút, cuộn carousel hoặc chọn công cụ đều sử dụng `HapticFeedbackSafe.impact()` và `HapticFeedbackSafe.selection()` để không phát sinh lỗi trên iOS Simulator.
3. **Metal GPU Acceleration**:
   - Lớp vẽ `PKCanvasView` tận dụng Metal pipeline có sẵn của hệ điều hành, đảm bảo mượt mà ngay cả khi vẽ liên tục nhiều nét phức tạp.
