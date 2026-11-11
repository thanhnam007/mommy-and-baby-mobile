# Kế Hoạch Triển Khai: Tính Năng Lịch Hâm Sữa (Milk Warming Tracker)

> **Mã kế hoạch:** `PLAN-milk-warming-tracker`  
> **Áp dụng đồng bộ:**  
> - **FastAPI Backend:** `F:\work\mommy-and-baby-backend`  
> - **Web Frontend (Vue 3 + Tailwind CSS):** `F:\work\mommy-and-baby-frontend`  
> - **Flutter Mobile App:** `F:\work\mommy-and-baby-mobile`  
> **Nguyên tắc kiến trúc cốt lõi:**  
> Lịch hâm sữa là một **module hoàn toàn tách biệt với Lịch sinh hoạt của em bé (`activities`)**. Dữ liệu hâm sữa được lưu trữ ở bảng riêng, API riêng, màn hình riêng, tuyệt đối không trộn lẫn vào Timeline hay thống kê cữ bú/ngủ/vệ sinh của bé.

---

## 1. Phân Tích Yêu Cầu & Quy Tắc Nghiệp Vụ (Domain & UX Rules)

### 1.1. Các Thông Số Của Mỗi Lần Hâm Sữa
Mỗi bản ghi lịch hâm sữa bao gồm đầy đủ 3 thông số chính (kèm thời lượng tự động tính):
1. **Thời gian bắt đầu hâm (`start_time`)**: Mốc thời gian bắt đầu đưa bình sữa vào máy hâm.
2. **Thời gian kết thúc hâm (`end_time`)**: Mốc thời gian lấy bình sữa ra khỏi máy (bằng `null` khi đang trong quá trình hâm).
3. **Số mililit sữa (`amount_ml`)**: Dung tích bình sữa được hâm (ml).
4. **Thời lượng hâm (`duration_seconds` / `duration_minutes`)**: Tự động tính từ `end_time - start_time`.

### 1.2. Luồng Thao Tác Siêu Nhanh ("Ghi nhanh lịch hâm" & "Kết thúc hâm")
Thiết kế tối giản cho mẹ/bố đang bận bế bé:
1. **Nút `"Ghi nhanh lịch hâm"`**:
   - Khi người dùng bấm nút **"Ghi nhanh lịch hâm"**:
     - Tự động lấy **`start_time` = thời điểm hiện tại**.
     - Chỉ hiển thị một hộp thoại nhỏ gọn **duy nhất hỏi số mililit sữa** (kèm các nút chọn nhanh 1 chạm: `60ml`, `90ml`, `120ml`, `150ml`, `180ml`, `210ml`, `240ml` hoặc ô nhập số trực tiếp).
     - Ngay sau khi xác nhận số ml -> Hệ thống tạo ngay bản ghi với trạng thái **`warming` (Đang hâm)** và `end_time = null`.
2. **Nút `"Kết thúc hâm"`**:
   - Trong lúc đang hâm (`status = warming`), thẻ lịch hâm hiển thị đồng hồ đếm thời gian đang hâm real-time từng giây cùng nút **"Kết thúc hâm"** nổi bật.
   - Khi bấm **"Kết thúc hâm"**:
     - Hệ thống tự động cập nhật **`end_time` = thời điểm hiện tại**, tự tính thời lượng hâm và chuyển trạng thái sang **`completed`**.
     - Đồng hồ bắt đầu đếm quãng thời gian kể từ lần hâm gần nhất (`end_time` vừa chốt).
3. **Ghi/Sửa thủ công (Manual Log & Edit)**:
   - Ngoài luồng "Ghi nhanh", người dùng vẫn có thể thêm hoặc sửa lại lịch hâm đã qua (chọn đầy đủ `start_time`, `end_time`, `amount_ml`, `notes`) trong trang chi tiết Lịch hâm sữa.

### 1.3. Quãng Thời Gian Với Lần Hâm Gần Nhất & Quy Tắc 2 Giờ
- **Mốc tính quãng thời gian**: Tính từ `end_time` (thời điểm kết thúc hâm) của lần hâm hoàn thành gần nhất đến thời điểm hiện tại (`now`).
- **Quy tắc cảnh báo 2 giờ (7.200 giây / 120 phút)**:
  - **Nếu quãng thời gian `<= 2 giờ` (`<= 7200 giây`)**:
    - Hiển thị thời gian trôi qua kể từ lần hâm gần nhất (cập nhật **real-time từng giây**, không cần refresh trang), ví dụ: `Hâm gần nhất: 35 phút 20 giây trước (120ml)`.
    - Có thể kèm thông tin thời gian an toàn còn lại (ví dụ: `Còn dùng được trong 1 giờ 24 phút 40 giây`).
  - **Nếu quãng thời gian `> 2 giờ` (`> 7200 giây`)**:
    - Hiển thị thông báo cảnh báo nổi bật: **"Cần hâm sữa mới"** (kèm quãng thời gian đã trôi qua, ví dụ: `Lần hâm gần nhất: 2 giờ 15 phút trước (120ml)`).
- **Trường hợp đang hâm (`status = warming`)**:
  - Hiển thị thời gian đã bắt đầu hâm (vd: `Đang hâm 120ml • 04 phút 12 giây`) kèm nút **"Kết thúc hâm"**.

### 1.4. Tách Biệt Hoàn Toàn Với Lịch Sinh Hoạt Của Bé (`activities`)
- **Không** ghi vào bảng `activities`, **không** dùng `ActivityType`.
- **Không** hiển thị vào Timeline sinh hoạt của bé (`TimelineView` / `timeline_view.dart`).
- **Không** cộng gộp số ml sữa hâm vào tổng ml sữa bé bú trong `FeedingSummary` (vì lượng sữa hâm là lượng sữa chuẩn bị, tách biệt với lượng sữa thực tế bé bú).
- Có bảng DB riêng (`milk_warming_records`), API router riêng (`/api/milk-warming`), Pinia store / Flutter Provider riêng, và mục menu điều hướng riêng trong Left Sidebar / Drawer.

---

## 2. Thiết Kế Giao Diện Trực Quan (Web & Flutter Mobile)

Tuân thủ chuẩn UI của hệ thống:
- Hỗ trợ Dark/Light theme, mobile viewport chuẩn **390×844**, padding bottom `pb-32`.
- **Auto 1s real-time ticker có giây**, không để người dùng phải refresh trang.

### 2.1. Thẻ Lịch Hâm Sữa Trên Dashboard (Hoặc Đầu Trang Lịch Hâm)

#### Trạng thái A: Quá 2 giờ kể từ lần hâm gần nhất (`> 2h`)
```
┌────────────────────────────────────────────────────────────────────────┐
│ 🍼 LỊCH HÂM SỮA                                    [🔴 Cần hâm sữa mới]│
│ ────────────────────────────────────────────────────────────────────── │
│   Lần hâm gần nhất: 120 ml • Kết thúc lúc 08:00                        │
│   Quãng thời gian:  ⏱️ 2 giờ 18 phút 45 giây trước (đã quá 2 giờ)      │
│   Trạng thái:       ⚠️ Cần hâm sữa mới                                 │
│ ────────────────────────────────────────────────────────────────────── │
│ [ ⚡ Ghi nhanh lịch hâm ]                             [ 🕒 Lịch sử hâm ]│
└────────────────────────────────────────────────────────────────────────┘
```

#### Trạng thái B: Trong vòng 2 giờ kể từ lần hâm gần nhất (`<= 2h`)
```
┌────────────────────────────────────────────────────────────────────────┐
│ 🍼 LỊCH HÂM SỮA                                   [🟢 Sữa còn dùng được]│
│ ────────────────────────────────────────────────────────────────────── │
│   Lần hâm gần nhất: 120 ml • 10:12 → 10:17 (5 phút)                    │
│   Quãng thời gian:  ⏱️ 35 phút 20 giây trước                           │
│   Thời gian còn lại: Còn 1 giờ 24 phút 40 giây                         │
│ ────────────────────────────────────────────────────────────────────── │
│ [ ⚡ Ghi nhanh lịch hâm ]                             [ 🕒 Lịch sử hâm ]│
└────────────────────────────────────────────────────────────────────────┘
```

#### Trạng thái C: Đang trong quá trình hâm (`warming`)
```
┌────────────────────────────────────────────────────────────────────────┐
│ 🔥 ĐANG HÂM SỮA                                          [🟠 Đang hâm] │
│ ────────────────────────────────────────────────────────────────────── │
│   Dung tích:        120 ml                                             │
│   Bắt đầu lúc:      11:30:15                                           │
│   Thời gian hâm:    ⏱️ 04 phút 38 giây (đang đếm real-time)            │
│ ────────────────────────────────────────────────────────────────────── │
│ [ ✅ Kết thúc hâm ]                                    [ ❌ Hủy ]       │
└────────────────────────────────────────────────────────────────────────┘
```

#### Trạng thái D: Chưa có lần hâm nào
```
┌────────────────────────────────────────────────────────────────────────┐
│ 🍼 LỊCH HÂM SỮA                                       [⚪ Chưa có dữ liệu]│
│ ────────────────────────────────────────────────────────────────────── │
│   Chưa có lần hâm sữa nào được ghi nhận.                               │
│ ────────────────────────────────────────────────────────────────────── │
│ [ ⚡ Ghi nhanh lịch hâm ]                             [ 🕒 Lịch sử hâm ]│
└────────────────────────────────────────────────────────────────────────┘
```

### 2.2. Popup/Sheet "Ghi nhanh lịch hâm" (Siêu tối giản)
Khi bấm **"Ghi nhanh lịch hâm"**:
- Tiêu đề: `Ghi nhanh lịch hâm`
- Ghi chú nhỏ: `Thời gian bắt đầu: Ngay bây giờ (tự động)`
- Câu hỏi duy nhất: **Số mililit sữa (ml)?**
  - Các nút chọn nhanh (pill chips): `[60ml]` `[90ml]` `[120ml]` `[150ml]` `[180ml]` `[210ml]` `[240ml]`
  - Ô nhập số ml tùy chỉnh (mặc định focus, gợi ý giá trị lần hâm gần nhất nếu có).
- Nút xác nhận: `🔥 Bắt đầu hâm ngay` (1 chạm để tạo record và chạy đồng hồ).

### 2.3. Trang Quản Lý Lịch Hâm Sữa (`/milk-warming` trên Web & Drawer trên Mobile)
- Nút trên header: **`⚡ Ghi nhanh lịch hâm`** và **`➕ Nhập thủ công`**.
- Thống kê ngày hôm nay: Số lần hâm hôm nay, Tổng ml sữa đã hâm.
- Danh sách các lần hâm gom nhóm theo ngày (`Hôm nay`, `Hôm qua`, `Thứ X, dd/mm/yyyy`):
  - Hiển thị mỗi dòng: `Thời gian bắt đầu → Thời gian kết thúc`, `Thời lượng hâm`, `Số ml sữa`, `Ghi chú`.
  - Hỗ trợ nút Sửa (`start_time`, `end_time`, `amount_ml`, `notes`) và Xóa.

---

## 3. Thiết Kế Cơ Sở Dữ Liệu & API Backend (`mommy-and-baby-backend`)

### 3.1. Model `MilkWarmingRecord` (`app/models.py`)
Bảng riêng `milk_warming_records` — hoàn toàn độc lập với bảng `activities`:

```python
class MilkWarmingRecord(Base):
    """Bản ghi lịch hâm sữa (tách biệt hoàn toàn với lịch sinh hoạt của bé)"""
    __tablename__ = "milk_warming_records"
    __table_args__ = (
        Index("ix_milk_warming_user_start", "user_id", "start_time"),
        Index("ix_milk_warming_user_end", "user_id", "end_time"),
    )

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    baby_id = Column(Integer, ForeignKey("babies.id", ondelete="SET NULL"), nullable=True, index=True)

    start_time = Column(UTCDateTime, nullable=False, index=True)  # Thời gian bắt đầu hâm
    end_time = Column(UTCDateTime, nullable=True, index=True)      # Thời gian kết thúc hâm (null nếu đang hâm)
    amount_ml = Column(Integer, nullable=False)                    # Số mililit sữa
    duration_seconds = Column(Integer, nullable=True, default=0)   # Thời lượng hâm (giây)

    status = Column(String(20), default="completed", nullable=False) # 'warming' | 'completed' | 'cancelled'
    notes = Column(Text, nullable=True)

    created_at = Column(UTCDateTime, default=utc_now)
    updated_at = Column(UTCDateTime, default=utc_now, onupdate=utc_now)

    user = relationship("User", back_populates="milk_warming_records")
    baby = relationship("Baby", back_populates="milk_warming_records")

    def __str__(self) -> str:
        return f"MilkWarming #{self.id} ({self.amount_ml}ml - {self.status})"
```

*(Ghi chú: `baby_id` là nullable giống `PumpingRecord` để theo dõi theo tài khoản gia đình/mẹ mà không ràng buộc hay lẫn vào bảng `activities` của bé. Vẫn hỗ trợ lọc theo `baby_id` nếu người dùng có nhiều bé).*

### 3.2. Pydantic Schemas (`app/schemas.py`)

```python
class MilkWarmingQuickStart(BaseModel):
    baby_id: Optional[int] = None
    amount_ml: int = Field(..., ge=1, le=2000, description="Số mililit sữa hâm")
    start_time: Optional[datetime] = None # Mặc định server lấy utc_now()
    notes: Optional[str] = None

class MilkWarmingEnd(BaseModel):
    end_time: Optional[datetime] = None   # Mặc định server lấy utc_now()
    amount_ml: Optional[int] = Field(None, ge=1, le=2000)
    notes: Optional[str] = None

class MilkWarmingManualCreate(BaseModel):
    baby_id: Optional[int] = None
    start_time: datetime
    end_time: datetime
    amount_ml: int = Field(..., ge=1, le=2000)
    notes: Optional[str] = None

class MilkWarmingUpdate(BaseModel):
    baby_id: Optional[int] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    amount_ml: Optional[int] = Field(None, ge=1, le=2000)
    notes: Optional[str] = None

class MilkWarmingOut(BaseModel):
    id: int
    user_id: int
    baby_id: Optional[int] = None
    start_time: datetime
    end_time: Optional[datetime] = None
    amount_ml: int
    duration_seconds: Optional[int] = 0
    status: str
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

class MilkWarmingStatusOut(BaseModel):
    active_warming: Optional[MilkWarmingOut] = None
    active_duration_seconds: Optional[int] = None

    last_completed_warming: Optional[MilkWarmingOut] = None
    seconds_since_last_warming: Optional[int] = None
    minutes_since_last_warming: Optional[int] = None

    is_over_2_hours: bool = False          # True nếu seconds_since_last_warming > 7200
    status_label: str                      # 'needs_new_milk' | 'safe' | 'warming' | 'none'
    display_message: str                   # "Cần hâm sữa mới" | "Sữa còn dùng được" | "Đang hâm" | "Chưa có dữ liệu"
    safe_remaining_seconds: Optional[int] = None

class MilkWarmingDayGroup(BaseModel):
    date_str: str
    display_date: str
    total_amount_ml: int
    sessions_count: int
    records: List[MilkWarmingOut]

class MilkWarmingOverviewResponse(BaseModel):
    status: MilkWarmingStatusOut
    today_total_ml: int
    today_sessions_count: int
    groups: List[MilkWarmingDayGroup]
```

### 3.3. API Endpoints (`app/routers/milk_warming.py`)
Router prefix: `/api/milk-warming`, `tags=["Milk Warming (Lịch hâm sữa)"]`:

1. **`POST /api/milk-warming/quick-start`**:
   - Dùng cho nút **"Ghi nhanh lịch hâm"**.
   - Input chỉ cần `amount_ml` (và optional `baby_id`).
   - Tự động gán `start_time = datetime.now(timezone.utc)`, `end_time = None`, `status = "warming"`.
   - Nếu đang có một cữ `warming` chưa kết thúc khác: tùy chọn trả về cữ đang chạy hoặc tự động chốt/báo lỗi nhẹ (mặc định nếu cùng user đang có cữ warming chưa xong, trả HTTP 409 hoặc auto-cancel/hoàn tất theo quy ước rõ ràng — đề xuất: báo `409 Conflict: Đang có cữ hâm chưa kết thúc` hoặc trả về `active_warming` để tránh tạo nhầm 2 cữ song song).
2. **`POST /api/milk-warming/{record_id}/end`**:
   - Dùng cho nút **"Kết thúc hâm"**.
   - Tự động gán `end_time = data.end_time or datetime.now(timezone.utc)`.
   - Kiểm tra `end_time >= start_time`.
   - Tính `duration_seconds = int((end_time - start_time).total_seconds())`.
   - Chuyển `status = "completed"`.
3. **`POST /api/milk-warming/{record_id}/cancel`**:
   - Hủy cữ đang hâm nếu mẹ bấm nhầm (`status = "cancelled"`).
4. **`POST /api/milk-warming/manual`**:
   - Thêm mới một cữ hâm đã kết thúc trong quá khứ (nhập đầy đủ `start_time`, `end_time`, `amount_ml`).
5. **`GET /api/milk-warming/status`**:
   - Trả về `MilkWarmingStatusOut`:
     - Tìm bản ghi `status == "warming"` mới nhất của user (và baby nếu lọc).
     - Tìm bản ghi `status == "completed"` có `end_time` mới nhất.
     - Tính `seconds_since_last_warming = max(0, int((now - last_end).total_seconds()))`.
     - Quy tắc 2 giờ: Nếu `seconds_since_last_warming > 7200` (tức quá 2 giờ = 120 phút):
       - `is_over_2_hours = True`
       - `status_label = "needs_new_milk"`
       - `display_message = "Cần hâm sữa mới"`
     - Ngược lại (`<= 7200`):
       - `is_over_2_hours = False`
       - `status_label = "safe"`
       - `display_message = "Sữa còn dùng được"`
       - `safe_remaining_seconds = 7200 - seconds_since_last_warming`
6. **`GET /api/milk-warming`**:
   - Trả về `MilkWarmingOverviewResponse` bao gồm `status` hiện tại + danh sách các lần hâm gom nhóm theo ngày (`MilkWarmingDayGroup`), hỗ trợ `range_type` (`day`, `7days`, `week`, `month`, `custom`) và `tz_offset`.
7. **`PUT /api/milk-warming/{record_id}` & `DELETE /api/milk-warming/{record_id}`**:
   - Chỉnh sửa hoặc xóa bản ghi hâm sữa.

---

## 4. Kế Hoạch Triển Khai Chi Tiết (Bite-Sized Tasks)

### Giai Đoạn 1: Backend FastAPI (`mommy-and-baby-backend`)
- [ ] **Task BE-1: Model & Cache Invalidation**
  - Thêm `MilkWarmingRecord` vào `app/models.py` (tách biệt hoàn toàn với `Activity`).
  - Thêm `User.milk_warming_records` & `Baby.milk_warming_records`.
  - Thêm `invalidate_user_milk_warming(user_id)` trong `app/services/cache.py`.
- [ ] **Task BE-2: Schemas (`app/schemas.py`)**
  - Thêm các schema `MilkWarmingQuickStart`, `MilkWarmingEnd`, `MilkWarmingManualCreate`, `MilkWarmingUpdate`, `MilkWarmingOut`, `MilkWarmingStatusOut`, `MilkWarmingOverviewResponse`.
- [ ] **Task BE-3: Router & Business Logic (`app/routers/milk_warming.py`)**
  - Triển khai các endpoint `/api/milk-warming/*`.
  - Triển khai logic tính toán `seconds_since_last_warming` và ngưỡng `> 7200s` -> `"Cần hâm sữa mới"`.
  - Đăng ký router vào `app/main.py` và view quản trị vào `app/admin.py`.
- [ ] **Task BE-4: Unit & Integration Tests (`tests/test_milk_warming.py`)**
  - Test `quick-start` chỉ truyền `amount_ml` -> kiểm tra `start_time` tự điền, `status == "warming"`, `end_time is None`.
  - Test `end` -> kiểm tra `end_time` tự cập nhật, `status == "completed"`, `duration_seconds` chính xác.
  - Test `status` khi `end_time` cách hiện tại 45 phút -> `is_over_2_hours == False`.
  - Test `status` khi `end_time` cách hiện tại 2 giờ 1 phút (7260 giây) -> `is_over_2_hours == True`, `display_message == "Cần hâm sữa mới"`.
  - Test đảm bảo bảng `activities` hoàn toàn không bị ảnh hưởng khi tạo/sửa/xóa `milk_warming_records`.
  - Chạy `uv run pytest` xác nhận pass 100%.

### Giai Đoạn 2: Web Frontend (`mommy-and-baby-frontend`)
- [ ] **Task FE-1: Pinia Store (`src/stores/milkWarming.js`)**
  - Kết nối API `/api/milk-warming/*`.
  - Real-time ticker 1 giây (`setInterval(..., 1000)`) tự động tăng `secondsSinceLastWarming` & giảm `safeRemainingSeconds` (hoặc tăng `activeDurationSeconds` khi đang hâm). Tự động bật cờ `isOver2Hours = true` ngay tại giây thứ 7201 mà không cần gọi lại API.
- [ ] **Task FE-2: Thẻ Dashboard & Modal Ghi Nhanh**
  - Tạo `src/components/MilkWarmingCard.vue`:
    - Có nút **"Ghi nhanh lịch hâm"** (khi không có cữ đang hâm).
    - Có nút **"Kết thúc hâm"** (khi đang hâm).
    - Hiển thị quãng thời gian từ lần hâm gần nhất (nhảy từng giây) và cảnh báo đỏ **"Cần hâm sữa mới"** khi quá 2 giờ.
  - Tạo `src/components/MilkWarmingQuickModal.vue`: Popup tối giản chỉ hỏi số ml với các chip chọn nhanh `60, 90, 120, 150, 180, 210, 240 ml` + ô nhập tay.
  - Tạo `src/components/MilkWarmingManualModal.vue`: Modal nhập/sửa thủ công (`start_time`, `end_time`, `amount_ml`, `notes`).
  - Gắn `MilkWarmingCard.vue` vào `DashboardView.vue` và `DesktopDashboardView.vue` (đặt ở khu vực riêng biệt, tách khỏi thẻ Lịch sinh hoạt của bé).
- [ ] **Task FE-3: Trang Lịch Hâm Sữa & Menu Điều Hướng**
  - Tạo `src/views/MilkWarmingView.vue` (hiển thị tổng quan ngày, danh sách lịch sử các lần hâm theo ngày, nút Ghi nhanh / Nhập thủ công / Sửa / Xóa).
  - Thêm route `/milk-warming` vào `src/router/index.js`.
  - Thêm mục `"Lịch hâm sữa"` vào Left Sidebar Drawer (`UserLayout.vue` & `DesktopSidebar.vue`).
  - Verify trên trình duyệt ở cả Desktop và Mobile viewport **390×844** (Dark/Light theme).

### Giai Đoạn 3: Flutter Mobile App (`mommy-and-baby-mobile`)
- [ ] **Task MOB-1: Model & Provider (`lib/models/milk_warming_model.dart`, `lib/providers/milk_warming_provider.dart`)**
  - Map chuẩn JSON backend.
  - Timer 1s (`Timer.periodic`) cập nhật real-time từng giây trạng thái đang hâm / quãng thời gian từ lần hâm gần nhất / tự chuyển trạng thái sang `"Cần hâm sữa mới"` khi vượt 7200 giây.
  - Đăng ký provider trong `lib/main.dart`.
- [ ] **Task MOB-2: Dashboard Card & Quick Start Sheet**
  - Tạo `lib/views/dashboard/widgets/milk_warming_card.dart` gắn vào `DashboardView`.
  - Hỗ trợ 1-tap nút **"Ghi nhanh lịch hâm"** mở BottomSheet chỉ hỏi số ml (chip chọn nhanh + ô nhập) và 1-tap nút **"Kết thúc hâm"**.
- [ ] **Task MOB-3: Trang Lịch Hâm Sữa & Drawer Menu**
  - Tạo `lib/views/milk_warming/milk_warming_view.dart` & form thêm/sửa thủ công.
  - Thêm mục `"Lịch hâm sữa"` vào Navigation Drawer trong `lib/views/main_layout.dart`.
  - Chạy `flutter test` và `flutter analyze` xác nhận sạch lỗi.

---

## 5. Tiêu Chí Nghiệm Thu (Acceptance Criteria)

1. **Tách biệt dữ liệu & luồng:**
   - [x] Bảng `milk_warming_records` độc lập 100% với bảng `activities`. Tạo/sửa/xóa lịch hâm không làm thay đổi lịch sinh hoạt (bú/ngủ/vệ sinh) của bé.
2. **Luồng "Ghi nhanh lịch hâm" & "Kết thúc hâm":**
   - [x] Bấm **"Ghi nhanh lịch hâm"** -> Chỉ hỏi số ml -> Tự tạo bản ghi với `start_time = now`, `end_time = null`, `status = warming`.
   - [x] Khi đang hâm, bấm **"Kết thúc hâm"** -> Tự động cập nhật `end_time = now`, tính `duration_seconds`, chuyển `status = completed`.
3. **Hiển thị quãng thời gian & Cảnh báo quá 2 giờ:**
   - [x] Đếm giờ real-time tự động từng giây (1s) trên cả Web & Flutter, không cần refresh trang.
   - [x] Nếu `<= 2 giờ`: Hiển thị quãng thời gian kể từ lần hâm gần nhất và trạng thái an toàn.
   - [x] Nếu `> 2 giờ`: Hiển thị rõ ràng dòng cảnh báo: **"Cần hâm sữa mới"**.
4. **Đầy đủ chức năng quản lý lịch sử:**
   - [x] Xem danh sách lịch sử các lần hâm theo ngày với đầy đủ `start_time`, `end_time`, `duration`, `amount_ml`.
   - [x] Hỗ trợ thêm thủ công, chỉnh sửa và xóa lần hâm.
