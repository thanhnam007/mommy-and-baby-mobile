# Danh Sách Nhiệm Vụ: Triển Khai Loading Effect & Chống Trùng Lặp Request API (TASK-api-loading-state-and-debouncing.md)

> Kế hoạch tham chiếu: `docs/PLAN-api-loading-state-and-debouncing.md`  
> Trạng thái: Đã hoàn thành (Completed & Verified)

---

## 1. Giai Đoạn 1: Tầng Hạ Tầng Mạng & Widget Dùng Chung (Infrastructure)
- [x] **Task 1.1: Xây dựng In-Flight Deduplication & Request Counter Interceptor trong `ApiClient`**
  - File: `lib/core/network/api_client.dart`
  - Bổ sung `ValueNotifier<int> activeRequestsNotifier` phát tín hiệu số lượng request đang xử lý.
  - Xây dựng logic interceptor chặn mutating request trùng lặp (cùng method + URL + body payload) khi request đầu tiên chưa trả về.
- [x] **Task 1.2: Xây dựng Reusable Widget `LoadingButton`**
  - File: `lib/core/widgets/loading_button.dart`
  - Tạo component nút bấm tự quản lý trạng thái loading, vô hiệu hóa click lặp lại, hiển thị `CircularProgressIndicator` kích thước `18x18`, viền `2px` và nhãn đang xử lý ("Đang lưu...").
- [x] **Task 1.3: Tích hợp Global Linear Progress Bar vào `MainLayout`**
  - File: `lib/views/main_layout.dart`
  - Lắng nghe `ApiClient().activeRequestsNotifier`, hiển thị thanh tiến trình mảnh (2.5px) ở đỉnh màn hình khi có request mạng đang chạy.

---

## 2. Giai Đoạn 2: Áp Dụng Loading State & Chặn Trùng Lặp Trên Màn Hình Ghi Nhanh & Dòng Thời Gian (Quick Log & Timeline)
- [x] **Task 2.1: Cập nhật `QuickLogSheet` (`lib/views/quick_log/quick_log_sheet.dart`)**
  - Thêm state `_isSubmitting`: Vô hiệu hóa nút Submit chính, hiển thị "Đang ghi nhận..." và spinner.
  - Thêm state `_isSleepingToggleLoading`: Vô hiệu hóa và hiển thị loading trên nút "Bắt đầu cữ ngủ" / "Bé đã dậy ☀️".
  - Thêm state `_isFeedingToggleLoading`: Vô hiệu hóa và hiển thị loading trên nút "Bắt đầu cữ bú" / "✅ Kết thúc cữ bú".
- [x] **Task 2.2: Cập nhật `ActivityDetailSheet` (`lib/views/timeline/activity_detail_sheet.dart`)**
  - Thêm trạng thái loading cho nút "Kết thúc cữ bú ngay" (`_isFinishingOngoingFeeding`).
  - Thêm trạng thái loading cho nút "Bé đã dậy" (`_isFinishingOngoingSleep`).
  - Thêm trạng thái loading khi bấm "Xóa bản ghi" trong hộp thoại xác nhận xóa (`_isDeleting`).
  - Đảm bảo `_isSaving` vô hiệu hóa nút "Lưu thay đổi" khi đang gọi API.

---

## 3. Giai Đoạn 3: Áp Dụng Loading State Trên Các Phân Hệ Khác (Growth, Pumping, Babies, Reminders)
- [x] **Task 3.1: Cập nhật `GrowthView` (`lib/views/growth/growth_view.dart`)**
  - Nâng cấp hộp thoại `_showRecordDialog` sang `StatefulBuilder`.
  - Thêm cờ `isSaving`, hiển thị "Đang lưu số đo..." và vô hiệu hóa nút bấm.
- [x] **Task 3.2: Cập nhật `PumpingFormSheet` & `PumpingView` (`lib/views/pumping/`)**
  - Chuyển `onSave` sang callback bất đồng bộ (`Future<void>`).
  - Thêm cờ `_isSaving`, hiển thị "Đang lưu..." trên nút "Lưu cữ hút", chỉ đóng bottom sheet sau khi API phản hồi thành công.
- [x] **Task 3.3: Cập nhật `BabyPickerSheet` (`lib/views/babies/baby_picker_sheet.dart`)**
  - Trong `_showAddBabyDialog`, thêm cờ `isCreating`, vô hiệu hóa nút "Tạo hồ sơ bé" và hiển thị spinner trong lúc gọi API.
- [x] **Task 3.4: Cập nhật `RemindersView` (`lib/views/reminders/reminders_view.dart`)**
  - Trong modal thêm nhắc nhở, thêm cờ `isCreating`, hiển thị "Đang tạo nhắc nhở..." và vô hiệu hóa nút bấm.

---

## 4. Giai Đoạn 4: Kiểm Thử, Đo Lường & Bàn Giao
- [x] **Task 4.1: Viết Widget Tests & Unit Tests**
  - Test kiểm tra `LoadingButton` không gọi `onPressed` nhiều lần khi bấm liên tục (`test/loading_button_test.dart`).
  - Test kiểm tra `ApiClient` loại bỏ request trùng lặp (`test/api_client_dedup_test.dart`).
  - Chạy `flutter test` đảm bảo 100% passed (5/5 tests).
- [x] **Task 4.2: Kiểm thử thực tế trên thiết bị Android (TECNO KL4 qua ADB)**
  - Build & Deploy APK debug mới nhất lên thiết bị qua ADB.
  - Khởi chạy app, thao tác cữ ngủ (Bắt đầu ngủ -> Bé đã dậy), kiểm tra cơ sở dữ liệu `baby_tracker.db` chỉ ghi nhận đúng 1 record duy nhất, không trùng lặp.
  - Chạy watchdog script xác thực độc lập `scripts/watchdog_verify_loading_and_dedup.py` đạt 100% PASS.
