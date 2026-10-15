# Project Rules & Guidelines for Instagram iOS

## 1. Yêu Cầu Tối Ưu Hiệu Năng Toàn Diện (Mandatory Performance for All Plans & Features)

> **QUY TẮC CỐT LÕI 1**: Việc **Tối Ưu Hiệu Năng (Performance Optimization)** là yêu cầu bắt buộc áp dụng cho **MỌI kế hoạch** và **MỌI tính năng**, không có ngoại lệ. Trong bất kỳ kế hoạch kỹ thuật nào, luôn phải có một phần riêng biệt cam kết, phân tích giải pháp và đặt chỉ số đo lường hiệu năng cụ thể.

### Các Nguyên Tắc Hiệu Năng Bắt Buộc:
1. **Zero Memory Leak & OOM Prevention**:
   - Mọi vòng lặp xử lý hình ảnh, video frames (`AVAssetWriter`), hoặc nén dữ liệu lặp đi lặp lại phải được bọc trong `@autoreleasepool { ... }` để giải phóng bộ nhớ ngay lập tức sau mỗi chu kỳ.
   - Bắt buộc tái sử dụng buffer qua `CVPixelBufferPool` khi render video, nghiêm cấm cấp phát mới (alloc) bộ nhớ liên tục trong render loop.
2. **Non-blocking UI & Multi-threading**:
   - Toàn bộ tác vụ nặng (tách nền Vision, encode video, xử lý CoreImage/Filter, giải nén ảnh lớn, render composite) phải được điều hướng sang background queue (`qos: .userInitiated`).
   - Giữ Main Thread hoàn toàn thông thoáng để duy trì tần số quét 60/120 FPS ProMotion.
3. **Memory Capping & Safe Image Downsampling**:
   - Khi nhận ảnh từ người dùng hoặc camera, luôn nén và downsample ảnh về kích thước hiển thị mục tiêu (ví dụ: tối đa 1080px đối với sticker/feed) bằng `CGImageSourceCreateThumbnailAtIndex` trước khi lưu vào RAM. Không giữ nguyên ảnh gốc 48MP/20MB trong bộ nhớ.
4. **Zero Layout Thrashing & Persistent UI Focus**:
   - Khi người dùng tương tác soạn thảo văn bản hoặc vẽ nét, giữ nguyên trạng thái bàn phím và bộ hiển thị, tránh trigger các chu kỳ re-layout không cần thiết của SwiftUI.
5. **Haptic Safe**:
   - Luôn sử dụng `HapticFeedbackSafe` để tránh phát sinh lỗi `CHHapticPattern CocoaError 260` trên iOS Simulator.

---

## 2. Quy Định Cập Nhật & Tạo Tài Liệu Sau Khi Hoàn Thành Kế Hoạch (Mandatory Documentation Updates)

> **QUY TẮC CỐT LÕI 2**: Mỗi khi thực hiện xong một kế hoạch đã được phê duyệt, **BẮT BUỘC phải tạo mới hoặc cập nhật tài liệu tương ứng** (plan artifact, tài liệu kiến trúc, checklist hoàn thành, kết quả kiểm tra `xcodebuild`, commit log).

### Yêu Cầu Cụ Thể:
1. **Cập Nhật Trạng Thái Kế Hoạch**:
   - Ngay sau khi hoàn tất các bước code và build pass, phải đánh dấu `[x]` vào tất cả các mục đã hoàn thành trong tài liệu kế hoạch.
   - Bổ sung mục báo cáo kết quả kiểm thử thực tế và các quyết định kỹ thuật phát sinh (nếu có).
2. **Đồng Bộ Tài Liệu Kiến Trúc & Hướng Dẫn**:
   - Mọi thay đổi về cấu trúc luồng (flow), service mới, hoặc schema dữ liệu mới đều phải được phản ánh đầy đủ trong tài liệu tương ứng để đảm bảo tài liệu và mã nguồn luôn đồng nhất 100%.
