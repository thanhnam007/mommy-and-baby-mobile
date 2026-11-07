# Kết Nối & Tích Hợp Backend Server (FastAPI Integration)

Tài liệu này cung cấp hướng dẫn toàn diện về cơ chế kết nối giữa ứng dụng **Mommy & Baby Flutter Mobile** và hệ thống **Backend FastAPI**, chi tiết các API endpoints, xử lý xác thực Bearer Token, cơ chế đổi Base URL linh hoạt và xử lý lỗi mạng.

---

## 1. Cơ Chế Địa Chỉ Mạng (Network Addressing Schemes)

Ứng dụng Flutter cần kết nối với backend FastAPI (chạy trên cổng `8000`). Tùy theo môi trường chạy của bạn, địa chỉ Base URL sẽ khác nhau:

| Môi Trường Chạy | Base URL Khuyến Nghị | Cách Thiết Lập |
| :--- | :--- | :--- |
| **Thiết Bị Thật (Cắm Cáp USB)** | `http://127.0.0.1:8000/api` | Bắt buộc chạy lệnh: `adb reverse tcp:8000 tcp:8000` |
| **Thiết Bị Thật (Mạng Wi-Fi LAN)** | `http://<IP_MAY_TINH>:8000/api` | Backend cần bind `--host 0.0.0.0`, mở port 8000 tường lửa |
| **Android Emulator (Máy Ảo)** | `http://10.0.2.2:8000/api` | Địa chỉ loopback đặc biệt của Android Emulator |
| **iOS Simulator** | `http://127.0.0.1:8000/api` | Dùng loopback trực tiếp trên macOS |
| **Production Server (VPS / Cloud)** | `https://api.yourdomain.com/api` | Domain HTTPS công khai có chứng chỉ SSL |

---

## 2. Quản Lý Base URL Động Trong Ứng Dụng (`AppConfig`)

Trong mã nguồn (`lib/core/config/app_config.dart`), ứng dụng hỗ trợ lưu trữ Base URL vào `SharedPreferences`:

```dart
class AppConfig {
  static const String keyBaseUrl = 'app_config_base_url';

  static const String defaultBaseUrl = 'http://127.0.0.1:8000/api';
  static const String lanBaseUrl = 'http://192.168.1.132:8000/api';
  static const String emulatorBaseUrl = 'http://10.0.2.2:8000/api';

  static String _currentBaseUrl = defaultBaseUrl;

  static String get baseUrl => _currentBaseUrl;
  
  // Nạp URL đã lưu từ bộ nhớ khi mở app
  static Future<void> init() async { ... }

  // Cập nhật URL mới và lưu vào máy
  static Future<void> setBaseUrl(String url) async { ... }
}
```

### Hộp Thoại Đổi Server Ngay Trong App (`ServerSettingsDialog`)
Người dùng hoặc tester có thể đổi địa chỉ backend bất kỳ lúc nào mà **không cần phải biên dịch lại mã nguồn**:
1. Mở Left Drawer (Menu góc trái màn hình chính) hoặc ở màn hình Đăng nhập.
2. Chọn **"Cài đặt máy chủ" (Server Settings)**.
3. Chọn nhanh một trong các preset có sẵn:
   - `USB ADB Reverse (127.0.0.1:8000)`
   - `Android Emulator (10.0.2.2:8000)`
   - `Mạng LAN Wi-Fi (192.168.x.x:8000)`
   - Hoặc gõ địa chỉ domain tùy chỉnh.
4. Bấm nút **"Kiểm tra kết nối" (Test Connection)**: App sẽ gửi một request `GET /health` đến server để xác nhận backend đang sống và hiển thị thông báo phản hồi màu xanh.
5. Bấm **"Lưu & Áp dụng"**: Toàn bộ các request tiếp theo của `ApiClient` sẽ tự động chuyển hướng sang Base URL mới.

---

## 3. Quản Lý Phiên Đăng Nhập & Xác Thực (`ApiClient` & `AuthProvider`)

### 3.1. Lưu Trữ Token Bảo Mật
Khi người dùng đăng nhập thành công qua `/api/auth/login`:
- Server trả về `access_token` (JWT Token) và thông tin tài khoản.
- Token được mã hóa và lưu vào Keychain (iOS) hoặc Keystore (Android) thông qua thư viện `flutter_secure_storage`.
- Thông tin profile người dùng được cache vào `SharedPreferences` để hiển thị tức thì.

### 3.2. Tự Động Đính Kèm Header Bearer Token
Trong `lib/core/network/api_client.dart`, `Dio` được cấu hình `InterceptorsWrapper`:
```dart
onRequest: (options, handler) async {
  final token = await _getToken();
  if (token != null && token.isNotEmpty) {
    options.headers['Authorization'] = 'Bearer $token';
  }
  return handler.next(options);
}
```

### 3.3. Quy Tắc Bẫy Lỗi 401 (Dio 401 Interceptor Trap on Login)
Một lỗi rất phổ biến khi làm ứng dụng di động là tự động logout / xóa token khi bất kỳ API nào trả về `401 Unauthorized`. Tuy nhiên:
- Khi người dùng đăng nhập sai mật khẩu tại `/api/auth/login`, backend FastAPI cũng trả về HTTP `401 Unauthorized`.
- Nếu interceptor xử lý sơ sài gọi callback `onUnauthorized()`, nó sẽ xóa sạch token và gọi `notifyListeners()`, gây ra xung đột luồng giao diện (rebuild đè màn hình).
- **Giải pháp chuẩn:** Trong `api_client.dart`:
```dart
onError: (DioException error, handler) {
  final path = error.requestOptions.path;
  // Bỏ qua callback logout nếu request xuất phát từ form đăng nhập
  if (error.response?.statusCode == 401 && !path.contains('/auth/login')) {
    onUnauthorized?.call();
  }
  return handler.next(error);
}
```

### 3.4. Trích Xuất Lỗi Chi Tiết Từ Backend FastAPI
FastAPI trả về lỗi xác thực dữ liệu qua trường `detail` trong JSON body:
- Có thể là chuỗi string: `{"detail": "Sai mật khẩu hoặc tài khoản không tồn tại"}`.
- Có thể là mảng Pydantic validation errors: `{"detail": [{"loc": [...], "msg": "Field required"}]}`.
`ApiClient` và `AuthProvider` đã được lập trình để trích xuất sạch sẽ thông điệp tiếng Việt dễ hiểu gửi về UI hiển thị trong khung cảnh báo đỏ (Error Alert Banner).

---

## 4. Danh Sách Chi Tiết Các API Endpoints Ứng Dụng Gọi

### 4.1. Xác Thực & Người Dùng (Authentication)
| Method | Endpoint | Mô Tả Nghiệp Vụ |
| :--- | :--- | :--- |
| `POST` | `/api/auth/register` | Đăng ký tài khoản mẹ bỉm mới |
| `POST` | `/api/auth/login` | Đăng nhập bằng username/password, nhận Bearer JWT |
| `GET` | `/api/auth/me` | Lấy thông tin tài khoản người dùng hiện tại |
| `PUT` | `/api/auth/profile` | Cập nhật tên, biệt danh, kênh nhận tin Telegram/Zalo |

### 4.2. Quản Lý Bé Yêu (Babies)
| Method | Endpoint | Mô Tả Nghiệp Vụ |
| :--- | :--- | :--- |
| `GET` | `/api/babies` | Lấy danh sách toàn bộ các bé thuộc quyền quản lý của mẹ |
| `POST` | `/api/babies` | Tạo hồ sơ bé mới (Tên, ngày sinh, giới tính, cân nặng, chiều cao lúc sinh) |
| `GET` | `/api/babies/{id}` | Lấy chi tiết thông tin và chỉ số của 1 bé |
| `PUT` | `/api/babies/{id}` | Cập nhật thông tin của bé |
| `DELETE` | `/api/babies/{id}` | Xóa hồ sơ bé |

### 4.3. Hoạt Động Sinh Hoạt & Dòng Thời Gian (Activities & Timeline)
| Method | Endpoint | Mô Tả Nghiệp Vụ |
| :--- | :--- | :--- |
| `GET` | `/api/activities/daily-summary` | Lấy tổng quan cữ trong ngày (tổng sữa ml, tổng giờ ngủ, số lần thay tã, trạng thái đang bú/ngủ) |
| `GET` | `/api/activities/timeline` | Lấy danh sách hoạt động theo ngày, hỗ trợ lọc theo loại (`feeding`, `sleeping`, `diaper`, `other`) |
| `POST` | `/api/activities/feeding` | Ghi cữ bú bình (ml), sữa mẹ vắt, hoặc bú mẹ trực tiếp (trái/phải) |
| `POST` | `/api/activities/sleeping` | Bắt đầu bấm giờ ngủ hoặc ghi nhận giấc ngủ đã qua |
| `POST` | `/api/activities/diaper` | Ghi nhận thay tã (tè, ị, cả hai, màu sắc, phân) |
| `POST` | `/api/activities/other` | Ghi nhận hoạt động ăn dặm (solid), tắm bé (bath), tummy time (play) |
| `PUT` | `/api/activities/{id}` | Chỉnh sửa thời gian bắt đầu, kết thúc, số lượng hoặc ghi chú của cữ |
| `DELETE` | `/api/activities/{id}` | Xóa 1 bản ghi hoạt động sinh hoạt |

> **Lưu ý nghiệp vụ cữ đang diễn ra (Ongoing Activity):** Khi ghi cữ ngủ hoặc cữ bú mẹ trực tiếp mà chưa kết thúc, trường `end_time` được gửi lên là `null`. Backend sẽ ghi nhận hoạt động đang diễn ra và cập nhật cờ `is_currently_sleeping = true` / `is_currently_feeding = true` trong daily-summary.

### 4.4. Tăng Trưởng & Chuẩn WHO (Growth Tracker)
| Method | Endpoint | Mô Tả Nghiệp Vụ |
| :--- | :--- | :--- |
| `GET` | `/api/growth/records` | Lấy danh sách lịch sử đo cân nặng & chiều cao của bé |
| `POST` | `/api/growth/records` | Ghi nhận số đo mới (cân nặng kg, chiều cao cm, ngày giờ đo, ghi chú) |
| `PUT` | `/api/growth/records/{id}` | Chỉnh sửa số đo đã nhập |
| `DELETE` | `/api/growth/records/{id}` | Xóa bản ghi số đo |
| `GET` | `/api/growth/chart` | Lấy dữ liệu tọa độ vẽ biểu đồ: số đo thực tế lồng ghép với đường trung vị WHO và dải `-2SD..+2SD` theo tháng tuổi |
| `GET` | `/api/growth/who-standards` | Lấy bảng tra cứu chuẩn WHO lý tưởng cho bé trai/bé gái từ 0 - 60 tháng |

### 4.5. Hút Sữa Mẹ (Pumping Tracker)
| Method | Endpoint | Mô Tả Nghiệp Vụ |
| :--- | :--- | :--- |
| `GET` | `/api/pumping/sessions` | Lấy danh sách các cữ vắt sữa mẹ |
| `POST` | `/api/pumping/sessions` | Ghi nhận cữ hút sữa (ml vú trái, ml vú phải, thời gian, cách bảo quản) |
| `PUT` | `/api/pumping/sessions/{id}` | Chỉnh sửa cữ hút sữa |
| `DELETE` | `/api/pumping/sessions/{id}` | Xóa cữ hút sữa |
| `GET` | `/api/pumping/daily-summary` | Thống kê tổng ml hút được trong ngày hôm nay |
| `GET` | `/api/pumping/chart` | Dữ liệu vẽ biểu đồ cột/đường xu hướng sản lượng sữa mẹ theo ngày |

### 4.6. Giám Sát BabyCam (Imou Camera Stream & PTZ)
| Method | Endpoint | Mô Tả Nghiệp Vụ |
| :--- | :--- | :--- |
| `GET` | `/api/cameras` | Lấy danh sách camera đã kết nối (luồng HLS `.m3u8`, snapshot, trạng thái online) |
| `POST` | `/api/cameras/{id}/ptz` | Điều khiển xoay camera: `direction = "up" \| "down" \| "left" \| "right" \| "stop"` |
| `GET` | `/api/cameras/{id}/snapshot` | Lấy ảnh snapshot trực tiếp từ camera |
| `GET` | `/api/cameras/imou/config` | Lấy cấu hình tài khoản Imou Cloud hiện tại |

### 4.7. Thư Viện Media Kỷ Niệm VIP (Media Gallery)
| Method | Endpoint | Mô Tả Nghiệp Vụ |
| :--- | :--- | :--- |
| `GET` | `/api/media` | Lấy danh sách ảnh/video kỷ niệm của bé theo phân trang |
| `POST` | `/api/media/upload` | Upload ảnh/video mới (Multipart Form Data) |
| `DELETE` | `/api/media/{id}` | Xóa ảnh/video kỷ niệm |

### 4.8. Nhắc Nhở Tự Động (Reminders)
| Method | Endpoint | Mô Tả Nghiệp Vụ |
| :--- | :--- | :--- |
| `GET` | `/api/reminders` | Lấy danh sách lịch nhắc nhở của bé |
| `POST` | `/api/reminders` | Tạo nhắc nhở mới (Tiêu đề, loại, giờ nhắc, chu kỳ lặp) |
| `PATCH` | `/api/reminders/{id}/toggle` | Bật / tắt nhanh một lịch nhắc nhở |
| `DELETE` | `/api/reminders/{id}` | Xóa lịch nhắc nhở |
