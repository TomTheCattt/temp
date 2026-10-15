# Project Rules & Guidelines for Instagram iOS

## 1. Yêu Cầu Tối Ưu Hiệu Năng (Mandatory Performance Planning)

> **QUY TẮC CỐT LÕI**: Luôn luôn phải có một phần riêng biệt cam kết và phân tích giải pháp **Tối Ưu Hiệu Năng (Performance Optimization)** trong mọi kế hoạch triển khai tính năng hoặc tái cấu trúc mã nguồn.

### Các Nguyên Tắc Hiệu Năng Bắt Buộc:
1. **Zero Memory Leak & OOM Prevention**:
   - Mọi vòng lặp xử lý hình ảnh, video frames (`AVAssetWriter`), hoặc nén dữ liệu lặp đi lặp lại phải được bọc trong `@autoreleasepool { ... }` để giải phóng bộ nhớ ngay lập tức.
   - Tái sử dụng buffer qua `CVPixelBufferPool` khi render video, không cấp phát bộ nhớ liên tục trong render loop.
2. **Non-blocking UI & Multi-threading**:
   - Toàn bộ tác vụ nặng (tách nền Vision, encode video, xử lý CoreImage/Filter, giải nén ảnh lớn, render composite) phải được điều hướng sang background queue (`qos: .userInitiated`).
   - Giữ Main Thread hoàn toàn thông thoáng để duy trì tần số quét 60/120 FPS ProMotion.
3. **Memory Capping & Safe Image Downsampling**:
   - Khi nhận ảnh từ người dùng hoặc camera, luôn nén và downsample ảnh về kích thước hiển thị mục tiêu (ví dụ: tối đa 1080px đối với sticker/feed) bằng `CGImageSourceCreateThumbnailAtIndex` trước khi lưu vào RAM. Không giữ nguyên ảnh gốc 48MP/20MB trong bộ nhớ.
4. **Zero Layout Thrashing & Persistent UI Focus**:
   - Khi người dùng tương tác soạn thảo văn bản hoặc vẽ nét, giữ nguyên trạng thái bàn phím và bộ hiển thị, tránh trigger các chu kỳ re-layout không cần thiết của SwiftUI.
5. **Haptic Safe**:
   - Luôn sử dụng `HapticFeedbackSafe` để tránh phát sinh lỗi `CHHapticPattern CocoaError 260` trên iOS Simulator.
