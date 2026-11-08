# Kế Hoạch Triển Khai Loading & Processing Effect, Chống Trùng Lặp Request API

> **Tài liệu tham chiếu:** `docs/PLAN-api-loading-state-and-debouncing.md` & `docs/TASK-api-loading-state-and-debouncing.md`  
> **Mục tiêu:** Cung cấp phản hồi trực quan (loading / processing effect) tức thì khi người dùng thực hiện thao tác gọi API, đồng thời ngăn chặn triệt để tình trạng click liên tục vào nút bấm khi mạng chậm gây gửi trùng lặp request (duplicate data).

---

## 1. Vấn Đề Hiện Tại & Phân Tích Nguyên Nhân Gốc (Root Cause)

1. **Thiếu phản hồi trạng thái trên các nút hành động (No Loading Feedback on Buttons):**
   - Trong các bottom sheet như `QuickLogSheet` (ghi cữ bú, giấc ngủ, thay tã, ăn dặm), `GrowthView` (lưu số đo), `PumpingFormSheet` (lưu cữ hút), `BabyPickerSheet` (tạo hồ sơ bé), nút "Lưu" hoặc "Bắt đầu / Kết thúc" không có trạng thái loading cục bộ.
   - Khi bấm, nút vẫn giữ nguyên trạng thái bấm được (`onPressed` không bị disable thành `null`), không có biểu tượng quay (spinner), cũng không có văn bản thay đổi (ví dụ: "Đang lưu...").
2. **Hiện tượng "đơ" giả lập khi độ trễ mạng cao (Perceived App Freeze):**
   - Các thao tác gọi API tốn từ 400ms đến 2500ms tùy vào tốc độ mạng và backend. Trong khoảng thời gian này, giao diện không có bất kỳ hiệu ứng chuyển động nào khiến người dùng lầm tưởng chạm không ăn.
   - Hệ quả: Người dùng nhấn nút liên tiếp 2–4 lần, dẫn tới việc gửi nhiều HTTP POST/PUT giống hệt nhau lên backend FastAPI, tạo ra các bản ghi trùng lặp (ví dụ: 2 cữ bú 120ml cùng 1 phút, 2 giấc ngủ đè lên nhau, 2 bản ghi cân nặng giống hệt).
3. **Thiếu cơ chế bảo vệ ở tầng mạng (No In-Flight Request Deduplication / Throttle):**
   - Tầng mạng `Dio` trong `ApiClient` chưa có bộ lọc chặn (interceptor) ngăn việc gửi lặp lại các mutating request (POST, PUT, DELETE) có cùng method, endpoint và payload khi request trước đó vẫn đang trong trạng thái xử lý (in-flight).

---

## 2. Giải Pháp Toàn Diện 3 Lớp (3-Layer Solution)

### Lớp 1: Widget Nút Bấm Xử Lý Bất Đồng Bộ (`LoadingButton` / `DebouncedAsyncButton`)
- **Đặc điểm:**
  - Nhận `Future<void> Function()? onPressed`.
  - Tự động chuyển `isLoading = true` ngay khi người dùng chạm vào nút.
  - Vô hiệu hóa nút (`onPressed = null`) trong suốt quá trình hàm bất đồng bộ đang chạy.
  - Hiển thị spinner nhỏ gọn `SizedBox(width: 18, height: 18, CircularProgressIndicator(strokeWidth: 2))` kết hợp đổi nhãn chữ thành "Đang lưu...", "Đang xử lý..." với màu sắc hài hòa theo Material 3.
  - Tích hợp thời gian hồi chiêu (cooldown/debounce 500ms) để triệt tiêu hoàn toàn các cú double-tap phần cứng hoặc vô tình chạm hai lần cực nhanh.

### Lớp 2: Bộ Chặn Chống Trùng Lặp Request Tại Tầng Mạng (`InFlightDeduplicationInterceptor`)
- **Đặc điểm trong `ApiClient`:**
  - Theo dõi danh sách các mutating request (`POST`, `PUT`, `DELETE`, `PATCH`) đang bay (in-flight) dựa trên chuỗi định danh: `${options.method}:${options.path}:${jsonEncode(options.data)}`.
  - Nếu một request trùng khớp được phát đi trong khi request trước chưa nhận response, interceptor sẽ lập tức chặn request thứ hai lại và trả về cảnh báo an toàn hoặc hủy bỏ không gửi lên server.
  - Khi request hoàn tất (thành công hoặc thất bại), mã định danh sẽ được giải phóng khỏi danh sách theo dõi.

### Lớp 3: Hiệu Ứng Thanh Tiến Trình Toàn Cục Mỏng (Global Slim Progress Indicator)
- **Đặc điểm:**
  - Đặt một `LinearProgressIndicator` mảnh (`height: 2.5px`, màu `AppTheme.brand500`) nằm ngay dưới thanh AppBar hoặc đỉnh màn hình `MainLayout`.
  - Kết nối với `ApiClient` qua bộ đếm `activeRequestsCount`: khi có bất kỳ request nào đang chạy, thanh tiến trình tự động lướt mượt mà báo hiệu ứng dụng đang làm việc; khi tất cả request xong, thanh tiến trình ẩn đi.

---

## 3. Danh Sách Màn Hình & Vị Trí Cần Nâng Cấp

1. **`QuickLogSheet` (`lib/views/quick_log/quick_log_sheet.dart`):**
   - Nút hành động cữ ngủ trực tiếp: "Bắt đầu cữ ngủ" / "Bé đã dậy ☀️".
   - Nút hành động bú mẹ trực tiếp: "Bắt đầu cữ bú" / "✅ Kết thúc cữ bú".
   - Nút Submit chính phía dưới cho các loại: Bú bình (bottle), Ăn dặm (solid), Giấc ngủ (sleep), Bú mẹ (breast), Tã (diaper), Tắm (bath), Chơi (play).
2. **`ActivityDetailSheet` (`lib/views/timeline/activity_detail_sheet.dart`):**
   - Nút "Kết thúc cữ bú ngay" & "Bé đã dậy" trong thẻ cữ đang diễn ra.
   - Nút "Lưu thay đổi" trong chế độ sửa.
   - Nút "Xóa bản ghi" trong hộp thoại xác nhận.
3. **`GrowthView` (`lib/views/growth/growth_view.dart`):**
   - Hộp thoại `_showRecordDialog`: Nút "Lưu số đo" / "Lưu cập nhật".
4. **`PumpingFormSheet` & `PumpingView` (`lib/views/pumping/`):**
   - Nút "Lưu cữ hút" / "Cập nhật". Đảm bảo await hoàn thành trước khi đóng modal.
5. **`BabyPickerSheet` (`lib/views/babies/baby_picker_sheet.dart`):**
   - Hộp thoại `_showAddBabyDialog`: Nút "Tạo hồ sơ bé".
6. **`RemindersView` (`lib/views/reminders/reminders_view.dart`):**
   - Hộp thoại tạo nhắc nhở: Nút "Tạo nhắc nhở".
7. **`ProfileView` (`lib/views/profile/profile_view.dart`):**
   - Nút "Lưu thông tin" và nút "Đăng xuất".

---

## 4. Kế Hoạch Kiểm Thử & Xác Nhận (Verification Plan)

1. **Kiểm thử Unit & Widget Test:**
   - Viết widget test cho `LoadingButton`: kiểm tra nút bị vô hiệu hóa khi đang loading, hiển thị CircularProgressIndicator, và không cho phép kích hoạt callback lần 2 khi chưa kết thúc.
   - Viết unit test cho `InFlightDeduplicationInterceptor`: giả lập 2 request POST trùng nhau gửi cùng lúc, kiểm tra request thứ 2 bị chặn.
2. **Kiểm thử trên Thiết bị thật (TECNO KL4 qua ADB):**
   - Bấm nhanh liên tục nhiều lần vào nút "Lưu" trong Quick Log hoặc "Ghi số đo".
   - Xác nhận:
     - Nút lập tức chuyển sang trạng thái loading với spinner quay mượt.
     - Nút bị mờ/disable, không thể bấm thêm lần thứ hai.
     - Backend FastAPI trong log chỉ nhận đúng 1 request HTTP POST duy nhất, hoàn toàn không sinh duplicate records.
