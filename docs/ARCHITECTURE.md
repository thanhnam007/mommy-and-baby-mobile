# Kiến Trúc Ứng Dụng Di Động (Mobile Architecture Guide)

Tài liệu này mô tả chi tiết kiến trúc kỹ thuật của dự án **Mommy & Baby Flutter Mobile App**, tổ chức tầng lớp (Layered Architecture), cơ chế quản lý trạng thái với `Provider`, và các giải pháp thiết kế giao diện tối ưu cho màn hình di động nhỏ.

---

## 1. Cấu Trúc Dự Án (Directory Structure)

Ứng dụng được tổ chức theo mô hình phân tầng hướng tính năng (Feature-driven / Clean Pattern):

```
mommy-and-baby-mobile/
├── android/                      # Native Android configuration (Manifest, Gradle, Icons)
├── ios/                          # Native iOS configuration (Info.plist, Podfile, Assets)
├── assets/
│   └── images/                   # Logo, logo mark, placeholder graphics
├── docs/                         # Toàn bộ tài liệu kỹ thuật, setup, backend specs
├── scripts/                      # Tool hỗ trợ (sinh bộ icon ứng dụng tự động)
├── lib/
│   ├── main.dart                 # Điểm khởi chạy ứng dụng (Entry point, MultiProvider setup)
│   ├── core/                     # Hạ tầng dùng chung toàn app
│   │   ├── config/
│   │   │   └── app_config.dart   # Quản lý Base URL động, SharedPreferences
│   │   ├── network/
│   │   │   └── api_client.dart   # Dio HTTP Client, Interceptors, Bearer Auth, Error parser
│   │   └── theme/
│   │       └── app_theme.dart    # Bảng màu Dual Theme (Dark/Light), Typography, bo góc 12-16px
│   ├── models/                   # Data Models & Serialization (JSON to Dart)
│   │   ├── user_model.dart       # User, Token, Profile
│   │   ├── baby_model.dart       # Baby, Gender, Birth Stats
│   │   ├── activity_model.dart   # Feeding, Sleeping, Diaper, Solid food, Daily Summary
│   │   ├── growth_model.dart     # Weight, Height, WHO Standard points
│   │   ├── pumping_model.dart    # Left/Right breast volumes, Pumping Session
│   │   ├── camera_model.dart     # Imou Camera stream, PTZ, Snapshots
│   │   ├── reminder_model.dart   # Scheduled alerts, repeats
│   │   └── media_model.dart      # Photos, Videos, Albums
│   ├── providers/                # Tầng Quản lý Trạng thái (ChangeNotifier Providers)
│   │   ├── auth_provider.dart
│   │   ├── baby_provider.dart
│   │   ├── activity_provider.dart
│   │   ├── growth_provider.dart
│   │   ├── pumping_provider.dart
│   │   ├── camera_provider.dart
│   │   ├── reminder_provider.dart
│   │   ├── media_provider.dart
│   │   └── theme_provider.dart
│   └── views/                    # Tầng Giao diện Người Dùng (Presentation)
│       ├── main_layout.dart      # Shell 4 Tab đáy + Left Drawer trượt
│       ├── auth/                 # Màn hình Đăng nhập & Đăng ký
│       ├── dashboard/            # Trang Tổng quan hôm nay (KPI Cards, cữ đang diễn ra)
│       ├── timeline/             # Lịch sử sinh hoạt chi tiết, BottomSheet xem & sửa cữ
│       ├── growth/               # Biểu đồ WHO fl_chart, bảng tra cứu chỉ số, ghi số đo
│       ├── pumping/              # Nhật ký hút sữa, biểu đồ sản lượng, form nhập
│       ├── camera/               # Giám sát Camera Imou trực tiếp, PTZ D-pad điều khiển
│       ├── media/                # Thư viện ảnh/video kỷ niệm VIP, xem ảnh fullscreen
│       ├── reminders/            # Quản lý danh sách nhắc nhở thông minh
│       ├── profile/              # Hồ sơ mẹ, thông tin cá nhân, cài đặt
│       ├── babies/               # BottomSheet chọn hoặc đổi bé đang theo dõi
│       ├── quick_log/            # FAB (+) BottomSheet ghi nhanh tức thì mọi hoạt động
│       └── settings/             # Hộp thoại đổi Base URL Server và kiểm tra kết nối
└── test/
    └── widget_test.dart          # Unit & Widget tests
```

---

## 2. Luồng Quản Lý Trạng Thái (State Management Flow)

Dự án áp dụng thư viện `Provider` kết hợp `ChangeNotifier`:

```
[View / Widget]
      │
      ▼ (Gọi hàm nghiệp vụ, ví dụ: addActivity, fetchTimeline)
[ChangeNotifier Provider]
      │
      ▼ (Gửi HTTP Request kèm Bearer Token)
[ApiClient (Dio)]
      │
      ▼ (RESTful API JSON)
[Backend Server (FastAPI)]
      │
      ▲ (Trả về JSON Response)
[Model Mapping] (Model.fromJson)
      │
      ▲ (notifyListeners())
[Widget Tự Động Re-render]
```

### Ưu điểm kiến trúc:
1. **Phân tách trách nhiệm hoàn toàn:** Giao diện chỉ nhận dữ liệu hiển thị và bắn sự kiện người dùng, không chứa logic gọi HTTP thô.
2. **Khả năng kiểm thử cao:** Tầng Provider và Model độc lập, có thể viết Unit Test dễ dàng với mock dữ liệu.
3. **Cập nhật dữ liệu thời gian thực (Reactive):** Khi một cữ mới được thêm hoặc cữ ngủ kết thúc, `ActivityProvider` tự động reload `fetchDailySummary` và `fetchTimeline`, cập nhật đồng thời cả trang Dashboard và trang Timeline.

---

## 3. Các Quy Tắc UI/UX Quan Trọng Cho Thiết Bị Di Động (360–390px)

### 3.1. Tránh Lỗi Tràn Màn Hình: Sử Dụng `Wrap` Thay Vì `Row`
- **Vấn đề:** Các nhóm chip lựa chọn (ví dụ: lượng ăn dặm 30g, 50g, 80g... hoặc các chỉ số cân nặng / chiều cao) nếu đặt trong `Row` nằm ngang sẽ ngay lập tức gây lỗi `RenderFlex overflowed by X pixels` trên các màn hình hẹp (360px - 390px).
- **Quy chuẩn:** Luôn bọc bằng `Wrap(spacing: 8, runSpacing: 8)` để các phần tử tự động xuống dòng mượt mà khi hết chỗ.

### 3.2. Căn Lề Hộp Thoại (Modal Dialog Inset Padding)
- Mặc định `Dialog` của Flutter có `insetPadding: EdgeInsets.symmetric(horizontal: 40)`. Trên màn hình 360px, việc này làm mất tới 80px lề hai bên, khiến nội dung bên trong bị chèn ép.
- Dự án ghi đè chuẩn: `Dialog(insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24))`.

### 3.3. Dual-Mode BottomSheet: Hỗ Trợ Cữ Đang Diễn Ra (Ongoing Activities)
- Với các hoạt động có thời lượng (cữ ngủ, bú mẹ trực tiếp), mẹ bỉm thường bắt đầu cữ trước rồi mới kết thúc sau.
- BottomSheet hỗ trợ 2 chế độ:
  1. **Quick Toggle:** 1 chạm để bắt đầu ngay (hiển thị chấm live nhấp nháy), 1 chạm để kết thúc khi bé dậy hoặc bú xong.
  2. **Thủ công & Chỉnh sửa:** Hỗ trợ xóa giờ kết thúc (`null`) để chuyển cữ thành *Đang diễn ra*, hoặc nhập đầy đủ cả giờ bắt đầu và giờ kết thúc.

### 3.4. Tránh Che Khuất Nội Dung Bởi Nút Nổi (FAB)
- Toàn bộ các danh sách cuộn (`ListView`, `SingleChildScrollView`) được thiết lập khoảng đệm đáy an toàn `padding: EdgeInsets.only(bottom: 120)` để nút bấm hành động nổi (FAB `+`) và thanh Bottom Navigation không bao giờ che khuất các phần tử ở cuối danh sách.

### 3.5. Biểu Đồ Tăng Trưởng Với `fl_chart`
- Đường chuẩn trung vị và dải giới hạn WHO `-2SD..+2SD` được dựng thông qua `ExtraLinesData(horizontalLines: [...])` hoặc đường chuẩn so sánh, đảm bảo khi bé chỉ mới có 1 điểm đo đầu tiên thì biểu đồ vẫn hiển thị rõ ràng đường chuẩn toàn chiều rộng mà không bị lỗi crash tính toán tọa độ.
