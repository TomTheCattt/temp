# Project Rules & Guidelines for Instagram iOS

## 1. Yêu Cầu Tối Ưu Hiệu Năng Toàn Diện (Mandatory Performance for All Plans & Features)

> **QUY TẮC CỐT LÕI 1**: Việc **Tối Ưu Hiệu Năng (Performance Optimization)** là yêu cầu bắt buộc áp dụng cho **MỌI kế hoạch** và **MỌI tính năng**, không có ngoại lệ. Trong bất kỳ kế hoạch kỹ thuật nào, luôn phải có một phần riêng biệt cam kết, phân tích giải pháp và đặt chỉ số đo lường hiệu năng cụ thể.

### Các Nguyên Tắc Hiệu Năng Bắt Buộc:
1. **Zero Memory Leak & OOM Prevention**:
   - Mọi vòng lặp xử lý hình ảnh, video frames (`AVAssetWriter`), hoặc nén dữ liệu lặp đi lặp lại phải được bọc trong `@autoreleasepool { ... }` để giải phóng bộ nhớ ngay lập tức sau mỗi chu kỳ.
   - Bắt buộc tái sử dụng buffer qua `CVPixelBufferPool` khi render video, nghiêm cấm cấp phát mới (alloc) bộ nhớ liên tục trong render loop.
2. **Non-blocking UI & Modern Concurrency (Task, Combine, Async/Await)**:
   - Ưu tiên tuyệt đối các giải pháp hiện đại của Swift: `async/await`, `Task`, `TaskGroup`, `actor`, `@MainActor`, `AsyncStream`, và `Combine` (`AnyCancellable`, Publishers) thay thế hoàn toàn cho GCD cũ kỹ (`DispatchQueue`, semaphore, completion callbacks lồng nhau).
   - Bảo vệ trạng thái chia sẻ (thread safety) qua `actor` để loại bỏ data races ở cấp độ compile-time của Swift 6.
   - Luôn đảm bảo ViewModels và mọi thao tác cập nhật giao diện người dùng (UI) được đánh dấu `@MainActor`.
   - Hỗ trợ Cooperative Cancellation: Luôn hủy `Task` hoặc `cancellables` khi view biến mất (`onDisappear` / `deinit`) để tiết kiệm CPU và pin.
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

## 3. Quy Trình Tiếp Nhận, Lập Kế Hoạch 5 Bước & Phê Duyệt (Mandatory 5-Step Planning & Approval Workflow)

> **QUY TẮC CỐT LÕI 3**: Mọi yêu cầu kỹ thuật phải tuân thủ nghiêm ngặt **Quy trình 5 Bước Chuẩn Mực (B1 -> B5)**. Khi có yêu cầu điều tra hoặc công việc phức tạp, **BẮT BUỘC phải lập kế hoạch để người dùng phê duyệt trước**. **NGHIÊM CẤM TỰ Ý CODE KHI CHƯA CÓ SỰ CHO PHÉP / PHÊ DUYỆT CỦA NGƯỜI DÙNG**.

### Quy Trình 5 Bước Chi Tiết:
- **B1. Xác Định Rõ Mục Tiêu Nhiệm Vụ & Độ Phức Tạp**:
  - Phân loại: **Sửa lỗi (Bug Fix)** hay **Phát triển tính năng mới (New Feature / Refactor)**.
  - Đánh giá độ phức tạp:
    - *Task Đơn Giản (Minor / Simple Task)* (sửa typo, chỉnh chuỗi dịch, đổi hằng số đơn lẻ): Thực hiện trực tiếp và kiểm tra ngay.
    - *Task Phức Tạp / Thay Đổi Luồng / UI Layout / Logic / Design System*: Bắt buộc chuyển sang B2 và B3.
- **B2. Điều Tra Các File Liên Quan & Luồng Kiến Trúc**:
  - Truy vết toàn diện trong Clean Architecture (`Presentations → Domain ← Data`).
  - Kiểm tra các file liên quan: View, ViewModel, Model, Use Case, Service, Mock Data, Asset Catalog, Design System Tokens (`DS.*`, `ColorTokens.*`).
  - Lập danh sách file cần sửa đổi hoặc tạo mới, xác định ranh giới ảnh hưởng.
- **B3. Lên Kế Hoạch Triển Khai & Tự Phản Biện Bản Thân (Kèm Approval Gate)**:
  - Lập tài liệu kế hoạch kỹ thuật chi tiết (Implementation Plan Artifact).
  - Tự phản biện qua 4 câu hỏi: *Tại sao viết như vậy? Phương án đã tối ưu hiệu năng/bộ nhớ tối đa chưa? Có bị thừa/lặp code không? Đã là phiên bản tốt nhất chưa?*
  - **STRICT APPROVAL GATE**: **DỪNG LẠI CHỜ NGƯỜI DÙNG PHÊ DUYỆT**. Chỉ bắt tay viết code khi người dùng xác nhận đồng ý (ví dụ: "triển khai", "ok", "duyệt").
- **B4. Xây Dựng Test Cases Cho Main & Edge Cases + Chạy Kiểm Thử Có Output Proof**:
  - Xây dựng đầy đủ Test Cases cho **Main Cases** (luồng chính, UI chuẩn) và **Edge Cases** (nil, empty, network timeout, dark/light mode, rotation, memory pressure).
  - Biên dịch toàn bộ dự án (`xcodebuild build` exit code 0 VÀ triệt tiêu 100% warnings - Zero Warning Policy) và chạy test runner tự động.
  - Cung cấp **Output Proof** xác thực (lệnh shell, exit code 0, trích đoạn log pass, kiểm tra 0 warnings, URI file log - tuân thủ Zero Fabrication).
- **B5. Chạy Benchmark Đo Hiệu Suất, Hiệu Năng Có Empirical Proof**:
  - Sử dụng `ContinuousClock` trong Swift 6.4 (hoặc `CFAbsoluteTimeGetCurrent()`) để đo thời gian thực thi định lượng và mức độ tiêu thụ tài nguyên.
  - Cung cấp bằng chứng đo đạc thực tế (trích xuất console log thời gian thực tế `ms`, đảm bảo 0 ms Main Thread blocking, duy trì 60/120 FPS).

---

## 4. Yêu Cầu Bắt Buộc Về Bằng Chứng Kiểm Thử Thực Tế (Mandatory Verifiable Test Evidence - Zero Fabrication & Zero Warning)

> **QUY TẮC CỐT LÕI 4**: Sau khi thực thi một task phức tạp, **BẮT BUỘC PHẢI CÓ BẰNG CHỨNG KIỂM THỬ THỰC TẾ**. **NGHIÊM CẤM BỊA ĐẶT HOẶC BÁO CÁO KHỐNG KẾT QUẢ KHI CHƯA THỰC SỰ CHẠY LỆNH KIỂM TRA**. Tiêu chuẩn hoàn thành bắt buộc phải thỏa mãn song song: **Build Success (Exit code 0)** VÀ **Zero Warnings (0 compiler warnings)**.

### Các Yêu Cầu Cụ Thể:
1. **Bằng Chứng Đầu Ra Thực Tế (Verifiable Execution Proof) & Zero Warning**:
   - Sau khi hoàn thành code, bắt buộc phải chạy lệnh kiểm thử thực tế (ví dụ: `xcodebuild`, test suite, linter).
   - Tiêu chuẩn nghiệm thu hoàn thành task (Task Completion Definition) bắt buộc phải đạt song song cả 2 tiêu chí:
     1. Build thành công (`Exit code 0`, `** BUILD SUCCEEDED **`).
     2. Tuyệt đối không có compiler warning nào trong toàn bộ dự án (`0 warnings` - Zero Warning Policy). Nếu phát sinh bất kỳ warning nào, task được coi là **CHƯA HOÀN THÀNH** và phải được xử lý triệt để trước khi báo cáo kết thúc.
   - Phải cung cấp bằng chứng rõ ràng, có thể kiểm chứng được:
     - Câu lệnh shell chính xác đã thực thi.
     - Mã thoát (`Exit code 0`).
     - Trích đoạn log kết quả thực tế (ví dụ: `** BUILD SUCCEEDED **`, danh sách test case đã pass).
     - Xác nhận số lượng compiler warnings thực tế (`0 Swift compiler warnings`).
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

---

## 6. Tự Phản Biện Trong Quá Trình Viết Code & Tiêu Chuẩn Chất Lượng Code Cao Nhất (Mandatory Code Self-Critique & Code Excellence)

> **QUY TẮC CỐT LÕI 6**: Mỗi khi triển khai viết bất kỳ dòng mã nào, **BẮT BUỘC PHẢI TỰ PHẢN BIỆN BẢN THÂN** trước khi hoàn thành tệp hoặc commit. Code đầu ra luôn phải là **phiên bản tốt nhất** (Best-in-class / Production-ready). Tuyệt đối nghiêm cấm viết code sơ sài, cẩu thả, chắp vá hoặc dừng lại ở mức "chạy được là xong".

### Bộ Câu Hỏi Tự Phản Biện Bắt Buộc Khi Triển Khai Code:
1. **Tại Sao Lại Viết Như Thế Này? (Design Intent & Architecture Rationale)**:
   - Tại sao lại chọn cấu trúc / pattern này thay vì giải pháp khác?
   - Mã nguồn có tuân thủ nghiêm ngặt ranh giới Clean Architecture (`Presentations → Domain ← Data`) không? Có lạm dụng `@ObservedObject` / `@State` hay logic bị rò rỉ vào tầng hiển thị không?
   - Cách viết này có tự nhiên, thanh lịch (Idiomatic Swift 6 / SwiftUI) và dễ bảo trì lâu dài không?
2. **Code Đã Được Tối Ưu Tối Đa Chưa? (Deep Performance & Modern Concurrency)**:
   - Đã ưu tiên sử dụng `async/await`, `Task`, `@MainActor`, `actor`, `Combine` thay vì GCD `DispatchQueue` cũ kỹ chưa?
   - Đã xử lý hủy tác vụ (Task cancellation / `AnyCancellable`) khi view biến mất để chống rò rỉ tài nguyên chưa?
   - Có tạo object / closure / modifier dư thừa làm re-trigger SwiftUI view body hoặc re-layout không?
   - Các tác vụ tính toán, parsing, filter, hoặc xử lý đồ họa / video đã được đưa vào background actor/Task chưa?
   - Đã kiểm soát bộ nhớ triệt để: bọc `@autoreleasepool` khi cần, xử lý `[weak self]` tránh retain cycle, dùng buffer pool / thumbnail downsampling chưa?
3. **Code Có Bị Thừa / Lặp Không? (Zero Duplication & DRY)**:
   - Logic, modifier, animation, hoặc UI snippet này đã tồn tại ở đâu trong codebase chưa? Có thể tái sử dụng token (`DS.*`), atomic component (`InstagramButton`, `InstagramAvatarView`), hoặc Core Utilities không?
   - Có bất kỳ dòng code, import không dùng, biến trung gian, modifier vô nghĩa, hay fallback thừa thãi nào không? Cắt bỏ và tinh gọn tối đa.
4. **Code Đầu Ra Đã Là Phiên Bản Tốt Nhất Chưa? (Best Possible Quality Gate)**:
   - Tên biến, struct, protocol, function đã đạt độ trực quan, tự giải thích (self-documenting) và nhất quán cao nhất chưa?
   - Xử lý lỗi (error handling) và tất cả edge cases (nil, empty list, network timeout, cancel) đã được bao quát thanh thoát, không crash, không fail âm thầm chưa?
   - Đã triệt tiêu 100% compiler warnings (`0 warnings` - Zero Warning Policy) để bảo đảm chất lượng mã nguồn sạch tuyệt đối chưa?
   - Code đã sẵn sàng vượt qua các bài review khắt khe nhất của các kỹ sư cấp cao (Senior / Staff iOS Engineer) chưa?

---

## 7. Bắt Buộc Kiểm Tra Tính Toàn Vẹn Ngữ Nghĩa & Đồng Bộ Dữ Liệu Xuyên Màn Hình (End-to-End Semantic Data Integrity & State Walkthrough)

> **QUY TẮC CỐT LÕI 7**: Nghiêm cấm tuyệt đối việc dừng lại ở mức "Biên dịch thành công (Build Pass)", "Khớp kiểu dữ liệu (Type Match)" hoặc "Tối ưu hạ tầng kỹ thuật (Actor/Concurrency/Warnings)" mà bỏ qua **Tính toàn vẹn ngữ nghĩa (Semantic Integrity) và logic trải nghiệm người dùng thực tế**. Mọi luồng dữ liệu kết nối giữa các màn hình bắt buộc phải được kiểm tra đồng bộ logic 100%.

### Các Yêu Cầu Cụ Thể:
1. **End-to-End User Journey Walkthrough**:
   - Khi điều tra, sửa lỗi hoặc phát triển bất kỳ tính năng nào, bắt buộc phải truy vết toàn diện hành trình trải nghiệm người dùng qua các màn hình liên quan:
     - *Màn hình danh sách (Parent List View) hiển thị trạng thái X &rarr; Người dùng bấm vào xem Màn hình chi tiết (Detail View) thì dữ liệu có khớp 100% với trạng thái X hay không?*
     - *Khi người dùng tạo mới, sửa, hoặc xóa dữ liệu ở Màn hình chi tiết, Màn hình danh sách bên ngoài có cập nhật tức thì (Real-time sync) hay không?*
2. **Single Source of Truth Tuyệt Đối**:
   - Nghiêm cấm việc sinh dữ liệu giả lập (mock data) rời rạc, tách biệt giữa màn hình danh sách và màn hình chi tiết.
   - Toàn bộ dữ liệu chi tiết và tóm tắt (`lastMessage`, `unreadCount`, `likeCount`, `avatarURL`) bắt buộc phải bắt nguồn từ cùng một kho dữ liệu duy nhất (`inMemoryMessages`, `inMemoryConversations`).
3. **Độ Nhạy Cảm Với Code Smells Khi Điều Tra**:
   - Khi phát hiện bất kỳ đoạn mã nào gán cứng dữ liệu (`MockData.users.first`), sinh tin nhắn từ mảng tách biệt không liên quan, hoặc thiếu bước cập nhật danh sách cha khi con thay đổi, **BẮT BUỘC PHẢI CHỈ RA VÀ XỬ LÝ TRIỆT ĐỂ**, tuyệt đối không được bỏ qua chỉ vì "nó không thuộc phạm vi dòng lệnh đang sửa".

---

## 8. Nguyên Tắc Phản Biện Đa Chiều & Tìm Kiếm Giải Pháp Tối Ưu (Mutual Critical Thinking & Constructive Pushback)

> **QUY TẮC CỐT LÕI 8**: Cả người dùng lẫn AI đều không phải lúc nào cũng luôn đúng. Bắt buộc phải duy trì tư duy **phản biện đa chiều (critical thinking)**: luôn tự phản biện các phương án của chính mình và đồng thời sẵn sàng phản biện, đặt câu hỏi, đưa ra góc nhìn khách quan đối với các yêu cầu hoặc giả định từ phía người dùng để cùng nhau tìm ra giải pháp tối ưu nhất về kỹ thuật, thẩm mỹ, UX và hiệu năng.

### Các Yêu Cầu Cụ Thể:
1. **Nghiêm Cấm Tuân Thủ Mù Quáng (No Blind Compliance)**:
   - Khi người dùng đưa ra một định hướng hoặc yêu cầu, nếu nhận thấy phương án đó có lỗ hổng kiến trúc, rủi ro về hiệu năng (memory leak, OOM, Main Thread blocking), xung đột với HIG/Instagram chuẩn, hoặc có giải pháp thay thế vượt trội hơn, **BẮT BUỘC PHẢI NÊU RÕ VẤN ĐỀ VÀ PHẢN BIỆN MỘT CÁCH XÂY DỰNG**.
   - Trình bày rõ ràng: *Ưu điểm, Nhược điểm, Rủi ro tiềm ẩn, và Phương án đề xuất tối ưu hơn (kèm lý do kỹ thuật thuyết phục)*.
2. **Tự Phản Biện Bản Thân Không Khoan Nhượng (Relentless Self-Doubt & Cross-Examination)**:
   - Trước khi đưa ra bất kỳ đề xuất hoặc kết luận nào, phải tự hỏi: *Liệu giải pháp này có sai sót ngầm nào không? Có cách nào viết đơn giản hơn, nhanh hơn, ít tốn bộ nhớ hơn không? Người dùng hoặc Senior Reviewer có thể bắt lỗi điểm nào?*
   - Thẳng thắn thừa nhận và chỉnh sửa ngay khi phát hiện phương án của mình chưa tối ưu hoặc có sai lệch.
3. **Mục Tiêu Tối Thượng Là Chất Lượng Sản Phẩm (Truth-Seeking Over Agreement)**:
   - Mục đích của phản biện không phải là tranh cãi, mà là hợp tác tìm ra sự thật kỹ thuật (technical truth) và giải pháp hoàn hảo nhất cho ứng dụng Instagram.

