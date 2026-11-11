# Kế Hoạch Triển Khai: Phân Tích Tương Quan Sữa Hâm & Cữ Bú Bình

> **Mã kế hoạch:** `PLAN-milk-warming-correlation`  
> **Áp dụng đồng bộ 3 nền tảng:**  
> - **FastAPI Backend:** `F:\work\mommy-and-baby-backend`  
> - **Web Frontend (Vue 3 + Tailwind CSS):** `F:\work\mommy-and-baby-frontend`  
> - **Flutter Mobile App (iOS / Android):** `F:\work\mommy-and-baby-mobile`  
> **Nguyên tắc nghiệp vụ cốt lõi:**  
> 1. Cữ bú bình bằng sữa mẹ vắt ra (`bottle_breast`) được phân định rõ thành 2 loại:  
>    - **Sữa mẹ vắt ra để lạnh và hâm nóng (`is_warmed = true`)**: Sữa mẹ được trữ ngăn mát/ngăn đông rồi đưa vào máy hâm ấm trước khi cho bé bú.  
>    - **Sữa mẹ vắt ra ti bình trực tiếp không hâm (`is_warmed = false`)**: Sữa mẹ mới vắt (nhiệt độ phòng/nhiệt độ cơ thể mẹ) cho bé bú bình ngay mà không qua máy hâm.  
> 2. **Tỉ lệ tương quan** được tính toán chính xác giữa:  
>    - **Tổng lượng sữa hâm trong ngày** ($\sum \text{amount\_ml}$ từ `milk_warming_records` trạng thái `completed`).  
>    - **Tổng lượng sữa bé thực tế đã bú từ cữ sữa hâm** ($\sum \text{amount\_ml}$ từ `activities` loại `bottle_breast` có `is_warmed = true`).  
> 3. Cung cấp chỉ số hao hụt / dư thừa sữa hâm, tỉ lệ hấp thu/tiêu thụ, và lời khuyên giúp bố mẹ cân đối lượng sữa hâm mỗi cữ tránh lãng phí sữa mẹ quý giá.

---

## 1. Phân Tích Yêu Cầu & Mô Hình Nghiệp Vụ (Domain Model)

### 1.1. Phân Loại Cữ Bú Bình Sữa Mẹ
Trong thực tế chăm sóc trẻ sơ sinh, sữa mẹ vắt ra có 2 luồng sử dụng hoàn toàn khác nhau:
1. **Luồng A - Sữa trữ lạnh đem hâm (`is_warmed = true`)**:
   - Mẹ vắt sữa cất tủ lạnh/tủ đông. Đến cữ bú, bố/mẹ lấy ra cho vào máy hâm sữa (`milk_warming_records`).
   - Sữa sau khi hâm có thời hạn dùng tối đa 2 tiếng (quy chuẩn WHO/CDC).
   - Bé có thể bú hết hoặc chỉ bú một phần, phần còn lại bị bỏ đi (hao hụt).
2. **Luồng B - Sữa mới vắt ti bình trực tiếp (`is_warmed = false`)**:
   - Mẹ vừa vắt xong, sữa còn ấm tự nhiên 36.5–37°C hoặc nhiệt độ phòng, đổ vào bình cho bé ti luôn.
   - Không qua máy hâm sữa, do đó **không được tính vào lượng sữa hâm** để tránh làm sai lệch tỉ lệ tương quan hao hụt.

### 1.2. Công Thức & Chỉ Số Tương Quan (Correlation Metrics)
Với ngày khảo sát $D$ (theo múi giờ địa phương của người dùng `tz_offset`, mặc định UTC+7):

| Chỉ số | Ký hiệu | Nguồn dữ liệu | Ý nghĩa |
| :--- | :---: | :--- | :--- |
| **Tổng sữa đã hâm** | $W_{\text{total}}$ | $\sum \text{amount\_ml}$ (`MilkWarmingRecord` status `completed`) | Tổng dung tích sữa đã bỏ vào máy hâm |
| **Số cữ hâm** | $W_{\text{count}}$ | Số bản ghi `MilkWarmingRecord` | Tần suất bật máy hâm trong ngày |
| **Bé bú sữa hâm** | $B_{\text{warmed}}$ | $\sum \text{amount\_ml}$ (`Activity` `bottle_breast` & `is_warmed = true`) | Lượng sữa hâm bé đã thực sự bú vào bụng |
| **Số cữ bú sữa hâm** | $B_{\text{count}}$ | Số bản ghi cữ bú bình sữa hâm | Tần suất bé bú sữa hâm |
| **Sữa mẹ tươi không hâm** | $B_{\text{direct}}$ | $\sum \text{amount\_ml}$ (`Activity` `bottle_breast` & `is_warmed = false`) | Sữa mẹ vắt ti trực tiếp (chỉ số đối chiếu) |
| **Tỉ lệ tiêu thụ / tương quan** | $R_{\text{consumption}}$ | $(B_{\text{warmed}} / W_{\text{total}}) \times 100\%$ | Tỉ lệ % sữa hâm được bé hấp thu |
| **Lượng sữa dư thừa / hao hụt** | $\Delta_{\text{waste}}$ | $W_{\text{total}} - B_{\text{warmed}}$ | Sữa hâm thừa phải đổ bỏ hoặc chưa dùng hết |

#### Đánh giá trạng thái tương quan:
- **Tối ưu ($90\% \le R \le 100\%$)**: Bé bú hết phần lớn lượng sữa hâm, tỉ lệ hao hụt cực thấp ($< 10\%$).
- **Dư thừa nhiều ($R < 75\%$, $\Delta > 50\text{ml}$)**: Bố mẹ hâm lượng sữa lớn hơn sức bú thực tế của bé mỗi cữ, khuyến nghị giảm lượng ml mỗi lần hâm.
- **Cân bằng khá ($75\% \le R < 90\%$)**: Mức chênh lệch bình thường ở trẻ sơ sinh (thường dư 10-30ml đáy bình).
- **Lệch số liệu ($R > 100\%$)**: Bé bú ghi nhận nhiều hơn lượng hâm (gợi ý kiểm tra xem có quên ghi 1 cữ hâm sữa không).
- **Chưa có cữ hâm ($W_{\text{total}} = 0$)**: Chưa phát sinh hoạt động hâm sữa trong ngày.

---

## 2. Kiến Trúc Dữ Liệu & API Backend (FastAPI + SQLAlchemy)

### 2.1. Cập Nhật Database Schema (`app/models.py`)
Thêm trường `is_warmed` vào bảng `activities`:
```python
class Activity(Base):
    __tablename__ = "activities"
    ...
    # Feeding specific fields
    feeding_type = Column(String(30), nullable=True) # breast, bottle_breast, formula, solid
    amount_ml = Column(Integer, nullable=True) # Số ml bú (bú bình hoặc sữa công thức)
    breast_side = Column(String(20), nullable=True) # left, right, both
    nursing_minutes = Column(Integer, nullable=True) # Số phút bú mẹ
    is_warmed = Column(Boolean, default=False, nullable=True) # True: sữa mẹ để lạnh & hâm nóng; False: sữa tươi ti trực tiếp
```

#### Safe SQLite Migration Protocol:
Vì SQLAlchemy `create_all()` không tự bổ sung cột mới vào bảng SQLite đã tồn tại, backend sẽ có hàm kiểm tra an toàn lúc khởi động hoặc migration helper:
```python
def ensure_activity_is_warmed_column(db_engine):
    with db_engine.connect() as conn:
        result = conn.exec_driver_sql("PRAGMA table_info(activities);").fetchall()
        cols = [r[1] for r in result]
        if "is_warmed" not in cols:
            conn.exec_driver_sql("ALTER TABLE activities ADD COLUMN is_warmed BOOLEAN DEFAULT 0;")
            conn.commit()
```

### 2.2. Cập Nhật Pydantic Schemas (`app/schemas.py`)

#### 1. Hoạt động cữ bú:
- `ActivityBase`: `is_warmed: Optional[bool] = False`
- `ActivityCreate`: `is_warmed: Optional[bool] = False`
- `ActivityUpdate`: `is_warmed: Optional[bool] = None`
- `FeedingCreate`: `is_warmed: Optional[bool] = False`
- `FeedingStart`: `is_warmed: Optional[bool] = False`
- `FeedingEnd`: `is_warmed: Optional[bool] = None`

#### 2. Thống kê cữ bú theo ngày (`FeedingSummary`):
Bổ sung các trường phân tách chi tiết:
```python
class FeedingSummary(BaseModel):
    ...
    # Phân tách sữa mẹ bú bình:
    bottle_breast_count: int = 0
    bottle_breast_ml: int = 0
    bottle_breast_warmed_count: int = 0      # Số cữ bú sữa mẹ đã hâm
    bottle_breast_warmed_ml: int = 0         # Tổng ml bú sữa mẹ đã hâm
    bottle_breast_direct_count: int = 0      # Số cữ bú sữa mẹ tươi trực tiếp không hâm
    bottle_breast_direct_ml: int = 0         # Tổng ml bú sữa mẹ tươi trực tiếp không hâm
```

#### 3. Mô hình Tương quan Hâm Sữa (`MilkWarmingCorrelation`):
```python
class MilkWarmingCorrelation(BaseModel):
    date: date
    display_date: str
    warmed_total_ml: int                     # Tổng ml sữa mẹ đã hâm
    warmed_sessions_count: int               # Số cữ hâm
    consumed_warmed_ml: int                  # Bé đã bú từ sữa hâm
    consumed_warmed_count: int               # Số cữ bú sữa hâm
    consumed_direct_ml: int                  # Sữa mẹ tươi không hâm bé bú
    consumed_direct_count: int               # Số cữ bú không hâm
    difference_ml: int                       # warmed_total_ml - consumed_warmed_ml (dư/hao hụt)
    consumption_ratio_percent: Optional[float] = None # (consumed_warmed_ml / warmed_total_ml) * 100
    status: str                              # 'optimal' | 'waste' | 'deficit' | 'balanced' | 'no_data'
    message: str                             # Đánh giá & lời khuyên trực quan
```

Cập nhật `MilkWarmingDayGroup` & `MilkWarmingOverviewResponse`:
```python
class MilkWarmingDayGroup(BaseModel):
    date_str: str
    display_date: str
    total_amount_ml: int
    sessions_count: int
    records: List[MilkWarmingOut]
    correlation: Optional[MilkWarmingCorrelation] = None # Tương quan chi tiết của từng ngày trong lịch sử

class MilkWarmingOverviewResponse(BaseModel):
    status: MilkWarmingStatusOut
    today_total_ml: int
    today_sessions_count: int
    today_correlation: Optional[MilkWarmingCorrelation] = None # Tương quan hôm nay
    groups: List[MilkWarmingDayGroup]
```

### 2.3. Cập Nhật Router Logic Backend
- `app/routers/activities.py`:
  - Trong `create_feeding`, `start_feeding`, `end_feeding`, `update_activity`: Lưu nhận diện `is_warmed`.
  - Trong `get_feeding_daily_summary`: Tính toán và cộng dồn `bottle_breast_warmed_count`, `bottle_breast_warmed_ml`, `bottle_breast_direct_count`, `bottle_breast_direct_ml`.
- `app/routers/milk_warming.py`:
  - Hàm `calculate_daily_correlation(user_id, baby_id, target_date, tz_offset, db)`: Truy vấn song song bảng `milk_warming_records` và `activities` trong cùng khoảng thời gian ngày địa phương, tính toán tỉ lệ $R$ và dung lượng chênh lệch $\Delta$.
  - Gắn `today_correlation` vào `get_warming_overview` và gắn `correlation` vào từng `MilkWarmingDayGroup`.
- `app/admin/views.py`:
  - Trong `ActivityAdmin`: Thêm cột `is_warmed` vào `column_list`, `column_labels`, bộ lọc và form sửa.

---

## 3. Thiết Kế Giao Diện Người Dùng Web Frontend (Vue 3 + Tailwind CSS)

### 3.1. Hộp Thoại Ghi Cữ Bú Nhanh (`QuickLogModal.vue`)
Khi người dùng chọn tab **Cữ bú** và bấm chọn loại sữa **Sữa mẹ (bình)** (`bottle_breast`):
- Hiển thị ngay một Card tùy chọn trực quan bên dưới lựa chọn số ml:
  + **Nút Checkbox/Toggle**: `♨️ Sữa mẹ đã hâm (để lạnh / đông đem hâm)`
  + **Trạng thái bật (`true`)**: "Cữ này dùng sữa mẹ đã trữ lạnh/đông đem hâm nóng (được tính vào tỉ lệ tương quan tiêu thụ)".
  + **Trạng thái tắt (`false`)**: "Sữa mẹ mới vắt ra cho bé ti bình trực tiếp ở nhiệt độ phòng/cơ thể (không qua hâm nóng)".
  + **Mặc định**: `true` (tiện lợi vì hầu hết các mẹ dùng bình thường là sữa trữ cữ trước).

### 3.2. Hộp Thoại Chi Tiết & Chỉnh Sửa Cữ Bú (`ActivityDetailModal.vue`)
1. **Chế độ xem chi tiết**:
   - Khi cữ bú là `bottle_breast`:
     + Hiển thị nhãn huy hiệu:
       * Nếu `is_warmed = true`: Huy hiệu màu hổ phách `♨️ Sữa mẹ đã hâm`.
       * Nếu `is_warmed = false`: Huy hiệu màu xanh da trời `🍼 Sữa mẹ tươi (ti trực tiếp không hâm)`.
2. **Chế độ chỉnh sửa (Edit mode)**:
   - Cho phép người dùng bật/tắt checkbox `Sữa mẹ đã hâm nóng` và lưu lại thông qua API `PUT /api/activities/{id}`.

### 3.3. Dòng Thời Gian Sinh Hoạt (`ActivityTimelineRow.vue` & `activityCategories.js`)
- Cữ bú bình sữa mẹ trong Timeline hiển thị tag nổi bật:
  + `♨️ Sữa mẹ (đã hâm)` hoặc `🧴 Sữa mẹ tươi (không hâm)`.
  + Giúp phụ huynh nhìn vào dòng thời gian biết ngay cữ nào dùng sữa đông hâm lại, cữ nào là sữa mới vắt.

### 3.4. Màn Hình Lịch Hâm Sữa (`MilkWarmingView.vue`)
Bổ sung một Card Phân tích tương quan chuyên biệt **"Tương quan Hâm & Bú hôm nay"**:
1. **Header**: Biểu tượng ⚖️ Tương quan Hâm & Bú hôm nay, kèm nhãn đánh giá (Tối ưu / Dư thừa / Cân đối).
2. **Thước đo 2 cột so sánh**:
   - Cột 1 (Màu hổ phách - Cam): **Đã hâm**: `X ml` (`N` cữ).
   - Cột 2 (Màu hồng - Đỏ hoa hồng): **Bé đã bú (sữa hâm)**: `Y ml` (`M` cữ).
3. **Thanh tỉ lệ phần trăm trực quan (Progress Bar)**:
   - Hiển thị tỉ lệ % sữa hâm bé đã bú được (VD: `88.5%`).
   - Màu sắc theo mức độ: Xanh ngọc ($\ge 85\%$), Vàng cam ($60-84\%$), Đỏ ($< 60\%$ hoặc $> 100\%$).
4. **Chỉ số chênh lệch hao hụt**:
   - Hiển thị rõ: `Hao hụt/Dư thừa: Z ml` (sữa hâm nhưng bé không bú hết hoặc quá 2h phải bỏ).
5. **Chỉ số phụ đối chiếu**:
   - `Sữa mẹ tươi ti bình trực tiếp: K ml (P cữ)` (được tách riêng, không làm nhiễu tỉ lệ hâm).
6. **Trong từng ngày lịch sử (`MilkWarmingDayGroup`)**:
   - Thêm một badge nhỏ cạnh tổng ml: `🍼 Bú: 450/500ml (90%) • Dư: 50ml`.

### 3.5. Bảng Điều Khiển Trang Chủ (`DashboardView.vue` & `DesktopDashboardView.vue`)
1. **Khối Thống kê cữ bú hôm nay**:
   Trong mục Bú bình, phân tách rõ ràng:
   - 🥛 Sữa công thức: `X cữ • Y ml`
   - ♨️ Sữa mẹ (đã hâm): `A cữ • B ml`
   - 🧴 Sữa mẹ tươi ti trực tiếp: `C cữ • D ml`
2. **Card Lịch hâm sữa nhanh (`MilkWarmingCard.vue`)**:
   Hiển thị thêm dòng tóm tắt:
   `Tương quan hôm nay: Đã bú A / W ml (R%)`.

---

## 4. Thiết Kế Ứng Dụng Di Động Flutter (`F:\work\mommy-and-baby-mobile`)

Để đồng bộ 100% trải nghiệm và dữ liệu giữa Web và App điện thoại, toàn bộ các luồng thao tác trên Flutter sẽ được nâng cấp tương ứng:

### 4.1. Nâng Cấp Data Models (`lib/models/`)
1. **`lib/models/activity_model.dart`**:
   - `ActivityModel`:
     + Bổ sung trường `final bool isWarmed;` (default `false`).
     + `fromJson`: `isWarmed: json['is_warmed'] == true || json['is_warmed'] == 1,`
     + `title`: Hiển thị rõ `Bú bình sữa hâm (X ml)` hoặc `Bú bình sữa tươi (X ml)`.
   - `FeedingSummaryModel`:
     + Bổ sung các trường thống kê:
       ```dart
       final int bottleBreastWarmedCount;
       final int bottleBreastWarmedMl;
       final int bottleBreastDirectCount;
       final int bottleBreastDirectMl;
       ```
2. **`lib/models/milk_warming_model.dart`**:
   - Thêm `MilkWarmingCorrelationModel`:
     ```dart
     class MilkWarmingCorrelationModel {
       final String date;
       final String displayDate;
       final int warmedTotalMl;
       final int warmedSessionsCount;
       final int consumedWarmedMl;
       final int consumedWarmedCount;
       final int consumedDirectMl;
       final int consumedDirectCount;
       final int differenceMl;
       final double? consumptionRatioPercent;
       final String status;
       final String message;
       ...
     ```
   - Cập nhật `MilkWarmingDayGroupModel`: Bổ sung `final MilkWarmingCorrelationModel? correlation;`
   - Cập nhật `MilkWarmingOverviewModel`: Bổ sung `final MilkWarmingCorrelationModel? todayCorrelation;`

### 4.2. Nâng Cấp Provider & API Client (`lib/providers/` & `lib/core/network/`)
- `lib/providers/activity_provider.dart`:
  + Cập nhật phương thức `logBottleFeeding`:
    ```dart
    Future<bool> logBottleFeeding(
      int babyId,
      int amountMl, {
      String feedingType = 'formula',
      bool isWarmed = false,
      DateTime? time,
      String? notes,
    }) async
    ```
  + Gửi trường `is_warmed: isWarmed` lên backend trong payload JSON.
- `lib/providers/milk_warming_provider.dart`: Nạp và quản lý state `todayCorrelation`.

### 4.3. Nâng Cấp Giao Diện Di Động Flutter (`lib/views/`)
1. **Hộp Thoại Ghi Cữ Bú Nhanh (`lib/views/quick_log/quick_log_sheet.dart`)**:
   - Trong phân mục Ghi cữ bú bình:
     + Thêm hàng chọn Loại sữa bình: `🥛 Sữa công thức` vs `🧴 Sữa mẹ vắt ra`.
     + Khi chọn `🧴 Sữa mẹ vắt ra`: Xuất hiện checkbox Switch / Checkbox ListTile `♨️ Sữa mẹ đã hâm (để lạnh / đông đem hâm)` (mặc định `true`).
     + Hiển thị sub-caption giải thích để người dùng dễ chọn (Sữa mẹ để lạnh hâm nóng vs Sữa mới vắt ti trực tiếp).
2. **Chi Tiết Cữ Bú (`lib/views/timeline/activity_detail_sheet.dart`)**:
   - Hiển thị huy hiệu cữ bú:
     + Sữa mẹ đã hâm: `♨️ Sữa mẹ đã hâm nóng` (Container viền màu cam/hổ phách).
     + Sữa mẹ không hâm: `🍼 Sữa mẹ tươi (ti trực tiếp không hâm)` (Container viền màu xanh dương).
   - Form Edit: Cho phép chuyển đổi cờ `is_warmed` và lưu lại qua API.
3. **Thẻ Timeline Row (`lib/views/timeline/widgets/activity_timeline_row.dart`)**:
   - Trong `_getContextTags`: Thêm tag `♨️ Sữa mẹ đã hâm` hoặc `🧴 Sữa mẹ tươi (không hâm)`.
4. **Màn Hình Lịch Hâm Sữa Flutter (`lib/views/milk_warming/milk_warming_view.dart`)**:
   - Bổ sung Card Widget **Tương Quan Hâm & Bú Hôm Nay**:
     + Hiển thị 2 cột số đo: `Đã hâm X ml` vs `Bé bú Y ml`.
     + Thanh LinearProgressIndicator màu sinh động theo tỉ lệ phần trăm tiêu thụ.
     + Thông báo hao hụt / dư thừa sữa hâm ($\Delta$ ml).
     + Hiển thị số đo cữ sữa tươi không hâm (tham chiếu).
   - Trong từng nhóm ngày `MilkWarmingDayGroup`: hiển thị chip tương quan `Bé bú: A/B ml (R%)`.
5. **Dashboard Flutter (`lib/views/dashboard/widgets/milk_warming_dashboard_card.dart` & `dashboard_view.dart`)**:
   - Card Hâm sữa nhanh ở Dashboard bổ sung dòng tóm tắt: `Hôm nay: Bé đã bú A / W ml sữa hâm (R%)`.
   - Khối thống kê cữ bú hôm nay: Tách chi tiết số cữ và dung tích sữa mẹ đã hâm vs sữa tươi không hâm.

---

## 5. Kế Hoạch Kiểm Thử & Xác Minh (Testing & Verification)

### 5.1. Backend Unit & Integration Tests (`tests/test_milk_warming_correlation.py`)
1. **Test 1 - Phân tách cữ bú bình**:
   - Tạo 1 cữ `bottle_breast` có `is_warmed = True` (120ml).
   - Tạo 1 cữ `bottle_breast` có `is_warmed = False` (80ml).
   - Tạo 1 cữ `formula` (90ml).
   - Gọi `GET /api/activities/feeding/daily-summary`, xác nhận:
     + `bottle_breast_warmed_ml == 120` (1 cữ).
     + `bottle_breast_direct_ml == 80` (1 cữ).
     + `formula_ml == 90` (1 cữ).
     + `bottle_total_ml == 290` (3 cữ).
2. **Test 2 - Tương quan hâm sữa & bú bình**:
   - Ghi nhận 2 cữ hâm sữa: 150ml và 100ml -> Tổng hâm = 250ml.
   - Bé bú 1 cữ sữa hâm 120ml và 1 cữ sữa hâm 90ml -> Tổng bú sữa hâm = 210ml.
   - Bé bú thêm 1 cữ sữa tươi không hâm 80ml.
   - Gọi `GET /api/milk-warming`, kiểm tra `today_correlation`:
     + `warmed_total_ml == 250`
     + `consumed_warmed_ml == 210`
     + `consumed_direct_ml == 80`
     + `difference_ml == 40` (dư 40ml)
     + `consumption_ratio_percent == 84.0%`
3. **Test 3 - Edge Cases**:
   - Trường hợp chưa có cữ hâm nào trong ngày ($W_{\text{total}} = 0$): tỉ lệ trả về `None` hoặc `status == 'no_data'`, không bị lỗi chia cho 0 (`ZeroDivisionError`).
   - Trường hợp bé bú nhiều hơn lượng hâm ($B_{\text{warmed}} > W_{\text{total}}$): trạng thái `status == 'deficit'`, thông điệp nhắc nhở kiểm tra cữ ghi sót.
4. **Test 4 - Chạy toàn bộ Test Suites**:
   - `uv run pytest` phải vượt qua 100% tất cả các test cases hiện có và mới.

### 5.2. Web Frontend Build & UI Verification
- Chạy `npm test` (`vite build`) để xác nhận không có lỗi cú pháp, types, hoặc biến chưa định nghĩa.
- Kiểm tra hiển thị responsive trên màn hình mobile 390x844 (iPhone 12/13/14 Pro) và desktop:
  + Nút check `is_warmed` trong `QuickLogModal` rõ ràng, dễ bấm bằng 1 ngón tay.
  + Card Tương quan trong `MilkWarmingView` co giãn tự nhiên, không tràn khung.
  + Màu sắc hài hòa giữa Dark mode và Light mode.

### 5.3. Flutter Mobile Verification
- Chạy `flutter analyze` hoặc chạy `flutter test` trong `F:\work\mommy-and-baby-mobile` để kiểm tra phân tích tĩnh và bảo đảm không có lỗi linter/cú pháp nào.

---

## 6. Danh Sách Tệp Thay Đổi Dự Kiến

### 1. Backend (`F:\work\mommy-and-baby-backend`):
1. `app/models.py`: Thêm cột `is_warmed` vào bảng `activities`.
2. `app/database.py`: Đảm bảo cột `is_warmed` được tạo tự động nếu dùng database SQLite hiện hành.
3. `app/schemas.py`: Bổ sung `is_warmed` vào các request/response schemas cữ bú; bổ sung schema `MilkWarmingCorrelation` và cập nhật `FeedingSummary`, `MilkWarmingDayGroup`, `MilkWarmingOverviewResponse`.
4. `app/routers/activities.py`: Nhận và lưu `is_warmed`; cập nhật tính toán phân tách trong `FeedingSummary`.
5. `app/routers/milk_warming.py`: Bổ sung tính toán tương quan cữ hâm & bú bình cho hôm nay và các ngày trong lịch sử.
6. `app/admin/views.py`: Thêm hiển thị `is_warmed` trong quản trị admin cữ sinh hoạt.
7. `tests/test_milk_warming_correlation.py`: Bộ kiểm thử tự động toàn diện.

### 2. Web Frontend (`F:\work\mommy-and-baby-frontend`):
1. `src/api/client.js`: Cập nhật interface `logFeeding`, `updateActivity` hỗ trợ `is_warmed`.
2. `src/components/QuickLogModal.vue`: Thêm checkbox/switch chọn loại sữa mẹ đã hâm nóng khi chọn `bottle_breast`.
3. `src/components/ActivityDetailModal.vue`: Hiển thị badge cữ bú sữa hâm/tươi và form sửa `is_warmed`.
4. `src/utils/activityCategories.js`: Thêm tag phân biệt trực quan cữ bú sữa mẹ đã hâm vs sữa tươi.
5. `src/views/MilkWarmingView.vue`: Thêm Card Phân tích Tương quan Hâm & Bú hôm nay và badge tương quan từng ngày.
6. `src/components/MilkWarmingCard.vue`: Hiển thị tóm tắt tương quan nhanh.
7. `src/views/DashboardView.vue` & `src/components/desktop/DesktopDashboardView.vue`: Phân tách thống kê sữa mẹ đã hâm vs sữa tươi ti trực tiếp.

### 3. Flutter Mobile (`F:\work\mommy-and-baby-mobile`):
1. `lib/models/activity_model.dart`: Thêm `isWarmed` vào `ActivityModel` và 4 trường phân tách vào `FeedingSummaryModel`.
2. `lib/models/milk_warming_model.dart`: Thêm model `MilkWarmingCorrelationModel`, gắn vào `MilkWarmingOverviewModel` và `MilkWarmingDayGroupModel`.
3. `lib/providers/activity_provider.dart`: Cập nhật `logBottleFeeding` và các mutation method gửi `is_warmed`.
4. `lib/views/quick_log/quick_log_sheet.dart`: Thêm lựa chọn sữa công thức vs sữa mẹ vắt ra, kèm switch `is_warmed` cho cữ bú bình.
5. `lib/views/timeline/activity_detail_sheet.dart`: Hiển thị badge cữ sữa hâm vs tươi, hỗ trợ chỉnh sửa `is_warmed`.
6. `lib/views/timeline/widgets/activity_timeline_row.dart`: Bổ sung tag ngữ cảnh `♨️ Sữa mẹ (đã hâm)` / `🧴 Sữa mẹ (không hâm)`.
7. `lib/views/milk_warming/milk_warming_view.dart`: Bổ sung Card Tương Quan Hâm & Bú hôm nay và badge tương quan cho từng ngày.
8. `lib/views/dashboard/widgets/milk_warming_dashboard_card.dart` & `dashboard_view.dart`: Cập nhật hiển thị tóm tắt tương quan và phân tách số liệu cữ bú.

---

## 7. Kế Hoạch Triển Khai Theo Từng Bước (Step-by-Step Execution Plan)

- [ ] **Bước 1 (Backend Core & Model)**: Cập nhật `app/models.py`, `app/database.py`, thêm hàm migrate an toàn cho SQLite `is_warmed`.
- [ ] **Bước 2 (Backend Schemas & Router)**: Cập nhật `app/schemas.py`, `app/routers/activities.py` (tách stats sữa hâm vs tươi) và `app/routers/milk_warming.py` (tính toán tương quan).
- [ ] **Bước 3 (Backend Test Suites)**: Viết `tests/test_milk_warming_correlation.py` và chạy `uv run pytest` đảm bảo pass 100%.
- [ ] **Bước 4 (Web Frontend)**:
  - Cập nhật `src/components/QuickLogModal.vue`, `src/components/ActivityDetailModal.vue`, `src/utils/activityCategories.js`.
  - Thiết kế Card Tương quan tại `MilkWarmingView.vue`, cập nhật `MilkWarmingCard.vue`, `DashboardView.vue` và `DesktopDashboardView.vue`.
  - Chạy `npm test` (`vite build`) kiểm tra bundle.
- [ ] **Bước 5 (Flutter Mobile)**:
  - Cập nhật `lib/models/activity_model.dart`, `lib/models/milk_warming_model.dart`, `lib/providers/activity_provider.dart`.
  - Nâng cấp `quick_log_sheet.dart`, `activity_detail_sheet.dart`, `activity_timeline_row.dart`, `milk_warming_view.dart`, `milk_warming_dashboard_card.dart`.
  - Chạy kiểm tra phân tích tĩnh Flutter (`flutter analyze` hoặc test).
- [ ] **Bước 6 (Tài liệu & Xác nhận)**: Báo cáo kết quả kiểm thử trên cả 3 nền tảng sẵn sàng để người dùng duyệt.
