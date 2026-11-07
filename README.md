# 🍼 Mommy & Baby Mobile App (Flutter)

Ứng dụng di động Flutter (iOS & Android) đồng hành cùng mẹ bỉm sữa trong việc theo dõi và chăm sóc bé yêu toàn diện: ghi nhận cữ bú, giấc ngủ, vệ sinh, theo dõi tăng trưởng chuẩn WHO, giám sát BabyCam Imou trực tiếp và lưu giữ kỷ niệm tuổi thơ.

---

## 🌟 Tính Năng Nổi Bật (Core Features)

1. **Quản Lý Bé Yêu & Nhiều Hồ Sơ (Baby Management):**
   - Hỗ trợ quản lý nhiều bé trên cùng một tài khoản mẹ.
   - Hiển thị ngày sinh, tự động tính chính xác số tháng tuổi và ngày tuổi.
   - Chuyển đổi nhanh giữa các bé qua Bottom Sheet hoặc Drawer trượt.

2. **Theo Dõi Cữ Bú (Feeding Tracker):**
   - **Bú mẹ trực tiếp:** Ghi nhận ngực Trái / Phải, bấm giờ thời gian thực 1-chạm hoặc nhập số phút.
   - **Bú bình:** Nhập nhanh lượng sữa (ml), phân loại sữa công thức (formula) hoặc sữa mẹ vắt (breast milk).
   - **Ăn dặm (Solid food):** 8 preset số lượng từ 30g - 250g, ghi nhận món ăn và phản ứng của bé.
   - Thống kê tự động tổng lượng sữa và thời gian cữ bú gần nhất trong ngày.

3. **Theo Dõi Giấc Ngủ (Sleep Tracker):**
   - Nút bấm 1-chạm: **Bắt đầu cữ ngủ 💤** -> **Bé đã dậy ☀️** kèm trạng thái cữ đang diễn ra trực quan.
   - Nhập thủ công thời gian ngủ và thức cho các cữ đã qua.
   - Thống kê tổng số giờ ngủ ngày / ngủ đêm trong 24h.

4. **Theo Dõi Vệ Sinh & Thay Tã (Diaper Tracker):**
   - Thao tác nhanh 1-chạm: Tè 💧, Ị 💩, hoặc Cả hai 💧💩.
   - Ghi nhận chi tiết màu sắc, tính chất phân và ghi chú tình trạng da chống hăm.

5. **Nhật Ký Hút Sữa Mẹ (Pumping Tracker):**
   - Ghi nhận thể tích hút chi tiết từng bên (vú Trái / vú Phải).
   - Biểu đồ thống kê sản lượng sữa theo ngày và phương thức bảo quản.

6. **Biểu Đồ Tăng Trưởng Chiều Cao & Cân Nặng (WHO Growth Standards):**
   - Biểu đồ tương tác thời gian thực bằng `fl_chart`.
   - Lồng ghép đường đo thực tế của bé với **Đường trung vị chuẩn WHO** và **Vùng an toàn -2SD..+2SD** từ 0 - 60 tháng tuổi.
   - Tra cứu bảng chỉ số chuẩn WHO cho bé trai / bé gái.

7. **Giám Sát BabyCam Trực Tiếp (Imou Live Camera & PTZ):**
   - Phát luồng video trực tiếp HLS (`.m3u8`) từ camera phòng bé.
   - Cụm phím điều hướng ảo PTZ 4 chiều (Lên, Xuống, Trái, Phải, Dừng) điều khiển góc quay camera.
   - Chụp ảnh snapshot khoảnh khắc đáng yêu lưu vào thư viện.

8. **Dòng Thời Gian Sinh Hoạt (Timeline):**
   - Xem toàn bộ diễn biến hoạt động trong ngày theo trình tự thời gian.
   - Bộ lọc chip pill phân loại cữ: *Tất cả, Cữ bú, Giấc ngủ, Thay tã, Khác*.
   - Chạm vào từng cữ để xem chi tiết, chỉnh sửa hoặc xóa cữ.

9. **Thư Viện Media VIP & Kỷ Niệm (Media Gallery):**
   - Lưu trữ và phân loại ảnh, video khoảnh khắc đáng yêu của bé.
   - Trình xem ảnh toàn màn hình với zoom đa điểm mượt mà.

10. **Trải Nghiệm Tối Ưu Mobile (Mobile-First UX/UI):**
    - **Dual Theme:** Chuyển đổi linh hoạt giữa giao diện Sáng (Light - Hồng phấn ấm áp) và Tối (Dark - Slate dịu mắt khi mẹ thức đêm).
    - Tối ưu hoàn hảo cho các kích thước màn hình điện thoại (360px - 390px), tuyệt đối không bị lỗi tràn màn hình (`RenderFlex overflow`).

---

## 🛠️ Công Nghệ Sử Dụng (Tech Stack)

| Thành phần | Công nghệ / Thư viện | Mục đích |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.44.x (Dart 3.12.x) | Xây dựng ứng dụng native đa nền tảng |
| **Quản lý trạng thái** | `provider: ^6.1.2` | Quản lý state theo mô hình ChangeNotifier |
| **Giao tiếp mạng** | `dio: ^5.4.3+1` | Gọi RESTful API, quản lý Bearer Token Interceptor |
| **Lưu trữ bảo mật** | `flutter_secure_storage: ^9.2.2` | Lưu JWT Access Token vào Keychain / KeyStore |
| **Lưu trữ cài đặt** | `shared_preferences: ^2.2.3` | Lưu tùy chọn Theme, Active Baby, Server URL |
| **Biểu đồ** | `fl_chart: ^0.68.0` | Vẽ biểu đồ tăng trưởng WHO và sản lượng hút sữa |
| **Phát video** | `video_player: ^2.14.1` | Phát luồng video trực tiếp từ camera phòng bé |
| **Hình ảnh** | `cached_network_image`, `image_picker` | Tải, cache ảnh và chọn ảnh từ thư viện/camera |
| **Định dạng ngày giờ** | `intl: ^0.19.0` | Định dạng ngày tháng, giờ giấc chuẩn Việt Nam |

---

## 📁 Cấu Trúc Thư Mục Dự Án

```
mommy-and-baby-mobile/
├── .github/workflows/            # CI/CD Workflows (Tự động build APK và iOS IPA)
│   ├── build_android.yml
│   └── build_ios.yml
├── android/                      # Mã nguồn và cấu hình native Android
├── assets/images/                # Logo ứng dụng và tài nguyên đồ họa
├── codemagic.yaml                # Cấu hình build tự động trên Codemagic Cloud
├── docs/                         # Tài liệu chi tiết hướng dẫn dự án
│   ├── SETUP.md                  # Hướng dẫn cài đặt môi trường & thiết bị
│   ├── BACKEND_INTEGRATION.md    # Hướng dẫn kết nối & chi tiết API FastAPI
│   ├── ARCHITECTURE.md           # Kiến trúc phần mềm & quy tắc giao diện
│   ├── PLAN-flutter-mobile-app.md# Kế hoạch phát triển tổng thể
│   └── TASK-flutter-mobile-app.md# Danh sách hạng mục nhiệm vụ
├── ios/                          # Mã nguồn và cấu hình native iOS
├── lib/
│   ├── main.dart                 # Khởi chạy app, cấu hình Provider & Theme
│   ├── core/                     # Hạ tầng dùng chung (Config, Network, Theme)
│   ├── models/                   # Lớp dữ liệu (User, Baby, Activity, Growth, Camera, ...)
│   ├── providers/                # Quản lý logic trạng thái (Auth, Baby, Activity, ...)
│   └── views/                    # Giao diện màn hình (Dashboard, Timeline, Growth, Camera, ...)
├── pubspec.yaml                  # Khai báo thư viện và tài nguyên
└── test/                         # Unit tests và Widget tests
```

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### 1. Chuẩn bị môi trường
- Đã cài đặt **Flutter SDK** (kênh stable, version `>= 3.22.0`).
- Đã cài đặt **Android Studio** hoặc Android SDK Platform-Tools (`adb`).
- Kiểm tra bằng lệnh:
  ```bash
  flutter doctor
  ```

### 2. Cài đặt packages
Di chuyển vào thư mục dự án và tải dependencies:
```bash
flutter pub get
```

### 3. Chạy ứng dụng trên thiết bị
- **Chạy trên điện thoại Android thật (Cắm cáp USB):**
  ```bash
  # 1. Bắt buộc chuyển tiếp cổng để kết nối đến backend máy tính
  adb reverse tcp:8000 tcp:8000

  # 2. Chạy ứng dụng
  flutter run
  ```

- **Chạy trên máy ảo Android Emulator:**
  ```bash
  flutter run
  ```
  *(Ứng dụng hỗ trợ địa chỉ `http://10.0.2.2:8000/api` cho máy ảo)*.

- **Chạy trên máy ảo iOS Simulator (macOS):**
  ```bash
  flutter run -d iPhone
  ```

---

## 🔗 Kết Nối Với Backend Server (FastAPI)

Ứng dụng mobile giao tiếp với backend FastAPI qua RESTful API.

### 1. Khởi động Backend Server
Tại thư mục backend của dự án mẹ (`mommy-and-baby`):
```bash
cd F:\work\mommy-and-baby\backend
.venv\Scripts\python.exe -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 --reload
```
- Swagger API Docs: `http://127.0.0.1:8000/docs`
- Health check: `http://127.0.0.1:8000/api/health`

### 2. Các phương thức kết nối mạng

| Cách kết nối | Địa chỉ Base URL | Thao tác cần thiết |
| :--- | :--- | :--- |
| **Cáp USB (Khuyên dùng)** | `http://127.0.0.1:8000/api` | Chạy lệnh `adb reverse tcp:8000 tcp:8000` |
| **Wi-Fi nội bộ (LAN)** | `http://192.168.x.x:8000/api` | Chạy backend với `--host 0.0.0.0`, chung mạng Wi-Fi |
| **Android Emulator** | `http://10.0.2.2:8000/api` | Máy ảo tự động trỏ về cổng máy tính host |
| **Production Server** | `https://api.yourdomain.com/api` | Nhập domain HTTPS của máy chủ VPS |

### 3. Đổi Server URL trực tiếp trong Ứng Dụng (Không cần Rebuild)
Ứng dụng tích hợp sẵn hộp thoại **Cài đặt máy chủ (Server Settings)**:
1. Mở màn hình chính -> Bấm biểu tượng Menu (góc trên bên trái) -> Chọn **"Cài đặt máy chủ"**.
2. Chọn nhanh một preset (USB ADB, LAN Wi-Fi, Emulator) hoặc gõ địa chỉ IP bất kỳ.
3. Bấm **"Kiểm tra kết nối"** để test `GET /health` trực tiếp với server.
4. Bấm **"Lưu & Áp dụng"** để cập nhật ngay lập tức.

Chi tiết xem tại tài liệu: [docs/BACKEND_INTEGRATION.md](docs/BACKEND_INTEGRATION.md).

---

## 📦 Hướng Dẫn Build & Đóng Gói (Release Packaging)

### Build Android APK:
```bash
# Build file APK Release Universal
flutter build apk --release

# Hoặc build tách theo ABI để file nhẹ hơn
flutter build apk --split-per-abi --release
```
File APK nằm tại: `build/app/outputs/flutter-apk/app-release.apk`.

Cài đặt nhanh vào máy bằng ADB:
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Build Android App Bundle (.aab cho Google Play):
```bash
flutter build appbundle --release
```

### Build iOS Unsigned IPA:
Tự động đóng gói thông qua GitHub Actions (`.github/workflows/build_ios.yml`) hoặc trên Codemagic Cloud (`codemagic.yaml`).

---

## 📚 Tài Liệu Kỹ Thuật Bổ Sung

- [Hướng Dẫn Cài Đặt Chi Tiết (SETUP.md)](docs/SETUP.md)
- [Chi Tiết Kết Nối & Danh Sách API (BACKEND_INTEGRATION.md)](docs/BACKEND_INTEGRATION.md)
- [Kiến Trúc & Quy Chuẩn UI/UX (ARCHITECTURE.md)](docs/ARCHITECTURE.md)
- [Kế Hoạch Dự Án Gốc (PLAN-flutter-mobile-app.md)](docs/PLAN-flutter-mobile-app.md)
- [Danh Sách Nhiệm Vụ Chi Tiết (TASK-flutter-mobile-app.md)](docs/TASK-flutter-mobile-app.md)
