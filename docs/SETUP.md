# Hướng Dẫn Cài Đặt & Phát Triển Ứng Dụng (Setup Guide)

Tài liệu này hướng dẫn chi tiết từng bước thiết lập môi trường phát triển, cài đặt công cụ cần thiết và khởi chạy ứng dụng **Mommy & Baby Mobile** trên cả máy tính (Windows / macOS / Linux) và thiết bị thật (Android / iOS).

---

## 1. Yêu Cầu Môi Trường (System Prerequisites)

| Công cụ | Phiên bản khuyến nghị | Ghi chú |
| :--- | :--- | :--- |
| **Flutter SDK** | `>= 3.22.0` (Khuyên dùng 3.44.x) | Kênh `stable` |
| **Dart SDK** | `>= 3.4.0` | Đi kèm với Flutter |
| **Java JDK** | JDK 17 hoặc JDK 21 | Eclipse Adoptium Temurin hoặc OpenJDK |
| **Android Studio** | Hỗ trợ Android SDK 34/35 | Kèm Android SDK Platform-Tools (`adb`) |
| **Xcode** *(dành cho macOS/iOS)* | `>= 15.0` | Kèm CocoaPods `>= 1.14` |
| **VS Code / Android Studio** | Mới nhất | Cài extension Flutter & Dart |

### Kiểm tra môi trường với `flutter doctor`
Mở Terminal / Command Prompt và chạy:
```bash
flutter doctor
```
Đảm bảo các mục sau hiển thị dấu tích xanh:
- `[✓] Flutter (Channel stable, ...)`
- `[✓] Android toolchain - develop for Android devices`
- `[✓] Android Studio` (nếu dùng Android Studio)
- `[✓] Connected device` (nếu đã kết nối điện thoại hoặc mở emulator)

---

## 2. Cài Đặt Dependencies

Di chuyển vào thư mục gốc của dự án `mommy-and-baby-mobile` và tải các packages:

```bash
cd F:\work\mommy-and-baby-mobile
flutter pub get
```

Nếu gặp thông báo về Symlink trên Windows:
```
Building with plugins requires symlink support. Please enable Developer Mode...
```
Bạn chỉ cần mở Windows Settings (`start ms-settings:developers`) và bật **Developer Mode** lên là xong.

---

## 3. Chạy Ứng Dụng Trên Thiết Bị Android

### 3.1. Chạy trên Thiết Bị Thật (Cắm cáp USB) - Khuyên Dùng
1. Trên điện thoại Android, vào **Cài đặt (Settings)** -> **Thông tin điện thoại (About phone)** -> Bấm liên tục 7 lần vào **Số bản dựng (Build number)** để bật tùy chọn nhà phát triển.
2. Vào **Tùy chọn cho nhà phát triển (Developer options)** -> Bật **Gỡ lỗi USB (USB Debugging)**.
3. Cắm cáp USB kết nối điện thoại với máy tính. Trên điện thoại sẽ hiện hộp thoại *"Cho phép gỡ lỗi USB?"*, tick chọn *"Luôn cho phép từ máy tính này"* và bấm **Đồng ý**.
4. Kiểm tra thiết bị đã nhận chưa:
   ```bash
   adb devices
   ```
   Kết quả mẫu:
   ```
   List of devices attached
   12905254AB009007    device
   ```
5. **Chuyển tiếp cổng kết nối mạng (Bắt buộc để gọi backend localhost):**
   ```bash
   adb reverse tcp:8000 tcp:8000
   ```
6. Khởi chạy ứng dụng:
   ```bash
   flutter run
   ```

### 3.2. Chạy trên Android Emulator (Trình Giả Lập)
1. Mở Android Studio -> **Device Manager** -> Khởi động một máy ảo (Ví dụ: Pixel 7 API 34).
2. Kiểm tra danh sách thiết bị:
   ```bash
   flutter devices
   ```
3. Chạy ứng dụng chỉ định device ID:
   ```bash
   flutter run -d emulator-5554
   ```
*(Lưu ý: Trên Android Emulator, địa chỉ trỏ về máy chủ host là `http://10.0.2.2:8000/api` thay vì `127.0.0.1`)*.

---

## 4. Chạy Ứng Dụng Trên iOS (Chỉ dành cho macOS)

1. Cài đặt CocoaPods:
   ```bash
   sudo gem install cocoapods
   ```
2. Cài đặt Pod dependencies:
   ```bash
   cd ios
   pod install
   cd ..
   ```
3. Chạy trên iOS Simulator:
   ```bash
   open -a Simulator
   flutter run -d iPhone
   ```
4. Chạy trên iPhone thật: Mở `ios/Runner.xcworkspace` bằng Xcode, cấu hình **Signing & Capabilities** với Apple Developer Account của bạn, chọn thiết bị và bấm **Run**.

---

## 5. Khởi Động Backend Server Cùng Lúc

Để ứng dụng mobile có dữ liệu thực tế và đăng nhập được, bạn cần chạy backend FastAPI của dự án:

1. Di chuyển vào thư mục backend của dự án `mommy-and-baby`:
   ```bash
   cd F:\work\mommy-and-baby\backend
   ```
2. Kích hoạt môi trường ảo và khởi động server uvicorn:
   ```bash
   .venv\Scripts\python.exe -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 --reload
   ```
3. Kiểm tra backend hoạt động bằng trình duyệt:
   - API Docs: `http://127.0.0.1:8000/docs`
   - Health Check: `http://127.0.0.1:8000/api/health`

---

## 6. Build File Cài Đặt (Release Packaging)

### Build Android APK:
```bash
# Build file APK Universal
flutter build apk --release

# Hoặc build APK tách theo kiến trúc CPU (dung lượng nhẹ hơn đáng kể)
flutter build apk --split-per-abi --release
```
File APK xuất ra tại:
`build/app/outputs/flutter-apk/app-release.apk`

Cài đặt trực tiếp lên điện thoại đang cắm cáp:
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Build Android App Bundle (.aab - Dành cho Google Play):
```bash
flutter build appbundle --release
```
File xuất ra tại:
`build/app/outputs/bundle/release/app-release.aab`

### Build iOS Unsigned IPA (Dành cho Sideload / AltStore / TrollStore):
Tự động đóng gói qua file workflow CI/CD `.github/workflows/build_ios.yml` hoặc `codemagic.yaml`, hoặc chạy lệnh trên macOS:
```bash
flutter build ios --release --no-codesign
mkdir -p Payload
cp -r build/ios/iphoneos/Runner.app Payload/
zip -r -y mommy_baby.ipa Payload
rm -rf Payload
```

---

## 7. Xử Lý Các Sự Cố Thường Gặp (Troubleshooting)

### Lỗi 1: `SocketException: Connection refused` hoặc `Không thể kết nối đến máy chủ`
- **Nguyên nhân:** Điện thoại không thể tìm thấy backend trên cổng 8000.
- **Khắc phục:**
  - Nếu cắm cáp USB: Chạy lại lệnh `adb reverse tcp:8000 tcp:8000`.
  - Nếu dùng Wi-Fi: Đảm bảo máy tính và điện thoại cùng kết nối vào một mạng Wi-Fi, mở app vào **Menu Drawer** -> **Cài đặt máy chủ (Server Settings)** -> Đổi Base URL thành `http://192.168.x.x:8000/api` (với `192.168.x.x` là IP máy tính của bạn).
  - Đảm bảo backend được khởi động với `--host 0.0.0.0` thay vì `127.0.0.1` khi kết nối qua Wi-Fi LAN.

### Lỗi 2: `Cleartext HTTP traffic not permitted` trên Android
- Ứng dụng đã được cấu hình sẵn thuộc tính `android:usesCleartextTraffic="true"` trong `AndroidManifest.xml` (ở cả `debug`, `profile` và `main`) để cho phép kết nối `http://` cục bộ mà không bị hệ điều hành Android chặn.

### Lỗi 3: Lỗi build Gradle liên quan đến Java Version
- Flutter 3.22+ yêu cầu Java 17 trở lên. Đảm bảo biến môi trường `JAVA_HOME` trỏ tới JDK 17 hoặc 21.
