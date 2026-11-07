# Danh Sách Nhiệm Vụ: Triển Khai Ứng Dụng Di Động Mẹ & Bé Bằng Flutter (TASK-flutter-mobile-app.md)

> Kế hoạch tham chiếu: `docs/PLAN-flutter-mobile-app.md` & `.hermes/plans/2026-11-06_100000-flutter-mobile-app.md`
> Trạng thái: Chờ duyệt (Pending Approval)

---

## 1. Giai Đoạn 1: Khởi Tạo Dự Án Flutter & Tầng Hạ Tầng (Infrastructure)
- [ ] **Task 1.1: Khởi tạo Project Flutter & Thiết lập `pubspec.yaml`**
  - Tạo cấu trúc thư mục `mobile/` bằng `flutter create --org com.avocado mommy_baby`.
  - Khai báo các thư viện thiết yếu: `flutter_riverpod`, `dio`, `flutter_secure_storage`, `shared_preferences`, `fl_chart`, `video_player`, `chewie`, `image_picker`, `flutter_local_notifications`, `intl`, `cached_network_image`.
- [ ] **Task 1.2: Xây dựng Hệ Thống Theme & Color Palette (`mobile/lib/core/theme/app_theme.dart`)**
  - Hỗ trợ đầy đủ Light Mode (Hồng phấn ấm áp) & Dark Mode (Slate / Navy dịu mắt khi mẹ thức đêm).
  - Tích hợp chuẩn bo góc `12px` - `16px`, typography sắc nét.
- [ ] **Task 1.3: Xây dựng Quản Lý Cấu Hình & Môi Trường (`mobile/lib/core/config/app_config.dart`)**
  - Quản lý API Base URL linh hoạt: Tự động hỗ trợ Android Emulator (`10.0.2.2:8000`), iOS Simulator (`127.0.0.1:8000`), và IP mạng LAN (`192.168.x.x:8000`) có thể chỉnh sửa trực tiếp trong app.
- [ ] **Task 1.4: Xây dựng Tầng Mạng `DioClient` & Interceptors (`mobile/lib/core/network/dio_client.dart`)**
  - Tự động đính kèm `Authorization: Bearer <token>`.
  - Bắt lỗi mạng, timeout và tự động xóa phiên đăng nhập khi gặp lỗi `401 Unauthorized`.
- [ ] **Task 1.5: Dịch vụ Lưu Trữ Cục Bộ (`mobile/lib/core/storage/storage_service.dart`)**
  - Lưu Access Token an toàn bằng `FlutterSecureStorage`.
  - Lưu tùy chọn người dùng (Theme, Active Baby ID, Base URL) bằng `SharedPreferences`.

---

## 2. Giai Đoạn 2: Xác Thực Tài Khoản & Quản Lý Bé Yêu (Auth & Babies)
- [ ] **Task 2.1: Màn hình Đăng Nhập & Đăng Ký (`mobile/lib/features/auth/presentation/`)**
  - Xây dựng `LoginScreen.dart` và `RegisterScreen.dart`.
  - Form nhập thông tin, nút ẩn/hiện mật khẩu, kiểm tra hợp lệ dữ liệu (validation).
  - Kết nối API `/api/auth/login` và `/api/auth/register`.
- [ ] **Task 2.2: Quản lý Trạng Thái Xác Thực (`AuthNotifier`)**
  - Kiểm tra trạng thái đăng nhập khi mở app, tự động đăng nhập nếu token còn hiệu lực.
  - Xử lý Đăng xuất và dọn sạch session.
- [ ] **Task 2.3: Quản lý Danh Sách Bé Yêu (`mobile/lib/features/babies/`)**
  - Gọi API `/api/babies` lấy danh sách bé.
  - Quản lý `ActiveBabyNotifier`: lưu và chuyển đổi bé đang chọn trên toàn bộ app.
  - Xây dựng `BabyFormScreen.dart`: Thêm bé mới hoặc chỉnh sửa thông tin (Tên, ngày sinh, giới tính, chiều cao/cân nặng lúc sinh, ảnh avatar).

---

## 3. Giai Đoạn 3: Shell Điều Hướng, Dashboard & Dòng Thời Gian (Timeline)
- [ ] **Task 3.1: Xây dựng Khung Điều Hướng `MainNavigationShell`**
  - Thanh điều hướng đáy (Bottom Navigation Bar) gồm 4 tab chính: 📊 Tổng quan, ⏱️ Dòng thời gian, 📈 Tăng trưởng, 📹 BabyCam.
  - Left Sidebar trượt (Slide-in Drawer) chứa avatar mẹ, bộ chọn đổi bé, các mục phụ (Nhắc nhở, Thư viện VIP, Cài đặt server IP, Chế độ Sáng/Tối, Đăng xuất).
- [ ] **Task 3.2: Màn hình Tổng Quan (`mobile/lib/features/dashboard/presentation/DashboardScreen.dart`)**
  - Thẻ tóm tắt cữ trong ngày: Lượng sữa bú (ml), Tổng thời gian ngủ (giờ), Số lần thay tã.
  - Thanh trạng thái cữ đang diễn ra (Timer đếm giây thực tế nếu bé đang ngủ hoặc đang bú mẹ, kèm nút "Kết thúc").
  - Nút tròn nổi ghi nhanh (`+`) mở Quick Action BottomSheet.
- [ ] **Task 3.3: Màn hình Dòng Thời Gian (`mobile/lib/features/activities/presentation/TimelineScreen.dart`)**
  - Bộ lọc chip pill `text-[12px]`: `Tất cả`, `Cữ bú 🍼`, `Giấc ngủ 😴`, `Thay tã 🧷`, `Khác 🎈`.
  - Danh sách thẻ hoạt động theo thứ tự mới nhất xếp trên, có khoảng đệm an toàn `pb-32`.
  - Thao tác bấm vào thẻ để xem chi tiết, chỉnh sửa hoặc xóa cữ.

---

## 4. Giai Đoạn 4: BottomSheets Ghi Nhận Hoạt Động Sinh Hoạt
- [ ] **Task 4.1: BottomSheet Ghi Cữ Bú (`FeedingSheet.dart`)**
  - Chuyển đổi linh hoạt giữa *Bú bình* (nhập ml, loại sữa) và *Bú mẹ* (chọn ngực Trái/Phải, nút Bắt đầu / Kết thúc hoặc nhập số phút thủ công).
  - Cho phép chọn/sửa lại ngày giờ bắt đầu và kết thúc cữ bú.
- [ ] **Task 4.2: BottomSheet Ghi Giấc Ngủ (`SleepSheet.dart`)**
  - Hỗ trợ 2 chế độ: Bấm giờ ngủ trực tiếp (Bắt đầu -> Kết thúc) hoặc Nhập thủ công thời gian ngủ/thức.
  - Cho phép chỉnh sửa thời gian ngủ và ghi chú.
- [ ] **Task 4.3: BottomSheet Thay Tã (`DiaperSheet.dart`)**
  - Nút chọn nhanh: Tè 💧, Ị 💩, Cả hai 💧💩.
  - Ô chọn màu sắc, tính chất phân và ghi chú tình trạng da.
- [ ] **Task 4.4: BottomSheet Hoạt Động Khác (`OtherActivitySheet.dart`)**
  - Ghi nhận hoạt động tắm bé, ăn dặm (loại món, lượng ăn), vận động tummy time.

---

## 5. Giai Đoạn 5: Biểu Đồ Tăng Trưởng Chiều Cao, Cân Nặng & Chuẩn WHO
- [ ] **Task 5.1: Màn hình Tăng Trưởng (`mobile/lib/features/growth/presentation/GrowthScreen.dart`)**
  - Thẻ tóm tắt chỉ số hiện tại (Cân nặng, Chiều cao, BMI) và đánh giá nhanh theo chuẩn WHO.
  - Bộ lọc chip pill thời gian: `7 ngày`, `30 ngày`, `1 năm`, `Tất cả`, `Tùy chỉnh`.
- [ ] **Task 5.2: Biểu Đồ Đường Tương Tác `WhoGrowthChart.dart` (Sử dụng `fl_chart`)**
  - Vẽ chung trên cùng biểu đồ: Đường đo thực tế của bé + Đường trung vị chuẩn WHO + Vùng chuẩn an toàn `-2SD..+2SD` tô nền mờ.
  - Hỗ trợ checkbox ẩn/hiện chỉ số Cân nặng hoặc Chiều cao.
  - Chạm vào từng điểm đo để xem tooltip chi tiết và nút sửa nhanh.
- [ ] **Task 5.3: Bảng Tra Cứu Chuẩn WHO Theo Tháng Tuổi**
  - Tra cứu chỉ số lý tưởng từ 0 - 60 tháng cho bé trai / bé gái, tự động làm nổi bật (highlight) tháng tuổi hiện tại của bé.
- [ ] **Task 5.4: BottomSheet Ghi Nhận Số Đo (`GrowthRecordSheet.dart`)**
  - Nhập cân nặng (kg) và chiều cao (cm), chọn ngày và giờ đo linh hoạt, ghi chú kèm theo.

---

## 6. Giai Đoạn 6: Xem Trực Tiếp BabyCam (Imou Camera) & Điều Khiển PTZ
- [ ] **Task 6.1: Màn hình Giám Sát BabyCam (`mobile/lib/features/camera/presentation/BabyCamScreen.dart`)**
  - Kết nối API `/api/cameras` để lấy camera đã gán của bé.
  - Tích hợp trình phát video luồng HLS (`video_player` / `chewie`) mượt mà, hỗ trợ phóng to toàn màn hình.
- [ ] **Task 6.2: Bảng Điều Khiển Xoay Camera (PTZ Pad)**
  - Cụm phím điều hướng ảo 4 chiều (Lên, Xuống, Trái, Phải, Dừng) gọi API `/api/cameras/{id}/ptz`.
- [ ] **Task 6.3: Tính Năng Chụp Ảnh Snapshot Khoảnh Khắc**
  - Nút bấm chụp ảnh tức thì từ luồng camera và lưu nhanh vào bộ sưu tập ảnh kỷ niệm của bé.

---

## 7. Giai Đoạn 7: Nhắc Nhở Thông Minh, Thư Viện Media VIP & Đóng Gói Ứng Dụng
- [ ] **Task 7.1: Màn hình Nhắc Nhở & Lập Lịch Local Notifications (`RemindersScreen.dart`)**
  - Đồng bộ danh sách nhắc nhở từ backend (`/api/reminders`).
  - Lập lịch thông báo ngoại tuyến trên điện thoại bằng `flutter_local_notifications` theo đúng giờ hẹn cữ bú, giấc ngủ hoặc uống thuốc.
- [ ] **Task 7.2: Thư Viện Ảnh/Video VIP (`MediaGalleryScreen.dart`)**
  - Lưới hiển thị hình ảnh kỷ niệm phân trang mượt mà (`cached_network_image`).
  - Chọn ảnh/video từ máy bằng `image_picker` và upload lên `/api/media/upload` kèm progress bar.
- [ ] **Task 7.3: Màn hình Cài Đặt Hệ Thống (`SettingsScreen.dart`)**
  - Chuyển đổi Dark/Light mode tức thì.
  - Cấu hình địa chỉ IP máy chủ Backend (tiện lợi cho việc test qua mạng LAN Wi-Fi nội bộ mà không cần rebuild app).
- [ ] **Task 7.4: Cấu Hình & Đóng Gói Bản Cài Đặt Android**
  - Cấu hình file `AndroidManifest.xml` đầy đủ các quyền: Internet, Camera, Photo Library, Notifications.
  - Thêm `network_security_config.xml` để cho phép kết nối HTTP qua mạng LAN khi thử nghiệm.
  - Cấu hình file `key.properties` và lệnh xuất file APK release: `flutter build apk --release`.
- [ ] **Task 7.5: Cấu Hình & Đóng Gói Bản Cài Đặt iOS**
  - Cấu hình `Info.plist` các quyền truy cập bằng tiếng Việt rõ ràng.
  - Cấu hình Signing Certificate & Bundle Identifier trong Xcode.
  - Hướng dẫn chi tiết chạy qua Xcode trên iPhone thật và xuất file `.ipa`.
