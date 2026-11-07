# Kế Hoạch Triển Khai Ứng Dụng Di Động Mẹ & Bé Bằng Flutter (iOS & Android)

> **Mục tiêu:** Xây dựng ứng dụng di động native đa nền tảng (iOS & Android) hoàn chỉnh bằng Flutter, kết nối trực tiếp với hệ thống backend FastAPI hiện có của dự án (`mommy-and-baby`), mang lại trải nghiệm mượt mà, tiện lợi cho các mẹ khi chăm sóc bé hàng ngày.
> 
> **Kế hoạch chi tiết:**
> 1. Thiết kế kiến trúc ứng dụng di động tối ưu theo chuẩn Feature-First / Clean Architecture bằng Flutter 3 (Dart 3).
> 2. Tái hiện trọn vẹn toàn bộ tính năng cốt lõi: Quản lý bé yêu, Ghi cữ bú/ngủ/tã thời gian thực, Dòng thời gian, Biểu đồ Tăng trưởng WHO đa chỉ số, Xem trực tiếp BabyCam (Camera Imou) & điều khiển PTZ, Nhắc nhở thông minh và Kho lưu trữ Media kỷ niệm VIP.
> 3. Chuẩn hóa trải nghiệm người dùng (UX/UI): Dual Theme (Dark/Light) chuyển tức thì, Bottom Navigation 4 tab chính, Sidebar trượt (Drawer) chọn nhanh bé, BottomSheet thao tác nhanh mọi hoạt động với nút Bắt đầu/Kết thúc và chỉnh sửa thời gian linh hoạt, tối ưu hoàn hảo trên kích thước di động chuẩn (390×844) với filter pill chips `text-[12px]` và `pb-32`.
> 4. Thiết lập quy trình build, ký chứng thực và đóng gói cài đặt trực tiếp trên cả Android (.apk / .aab) và iOS (Xcode / TestFlight / Ad-hoc IPA).

---

## 1. Phân Tích Nghiệp Vụ & Khả Năng Tái Sử Dụng Backend

### 1.1. Hiện trạng Backend FastAPI của dự án
Hệ thống backend hiện tại (`backend/app`) đã được thiết kế chuẩn RESTful API, hoàn chỉnh các module nghiệp vụ và sẵn sàng phục vụ mobile client:
- **Xác thực (`/api/auth`):** Đăng ký, đăng nhập JWT Bearer token, lấy thông tin cá nhân (`/me`), cập nhật hồ sơ, avatar.
- **Quản lý bé yêu (`/api/babies`):** Thêm, sửa, xóa, lấy danh sách bé của tài khoản, ảnh đại diện bé.
- **Hoạt động sinh hoạt (`/api/activities`):**
  - Cữ bú (`feeding`): Bú bình (ml), bú mẹ (trực tiếp trái/phải với thời gian bắt đầu/kết thúc), tóm tắt ngày (`daily-summary`).
  - Giấc ngủ (`sleeping`): Bấm giờ thời gian thực (`start`/`end`), nhập thủ công (`manual`), tóm tắt tổng số giờ ngủ ngày/đêm.
  - Tã (`diaper`): Tè (wet), Ị (dirty), Cả hai (both), màu sắc, tính chất.
  - Sinh hoạt khác: Tắm (`bath`), vui chơi (`play`), ăn dặm (`solid`).
  - Dòng thời gian (`timeline`): Lọc theo ngày và loại hoạt động, có hỗ trợ múi giờ người dùng (`tz_offset`).
- **Tăng trưởng & Chuẩn WHO (`/api/growth`):**
  - Ghi nhận cân nặng (kg) và chiều cao (cm) theo ngày/giờ.
  - Dữ liệu biểu đồ so sánh với đường chuẩn trung vị WHO và vùng an toàn `-2SD..+2SD` cho bé trai / bé gái từ 0-60 tháng tuổi.
  - Bảng tra cứu chuẩn WHO theo từng tháng tuổi.
- **Camera Imou & Giám sát trực tiếp (`/api/cameras`):**
  - Lấy danh sách camera, luồng phát trực tiếp (HLS / RTSP / WebRTC), snapshot ảnh chụp mới nhất.
  - Điều khiển góc xoay PTZ (Lên, Xuống, Trái, Phải, Zoom, Dừng).
- **Nhắc nhở (`/api/reminders`):** Lên lịch nhắc cữ bú, uống thuốc, ngủ, thay tã; bật/tắt nhắc nhở; thông báo đến hạn.
- **Media & VIP Gallery (`/api/media`):** Upload ảnh/video kỷ niệm, gắn thẻ cữ hoạt động, phân trang xem thư viện ảnh.

### 1.2. Thách thức mạng & Kết nối từ Thiết Bị Di Động
Khi phát triển mobile app, client không chạy trên cùng máy tính với backend (`localhost`), do đó cần giải quyết:
1. **Môi trường giả lập (Emulator / Simulator):**
   - Android Emulator: Dùng địa chỉ IP đặc biệt `http://10.0.2.2:8000/api`.
   - iOS Simulator: Dùng `http://127.0.0.1:8000/api` hoặc IP máy Mac/PC.
2. **Thiết bị thật (Real Device) thử nghiệm nội bộ:**
   - Cần kết nối điện thoại vào cùng mạng Wi-Fi với máy tính chạy backend (`http://192.168.x.x:8000/api`).
   - App cần có màn hình cho phép nhập/chọn nhanh Server URL khi khởi động hoặc trong màn hình Cài đặt.
3. **Môi trường Production (Máy chủ VPS / Cloud):**
   - Domain HTTPS: `https://mommy-baby-api.yourdomain.com/api`.
4. **Quy định mạng trên OS:**
   - Android 9+ mặc định chặn kết nối HTTP không mã hóa (Cleartext Traffic) -> Cần khai báo file `network_security_config.xml`.
   - iOS cần cấu hình `NSAppTransportSecurity` trong `Info.plist` để chấp nhận gọi IP nội bộ khi phát triển.

---

## 2. Kiến Trúc Ứng Dụng Flutter (Mobile Architecture)

### 2.1. Lựa chọn Công nghệ & Thư viện (Tech Stack)
- **Framework:** Flutter SDK >= 3.22.0 (Dart 3.x), Material 3 Design System.
- **Quản lý trạng thái (State Management):** `flutter_riverpod` (v2.5+) kết hợp `state_notifier` / `AsyncNotifier` giúp quản lý luồng dữ liệu bất đồng bộ, tự động xử lý loading/error/data sạch sẽ và dễ viết unit test.
- **Giao tiếp HTTP & API Client:**
  - `dio`: HTTP client mạnh mẽ hỗ trợ Interceptors (tự động gắn token, tự động bắt lỗi 401 để chuyển hướng đăng nhập, log request/response).
  - `dio_cache_interceptor`: Cache phản hồi nhanh khi mạng yếu.
- **Lưu trữ dữ liệu cục bộ (Local Storage):**
  - `flutter_secure_storage`: Lưu Access Token JWT, Refresh Token bảo mật vào iOS Keychain / Android KeyStore.
  - `shared_preferences`: Lưu cấu hình ứng dụng (Dark/Light theme, Active Baby ID, Base API URL tùy chỉnh).
- **Biểu đồ trực quan (Charts):**
  - `fl_chart`: Thư viện vẽ biểu đồ hàng đầu cho Flutter. Dùng để vẽ biểu đồ Tăng trưởng Chiều cao & Cân nặng lồng dải WHO `-2SD..+2SD` và đường chuẩn trung vị, hỗ trợ chạm tương tác vào từng điểm đo để xem tooltip chi tiết.
- **Truyền phát Video Camera Trực Tiếp:**
  - `video_player` + `chewie`: Phát luồng video HLS (`.m3u8`) từ backend/Imou API.
  - Tùy chọn mở rộng: `flutter_webrtc` nếu backend cấu hình WebRTC stream siêu ít trễ (< 1s).
- **Thông báo & Nhắc nhở (Notifications):**
  - `flutter_local_notifications`: Bắn thông báo nội bộ định kỳ trên điện thoại đúng giờ mẹ hẹn cữ bú/uống thuốc mà không cần phụ thuộc 100% vào mạng.
  - `timezone`: Xử lý múi giờ chính xác khi lập lịch thông báo.
- **Media & Hình ảnh:**
  - `image_picker`: Chọn ảnh/video từ thư viện hoặc chụp trực tiếp từ camera.
  - `cached_network_image`: Tải và cache ảnh đại diện của bé, ảnh media kỷ niệm mượt mà, có hiệu ứng skeleton loading.

### 2.2. Cấu trúc thư mục dự án (`mobile/`)
Cấu trúc theo mô hình **Feature-First Clean Architecture**:

```
mobile/
├── android/                   # Native Android project configuration
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       └── res/xml/network_security_config.xml
├── ios/                       # Native iOS project configuration
│   └── Runner/
│       └── Info.plist
├── assets/                    # Static assets
│   ├── icons/                 # App icon, custom SVGs
│   ├── images/                # Logo, empty state illustrations
│   └── fonts/                 # Geist / Be Vietnam Pro fonts
├── lib/
│   ├── core/                  # Hạ tầng cốt lõi dùng chung
│   │   ├── config/            # AppConfig, ApiEndpoints, Env
│   │   ├── network/           # DioClient, AuthInterceptor, ErrorHandler
│   │   ├── storage/           # SecureStorageService, LocalStorageService
│   │   ├── theme/             # AppTheme (Light & Dark palette, typography, radius 8-16px)
│   │   └── utils/             # DateFormatter, WhoCalculator, Logger
│   ├── features/              # Các phân hệ tính năng nghiệp vụ
│   │   ├── auth/              # Đăng nhập, đăng ký, hồ sơ mẹ
│   │   │   ├── data/          # AuthRepository, AuthRemoteDataSource
│   │   │   ├── domain/        # UserModel, TokenModel
│   │   │   └── presentation/  # LoginScreen, RegisterScreen, ProfileScreen
│   │   ├── babies/            # Quản lý bé yêu (danh sách, thêm, sửa, đổi bé active)
│   │   │   ├── data/          # BabyRepository
│   │   │   ├── domain/        # BabyModel
│   │   │   └── presentation/  # BabySelectorSheet, BabyFormScreen
│   │   ├── dashboard/         # Trang Tổng Quan hôm nay
│   │   │   └── presentation/  # DashboardScreen, QuickActionCards, ActiveTimerBar
│   │   ├── activities/        # Ghi cữ bú, ngủ, tã, tắm, ăn dặm & Timeline
│   │   │   ├── data/          # ActivityRepository
│   │   │   ├── domain/        # ActivityModel, FeedingSummaryModel, SleepSummaryModel
│   │   │   └── presentation/  # TimelineScreen, FeedingSheet, SleepSheet, DiaperSheet
│   │   ├── growth/            # Tăng trưởng Chiều cao, Cân nặng & Chuẩn WHO
│   │   │   ├── data/          # GrowthRepository
│   │   │   ├── domain/        # GrowthRecordModel, WhoStandardModel
│   │   │   └── presentation/  # GrowthScreen, WhoGrowthChart, GrowthRecordSheet
│   │   ├── camera/            # Xem BabyCam trực tiếp & Điều khiển PTZ xoay
│   │   │   ├── data/          # CameraRepository
│   │   │   ├── domain/        # CameraModel, StreamUrlModel
│   │   │   └── presentation/  # BabyCamScreen, VideoPlayerWidget, PtzControllerPad
│   │   ├── reminders/         # Quản lý nhắc nhở & Lập lịch thông báo
│   │   │   ├── data/          # ReminderRepository
│   │   │   ├── domain/        # ReminderModel
│   │   │   └── presentation/  # RemindersScreen, ReminderFormSheet
│   │   └── media/             # Thư viện ảnh/video VIP
│   │       ├── data/          # MediaRepository
│   │       ├── domain/        # MediaItemModel
│   │       └── presentation/  # MediaGalleryScreen, MediaViewerScreen, UploadSheet
│   ├── shared/                # Widget tái sử dụng toàn app
│   │   ├── widgets/           # AppButton, AppTextField, PillChip, StatCard, EmptyView
│   │   └── layouts/           # MainNavigationShell (Bottom Nav 4 tabs + Slide Drawer)
│   └── main.dart              # Entrypoint khởi tạo app, cấu hình theme, router
├── pubspec.yaml               # Khai báo dependencies & assets
└── README.md                  # Hướng dẫn build, chạy dev & đóng gói
```

---

## 3. Thiết Kế Giao Diện & Trải Nghiệm Người Dùng (UX/UI Spec)

Theo đúng quy chuẩn thiết kế người dùng mong muốn:
1. **Hệ màu & Chủ đề (Dual Theme):**
   - **Light Theme:** Tông hồng pastel ấm áp cho mẹ (`Primary: #EC4899`, `Secondary: #F472B6`, `Background: #FFF5F7`, `Surface: #FFFFFF`, `Text: #1E293B`).
   - **Dark Theme:** Tông Slate / Navy dịu mắt khi mẹ thức đêm chăm bé (`Primary: #F472B6`, `Background: #0F172A`, `Surface: #1E293B`, `Text: #F8FAFC`).
   - **Chuyển đổi tức thì:** Nút toggle nhanh chế độ Dark/Light ngay trong Left Sidebar hoặc Header, không cần khởi động lại app.
   - **Bo góc (Border Radius):** Bo cong mềm mại từ `12px` đến `16px` cho các thẻ thẻ số, input và modal.
2. **Thanh điều hướng dưới đáy (Bottom Navigation Bar - 4 mục chính):**
   - 📊 **Tổng quan (`Dashboard`):** Tổng kết cữ bú/ngủ hôm nay, đồng hồ đếm thời gian thực cữ đang diễn ra, thẻ trạng thái tóm tắt.
   - ⏱️ **Dòng thời gian (`Timeline`):** Toàn bộ sự kiện sinh hoạt trong ngày theo thứ tự thời gian đảo ngược, hỗ trợ chip lọc nhanh (`text-[12px]`) và khoảng đệm `pb-32`.
   - 📈 **Tăng trưởng (`Growth`):** Biểu đồ cân nặng & chiều cao tích hợp chuẩn WHO, bảng tra cứu chỉ số lý tưởng theo tháng tuổi.
   - 📹 **Camera (`BabyCam`):** Xem trực tiếp bé ngủ qua camera Imou, bảng điều khiển xoay 4 hướng (PTZ) và chụp ảnh nhanh.
3. **Left Sidebar Trượt (Slide-in Drawer):**
   - Mở ra khi bấm vào icon Avatar mẹ ở góc trên bên trái hoặc vuốt nhẹ từ cạnh trái màn hình.
   - Hiển thị danh sách bé yêu với nút tích chọn chuyển đổi bé tức thì (`Active Baby`).
   - Các mục bổ trợ không làm rối Bottom Nav: ⏰ **Nhắc nhở**, 🖼️ **Thư viện Media VIP**, 👶 **Thêm bé mới**, ⚙️ **Cài đặt hệ thống (Chọn Backend Server IP / Theme)**, 🚪 **Đăng xuất**.
4. **Nút Tròn Ghi Nhanh (+) & Modal/BottomSheet Tác Vụ:**
   - Nút nổi `+` ở góc dưới phải (Floating Action Button) mở ra Quick Action BottomSheet cho phép chọn nhanh: *Bú bình*, *Bú mẹ*, *Ngủ*, *Thay tã*, *Ăn dặm*, *Đo chiều cao/cân nặng*.
   - **Mọi hoạt động đều hỗ trợ:**
     - Nút **Bắt đầu** / **Kết thúc** (tính giờ tự động).
     - Cho phép tự chọn / sửa lại ngày, giờ bắt đầu, giờ kết thúc nếu mẹ ghi bù cữ trước.
5. **Tối ưu chuẩn màn hình di động (390×844):**
   - Mọi danh sách cuộn đều có `padding-bottom: 32px` (`pb-32`) cộng thêm chiều cao an toàn của Bottom Navigation để không bị che khuất nội dung dưới cùng.
   - Bộ lọc dạng thanh trượt ngang với các chip pill nhỏ gọn, cỡ chữ `12px` (`text-[12px]`), viền mỏng thanh thoát.

---

## 4. Kế Hoạch Triển Khai Chi Tiết Từng Giai Đoạn

### Giai đoạn 1: Khởi tạo Dự Án Flutter, Cấu Hình Hệ Thống & Tầng Mạng (Network Layer)
- Khởi tạo thư mục `mobile/` bằng `flutter create --org com.avocado mommy_baby`.
- Khai báo file `pubspec.yaml` với toàn bộ dependencies cần thiết (`flutter_riverpod`, `dio`, `flutter_secure_storage`, `shared_preferences`, `fl_chart`, `video_player`, `chewie`, `image_picker`, `flutter_local_notifications`, `intl`).
- Xây dựng hệ thống Theme (`AppTheme` hỗ trợ đầy đủ Light Mode & Dark Mode, font chữ hiện đại, góc bo mềm mại).
- Xây dựng tầng mạng `DioClient`:
  - Interceptor tự động gắn `Authorization: Bearer <token>`.
  - Interceptor bắt lỗi mạng, timeout và lỗi `401 Unauthorized` để xóa cache và tự điều hướng về màn hình đăng nhập.
  - Cho phép cấu hình linh hoạt `BaseUrl` (hỗ trợ đổi Server IP trực tiếp trên giao diện để test cả máy ảo lẫn máy thật).

### Giai đoạn 2: Xác Thực Tài Khoản & Quản Lý Hồ Sơ Bé Yêu
- Xây dựng màn hình **Đăng Nhập (`LoginScreen`)** và **Đăng Ký (`RegisterScreen`)**:
  - Giao diện thân thiện, nút bấm ẩn/hiện mật khẩu, tự động lưu thông tin đăng nhập.
- Xây dựng State Provider quản lý phiên làm việc (`AuthNotifier`):
  - Tự động kiểm tra token lưu trong `FlutterSecureStorage` khi mở app.
- Xây dựng tính năng **Quản lý Bé Yêu (`BabiesFeature`)**:
  - Tải danh sách bé yêu của mẹ từ `/api/babies`.
  - Dropdown / BottomSheet chuyển đổi bé active nhanh chóng.
  - Form thêm bé mới / chỉnh sửa thông tin bé (Tên, ngày sinh, giới tính boy/girl, chiều cao & cân nặng lúc sinh, ảnh đại diện).

### Giai đoạn 3: Shell Điều Hướng, Dashboard & Dòng Thời Gian (Timeline)
- Xây dựng khung điều hướng trung tâm `MainNavigationShell`:
  - Bottom Navigation Bar 4 tabs (`Dashboard`, `Timeline`, `Growth`, `BabyCam`).
  - Left Sidebar trượt (`AppDrawer`) chứa avatar mẹ, bộ chuyển đổi bé, menu phụ và switch Dark/Light theme.
- Xây dựng màn hình **Tổng Quan (`DashboardScreen`)**:
  - Thẻ tóm tắt ngày: Tổng lượng sữa (ml), Tổng thời gian ngủ (giờ), Số lần thay tã.
  - Thanh trạng thái cữ đang diễn ra (nếu bé đang ngủ hoặc đang bú mẹ, hiển thị bộ đếm giờ chạy từng giây kèm nút "Kết thúc").
  - Nút ghi nhanh `+` mở BottomSheet chọn loại cữ.
- Xây dựng màn hình **Dòng Thời Gian (`TimelineScreen`)**:
  - Bộ lọc chip pill `text-[12px]`: `Tất cả`, `Cữ bú 🍼`, `Giấc ngủ 😴`, `Thay tã 🧷`, `Sinh hoạt khác 🎈`.
  - Danh sách thẻ sự kiện theo trục thời gian trong ngày với khoảng đệm an toàn `pb-32`.
  - Thao tác chạm để xem chi tiết, sửa thông số hoặc xóa cữ.

### Giai đoạn 4: BottomSheets Ghi Nhận Cữ Sinh Hoạt (Bú, Ngủ, Tã)
- **Cữ Bú (`FeedingSheet`):**
  - Chuyển tab nhanh: *Bú bình* (nhập số ml, loại sữa mẹ/công thức) & *Bú mẹ* (chọn ngực Trái/Phải, nút Bắt đầu/Kết thúc bấm giờ hoặc nhập số phút thủ công).
  - Cho phép chỉnh sửa thời điểm bắt đầu/kết thúc.
- **Giấc Ngủ (`SleepSheet`):**
  - Đồng hồ đếm thời gian thực (Bắt đầu ngủ -> Đang ngủ... -> Thức dậy kết thúc).
  - Chế độ nhập thủ công (Chọn giờ bắt đầu, giờ thức dậy, chất lượng giấc ngủ).
- **Thay Tã (`DiaperSheet`):**
  - Lựa chọn nhanh bằng icon: Tè 💧, Ị 💩, Cả hai 💧💩.
  - Ghi chú tính chất phân, màu sắc, tình trạng hăm tã.
- **Sinh hoạt khác (`ActivitySheet`):** Tắm bé, cho ăn dặm, vận động tummy time.

### Giai đoạn 5: Biểu Đồ Tăng Trưởng Chiều Cao, Cân Nặng & Chuẩn WHO
- Xây dựng màn hình **Tăng Trưởng (`GrowthScreen`)**:
  - Thẻ chỉ số hiện tại của bé và đánh giá nhanh theo chuẩn WHO (Bình thường, Nhẹ cân, Thấp còi, Vượt chuẩn).
  - Bộ lọc thời gian dạng chip pill (`7 ngày`, `30 ngày`, `1 năm`, `Tất cả`, `Tùy chỉnh`).
- Tích hợp biểu đồ đường tương tác bằng `fl_chart` (`WhoGrowthChart`):
  - Biểu diễn đồng thời: Đường đo thực tế của bé + Đường trung vị chuẩn WHO + Vùng an toàn `-2SD..+2SD` tô nền mờ.
  - Hỗ trợ checkbox bật/tắt hiển thị Cân nặng hoặc Chiều cao trên cùng biểu đồ.
  - Chạm vào từng điểm đo để xem tooltip chi tiết (Số đo, Ngày đo, Chênh lệch với chuẩn WHO).
- Bảng tra cứu chuẩn WHO theo từng tháng tuổi (0 - 60 tháng) tự động căn theo giới tính của bé.
- BottomSheet thêm / chỉnh sửa số đo (Ngày đo, giờ đo, cân nặng kg, chiều cao cm, ghi chú).

### Giai đoạn 6: BabyCam Trực Tiếp (Imou Camera) & Điều Khiển PTZ
- Xây dựng màn hình **BabyCam (`BabyCamScreen`)**:
  - Kết nối API `/api/cameras` để lấy danh sách camera của bé.
  - Trình phát video HLS mượt mà bằng `video_player` / `chewie`, tự động xoay ngang toàn màn hình (Fullscreen) khi mẹ bấm nút phóng to.
  - Nút chụp ảnh tức thì (Snapshot) lưu nhanh khoảnh khắc đáng yêu của bé khi đang ngủ.
  - Bảng điều khiển xoay 4 hướng (PTZ Pad: Lên, Xuống, Trái, Phải, Zoom) tương tác trực tiếp với API `/api/cameras/{id}/ptz`.

### Giai đoạn 7: Nhắc Nhở Thông Minh, Media Gallery VIP & Đóng Gói (iOS & Android)
- **Nhắc nhở (`RemindersScreen`):**
  - Đồng bộ danh sách nhắc nhở từ backend.
  - Đăng ký Local Notification qua `flutter_local_notifications` để đổ chuông/rung đúng giờ hẹn trên điện thoại.
- **Thư viện Media VIP (`MediaGalleryScreen`):**
  - Hiển thị lưới ảnh/video kỷ niệm của bé, chạm để xem ảnh phóng to hoặc phát video.
  - Tích hợp `image_picker` và upload ảnh/video trực tiếp lên `/api/media/upload` có thanh tiến trình (progress bar).
- **Cấu hình & Đóng gói Cài đặt:**
  - **Android:**
    + Cấu hình `network_security_config.xml` cho phép test HTTP mạng LAN.
    + Cấu hình quyền trong `AndroidManifest.xml` (Camera, Micro, Notifications, Internet).
    + Sinh mã khóa ký release `upload-keystore.jks` và cấu hình `key.properties`.
    + Đóng gói APK cài đặt trực tiếp (`flutter build apk --release`) và App Bundle (`flutter build appbundle`).
  - **iOS:**
    + Cấu hình quyền và lý do sử dụng bằng tiếng Việt trong `Info.plist` (Camera, Thư viện ảnh, Micro, Local Network).
    + Cấu hình Team & Signing trong Xcode.
    + Đóng gói file cài đặt `.ipa` (Development / Ad-Hoc / TestFlight).

---

## 5. Quy Trình Cài Đặt Thử Nghiệm Trên Thiết Bị Thật

### 5.1. Cài đặt trên Android
1. **Qua cáp USB (Chế độ Nhà phát triển):**
   - Bật `USB Debugging` trên điện thoại Android.
   - Cắm cáp vào máy tính và chạy:
     ```bash
     flutter run --release
     ```
2. **Cài đặt qua file APK độc lập:**
   - Chạy lệnh build:
     ```bash
     flutter build apk --release --split-per-abi
     ```
   - Lấy file APK tại `mobile/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` gửi qua Google Drive, Zalo hoặc cắm cáp chép vào điện thoại để cài đặt trực tiếp.

### 5.2. Cài đặt trên iOS (iPhone/iPad)
1. **Yêu cầu:** Máy tính chạy macOS có cài đặt Xcode (hoặc sử dụng dịch vụ CI/CD như Codemagic / GitHub Actions nếu build từ xa).
2. **Chạy trực tiếp lên iPhone qua Xcode:**
   - Kết nối iPhone với máy Mac, bật `Developer Mode` trên iPhone (iOS 16+).
   - Mở thư mục `mobile/ios` bằng Xcode, chọn Apple ID miễn phí hoặc Apple Developer Program trong mục `Signing & Capabilities`.
   - Chọn thiết bị iPhone đích và bấm nút **Run** (Play) hoặc chạy:
     ```bash
     flutter run -d <iPhone_ID>
     ```
3. **Cài đặt qua TestFlight / Ad-hoc IPA:**
   - Xuất file `.ipa` từ Xcode Organizer hoặc lệnh `flutter build ipa`.
   - Phân phối qua link TestFlight hoặc cài đặt trực tiếp qua Apple Configurator / Sideloadly.

---

## 6. Tiêu Chí Nghiệm Thu (Acceptance Criteria)

- [ ] Dự án Flutter biên dịch thành công không có lỗi trên cả Android và iOS.
- [ ] Đăng nhập và lưu phiên an toàn bằng JWT token, tự động gắn token vào header và xử lý mượt mà khi hết hạn.
- [ ] Chọn và đổi bé yêu tức thì, dữ liệu Dashboard và Timeline cập nhật chính xác theo bé được chọn.
- [ ] Ghi cữ bú, giấc ngủ, thay tã hoạt động đầy đủ cả chế độ bấm giờ thực tế và nhập/sửa thời gian thủ công.
- [ ] Biểu đồ Tăng trưởng hiển thị chuẩn xác số đo của bé, lồng đường chuẩn WHO và dải an toàn, hỗ trợ bộ lọc linh hoạt.
- [ ] Luồng phát BabyCam xem mượt mà, điều khiển xoay PTZ và chụp snapshot hoạt động tốt.
- [ ] Thông báo nhắc nhở cữ được kích hoạt đúng giờ trên thiết bị.
- [ ] Giao diện hỗ trợ chuyển đổi Dark / Light mode tức thì, giao diện chuẩn đẹp trên màn hình 390×844 với filter chips `text-[12px]` và `pb-32`.
- [ ] Xuất bản thành công file cài đặt APK cho Android và hướng dẫn cài đặt iOS rõ ràng.
