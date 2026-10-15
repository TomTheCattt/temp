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

---

## 3. Quy Trình Tiếp Nhận, Phân Loại, Điều Tra & Phê Duyệt Kế Hoạch (Mandatory Intake, Planning & Approval Workflow)

> **QUY TẮC CỐT LÕI 3**: Mọi yêu cầu từ người dùng phải được phân loại và đánh giá độ phức tạp trước khi hành động. Khi có yêu cầu điều tra hoặc công việc phức tạp, **BẮT BUỘC phải lập kế hoạch để người dùng phê duyệt trước**. **NGHIÊM CẤM TỰ Ý CODE KHI CHƯA CÓ SỰ CHO PHÉP / PHÊ DUYỆT CỦA NGƯỜI DÙNG**.

### Quy Trình Cụ Thể:
1. **Xác Nhận & Phân Loại Yêu Cầu**:
   - Khi tiếp nhận yêu cầu, cần xác nhận rõ ràng:
     - Đây là **Phát triển tính năng mới (New Feature)** hay **Sửa lỗi (Bug Fix)**.
     - Mục tiêu cụ thể và phạm vi tác động.
2. **Đánh Giá Độ Phức Tạp & Quyết Định Lên Kế Hoạch**:
   - **Task Đơn Giản (Minor / Simple Task)** (ví dụ: sửa nội dung text, sửa typo, cập nhật chuỗi bản dịch localization, chỉnh một giá trị hằng số đơn lẻ): **KHÔNG CẦN LÊN KẾ HOẠCH**, tiến hành thực hiện trực tiếp và kiểm tra kết quả ngay.
   - **Task Phức Tạp / Thay Đổi Luồng / UI Layout / Logic Nghiệp Vụ / Tương Tác**: Bắt buộc phải điều tra kỹ lưỡng nguyên nhân gốc rễ và lập kế hoạch kỹ thuật chi tiết.
3. **Quy Tắc Phê Duyệt Trước Khi Code (Strict Approval Gate)**:
   - Khi người dùng yêu cầu điều tra hoặc task có độ phức tạp cao: Điều tra codebase, phân tích nguyên nhân, đối chiếu hành vi chuẩn và **trình bày kế hoạch chi tiết (Implementation Plan)**.
   - **DỪNG LẠI CHỜ NGƯỜI DÙNG PHÊ DUYỆT**. Chỉ bắt tay vào viết code khi người dùng xác nhận phê duyệt (ví dụ: "triển khai", "ok", "duyệt", "tiến hành"). Tuyệt đối không tự ý sửa code trước khi có sự đồng ý.

---

## 4. Yêu Cầu Bắt Buộc Về Bằng Chứng Kiểm Thử Thực Tế (Mandatory Verifiable Test Evidence - Zero Fabrication)

> **QUY TẮC CỐT LÕI 4**: Sau khi thực thi một task phức tạp, **BẮT BUỘC PHẢI CÓ BẰNG CHỨNG KIỂM THỬ THỰC TẾ**. **NGHIÊM CẤM BỊA ĐẶT HOẶC BÁO CÁO KHỐNG KẾT QUẢ KHI CHƯA THỰC SỰ CHẠY LỆNH KIỂM TRA**.

### Các Yêu Cầu Cụ Thể:
1. **Bằng Chứng Đầu Ra Thực Tế (Verifiable Execution Proof)**:
   - Sau khi hoàn thành code, bắt buộc phải chạy lệnh kiểm thử thực tế (ví dụ: `xcodebuild`, test suite, linter).
   - Phải cung cấp bằng chứng rõ ràng, có thể kiểm chứng được:
     - Câu lệnh shell chính xác đã thực thi.
     - Mã thoát (`Exit code 0`).
     - Trích đoạn log kết quả thực tế (ví dụ: `** BUILD SUCCEEDED **`, danh sách test case đã pass).
     - Đường dẫn tệp log thực tế trên hệ thống (log file URI).
2. **Nghiêm Cấm Tuyệt Đối Hành Vi Bịa Đặt (Strict Zero-Fabrication Policy)**:
   - Tuyệt đối không được suy đoán, giả lập, hoặc tự ý tuyên bố "đã test thành công" khi chưa chạy công cụ kiểm thử.
   - Nếu lệnh kiểm thử gặp lỗi hoặc thất bại, phải trích xuất log lỗi trung thực, phân tích nguyên nhân gốc rễ và xử lý triệt để cho đến khi có bằng chứng pass thực tế.
3. **Quy Định Đo Lường Hiệu Năng & Chỉ Số Định Lượng (Benchmark & Metric Proof)**:
   - **Nghiêm cấm tự ý đưa ra các con số định lượng** (ví dụ: "giảm từ ~800ms xuống 16ms", "tiết kiệm 50MB RAM", "đạt 60/120 FPS") nếu không có log đo đạc thực tế đính kèm.
   - Mọi tuyên bố về thời gian xử lý hoặc mức tiêu thụ tài nguyên bắt buộc phải có bằng chứng từ:
     - Log thực thi benchmark (sử dụng `ContinuousClock`, `CFAbsoluteTimeGetCurrent()`, hoặc XCTest `measure { ... }`).
     - Trích đoạn console log in ra thời gian thực thi (timestamp/duration) trước và sau tối ưu.
   - Nếu chưa hoặc không thể đo đạc thực tế trên môi trường hiện tại, **phải nói rõ là ước lượng lý thuyết**, tuyệt đối không được báo cáo như một kết quả đo kiểm thực tế đã hoàn thành.

---

## 5. Tuyệt Đối Không Tự Suy Diễn (Zero Assumption), Tự Phản Biện Chặt Chẽ & Đồng Bộ Quy Tắc .kiro

> **QUY TẮC CỐT LÕI 5**: Nghiêm cấm tuyệt đối mọi hành vi **TỰ SUY DIỄN / ĐOÁN MÒ** về giao diện (UI), trải nghiệm (UX), logic nghiệp vụ, và luồng hoạt động (User Flow). Mọi phương án kỹ thuật đề xuất bắt buộc phải **suy nghĩ thấu đáo, tự phản biện bản thân, ưu tiên tối đa trải nghiệm người dùng, tính thẩm mỹ và tối ưu hiệu năng**, đồng thời tuân thủ 100% các quy định đã định nghĩa tại thư mục `.kiro/`.

### Các Yêu Cầu Cụ Thể:
1. **Tuân Thủ Bộ Quy Tắc Tại Thư Mục `.kiro/`**:
   - Bắt buộc tuân thủ toàn diện các chỉ dẫn kỹ thuật trong `.kiro/steering/project-guidelines.md` và `.kiro/steering/feature-file-map.md`:
     - **Clean Architecture**: `Presentations → Domain ← Data`. Domain thuần Swift, không phụ thuộc framework bên ngoài.
     - **Điều hướng (Navigation)**: Chỉ dùng `AppRouter.shared.push/present`, tuyệt đối không dùng inline `NavigationLink`.
     - **Design System**: Không hard-code giá trị số, bắt buộc dùng `DS.Spacing.*`, `DS.Size.*`, `DS.Radius.*`, `DS.Font.*`, `ColorTokens.*`.
     - **Tối ưu tài nguyên**: Sử dụng chung `FilterEngine.shared.ciContext`, giới hạn tối đa 3 `AVPlayer` đồng thời qua `VideoPlayerManager.shared`, tải ảnh từ xa qua `LazyImage` (NukeUI) và luôn dùng thumbnail downsampled.
2. **Nghiêm Cấm Tự Suy Diễn UI, UX, Logic & Luồng (Zero Speculation)**:
   - Khi phát triển bất kỳ tính năng hoặc màn hình nào, tuyệt đối không tự ý quyết định hoặc suy diễn luồng hoạt động, cấu trúc layout, hay các giá trị kích thước.
   - Khi gặp điểm chưa rõ ràng hoặc còn nhiều hướng xử lý: **BẮT BUỘC PHẢI HỎI XÁC NHẬN TỪ PHÍA NGƯỜI DÙNG** trước khi lên kế hoạch chi tiết hoặc triển khai.
3. **Quy Trình Tự Phản Biện Bản Thân (Rigorous Self-Critique)**:
   - Trước khi đề xuất bất kỳ giải pháp nào cho người dùng, phải tự phản biện qua các câu hỏi:
     - *Phương án này đã bám sát 1:1 chuẩn Instagram app gốc trên iOS chưa?*
     - *Trải nghiệm người dùng (UX) và công thái học chạm (touch ergonomics) đã đạt chuẩn chưa? Vùng tương tác ngón tay có đạt tối thiểu 44-48pt không?*
     - *Tính thẩm mỹ thị giác (Visual Polish, spacing, contrast, shadow) đã thực sự tinh tế chưa?*
     - *Hiệu năng đã được cam kết: không block Main Thread, zero memory leak, duy trì 60/120 FPS chưa?*
