# Kế Hoạch Triển Khai Loading Effect & Chống Trùng Lặp Request API (PLAN-api-loading-state-and-debouncing.md)

> **Mục tiêu:** Cung cấp phản hồi trực quan (loading / processing effect) tức thì khi người dùng thực hiện thao tác gọi API, đồng thời ngăn chặn triệt để tình trạng click liên tục vào nút bấm khi mạng chậm gây gửi trùng lặp request (duplicate data).

---

## 1. Bối Cảnh & Phân Tích Thực Tế

### 1.1. Hiện trạng giao diện & luồng người dùng
- Khi mẹ bỉm thao tác ghi nhanh hoạt động (bú bình, ăn dặm, thay tã, bắt đầu cữ ngủ, ghi cân nặng/chiều cao), hệ thống sẽ gửi một HTTP request bất đồng bộ đến backend FastAPI qua `ApiClient`.
- Nếu kết nối mạng chậm hoặc backend mất từ 500ms đến 2s để xử lý, các nút bấm trên giao diện hiện tại không đổi sang trạng thái loading cục bộ, không hiển thị vòng quay spinner và không vô hiệu hóa nút bấm (`onPressed` vẫn nhận click).
- Người dùng có xu hướng nghĩ rằng thao tác chạm chưa ăn nên tiếp tục bấm liên tục 2–3 lần.

### 1.2. Hậu quả
- Phát sinh nhiều HTTP request trùng lặp (duplicate mutations) gửi đồng thời lên backend.
- Tạo ra nhiều dòng dữ liệu rác hoặc sai lệch trong cơ sở dữ liệu (ví dụ: tạo 2 cữ bú 150ml cùng thời điểm, làm sai lệch tổng lượng sữa bú trong ngày).

---

## 2. Giải Pháp Kỹ Thuật 3 Lớp (Architecture)

```
┌─────────────────────────────────────────────────────────────────┐
│ Lớp 1: UI Level (Widget LoadingButton & Local State)            │
│ - Tự động disable nút ngay lập tức khi người dùng click         │
│ - Hiển thị spinner quay mượt + chữ "Đang lưu..."                │
│ - Cooldown 500ms chống double-tap phần cứng                     │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ Lớp 2: Network Level (ApiClient In-Flight Deduplicator)         │
│ - Interceptor bắt các request POST/PUT/DELETE đang in-flight    │
│ - Nếu cùng method + endpoint + payload: Chặn request trùng lặp  │
│ - Tự động giải phóng hash khi request hoàn tất                  │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│ Lớp 3: Global Feedback (Top Slim Linear Progress Bar)           │
│ - Thanh tiến trình mỏng 2.5px dưới App Bar đỉnh màn hình        │
│ - Hiển thị khi activeRequestsCount > 0                          │
│ - Tạo cảm giác hệ thống luôn phản hồi linh hoạt, chuyên nghiệp  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Chi Tiết Các Hạng Mục Triển Khai

### 3.1. Xây dựng Reusable Widget `LoadingButton` (`lib/core/widgets/loading_button.dart`)
- Hỗ trợ các kiểu nút: `ElevatedButton`, `OutlinedButton`, `TextButton`.
- Nhận callback `Future<void> Function()? onPressed`.
- Khi callback được kích hoạt:
  - Tự động set `isLoading = true`, đổi trạng thái nút sang disable.
  - Hiển thị spinner `SizedBox(width: 18, height: 18, CircularProgressIndicator(strokeWidth: 2, color: ...))`.
  - Hiển thị nhãn đang xử lý (ví dụ: `loadingLabel: 'Đang lưu...'`).
  - Đảm bảo khối `finally` luôn hoàn trả `isLoading = false` kể cả khi có ngoại lệ (exception).

### 3.2. Cấu hình `InFlightDeduplicationInterceptor` trong `ApiClient` (`lib/core/network/api_client.dart`)
- Duy trì một `Set<String> _inFlightRequests`.
- Tạo khóa duy nhất cho mỗi mutation: `key = "${request.method}:${request.uri}:${jsonEncode(request.data)}"`.
- Trong `onRequest`:
  - Nếu `key` đã tồn tại trong `_inFlightRequests`, từ chối request với mã lỗi nội bộ hoặc `DioException(type: DioExceptionType.cancel, message: 'Thao tác đang được xử lý, vui lòng không bấm liên tục')`.
  - Nếu chưa có: Thêm `key` vào `_inFlightRequests`.
- Trong `onResponse` và `onError`:
  - Xóa `key` khỏi `_inFlightRequests`.
- Tích hợp `ValueNotifier<int> activeRequestsCount` để thông báo cho thanh loading toàn cục.

### 3.3. Tích hợp Global Linear Progress Bar (`lib/views/main_layout.dart`)
- Lắng nghe `ApiClient().activeRequestsNotifier`.
- Khi `count > 0`, hiển thị thanh `PreferredSize` chứa `LinearProgressIndicator` mảnh (2.5px) màu `AppTheme.brand500` dưới AppBar hoặc đỉnh màn hình.

### 3.4. Refactor các Màn Hình & Bottom Sheets Nghiệp Vụ
1. **`QuickLogSheet`:**
   - Nút cữ ngủ: "Bắt đầu cữ ngủ" / "Bé đã dậy ☀️" -> Có state `_isSleepingActionLoading`.
   - Nút bú mẹ: "Bắt đầu cữ bú" / "✅ Kết thúc cữ bú" -> Có state `_isFeedingActionLoading`.
   - Nút Submit Form chính -> Tích hợp `_isSubmitting`, vô hiệu hóa nút và hiện spinner.
2. **`ActivityDetailSheet`:**
   - Nút "Kết thúc cữ bú ngay" & "Bé đã dậy" -> Tích hợp `_isFinishingOngoing`.
   - Nút "Xóa bản ghi" -> Tích hợp `_isDeleting`.
3. **`GrowthView`:**
   - Nút "Lưu số đo" / "Lưu cập nhật" trong `_showRecordDialog` -> Tích hợp `_isSavingGrowth`.
4. **`PumpingFormSheet` & `PumpingView`:**
   - Nút "Lưu cữ hút" / "Cập nhật" -> Await API hoàn tất trước khi pop modal, hiển thị spinner.
5. **`BabyPickerSheet`:**
   - Nút "Tạo hồ sơ bé" trong `_showAddBabyDialog` -> Tích hợp `_isCreatingBaby`.
6. **`RemindersView`:**
   - Nút "Tạo nhắc nhở" -> Tích hợp `_isCreatingReminder`.

---

## 4. Kế Hoạch Xác Thực & Nghiệm Thu (Acceptance Criteria)

1. **Unit & Widget Tests:**
   - Viết test cho `LoadingButton` và `InFlightDeduplicationInterceptor`.
   - Chạy lệnh `flutter test` đảm bảo 100% tests passed.
2. **Kiểm thử trên thiết bị Android thật (TECNO KL4):**
   - Mở màn hình Quick Log, bấm liên tục 5 lần vào nút "Lưu cữ bú".
   - Kiểm tra giao diện: Nút lập tức khóa và hiện icon xoay, không bị đơ, sau khi lưu xong đóng popup mượt mà.
   - Kiểm tra backend log: Chỉ nhận đúng 1 request POST duy nhất, không tạo cữ trùng lặp trong cơ sở dữ liệu.
