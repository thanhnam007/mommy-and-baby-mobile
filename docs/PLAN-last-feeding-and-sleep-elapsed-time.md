# Kế Hoạch Triển Khai: Hiển Thị Quãng Thời Gian Cữ Bú & Cữ Ngủ Gần Nhất (EASY Routine Elapsed Time Tracker)

> **Mã kế hoạch:** `PLAN-last-feeding-and-sleep-elapsed-time`  
> **Áp dụng đồng bộ:**  
> - Web Frontend: `F:\work\mommy-and-baby-frontend`  
> - Flutter Mobile App: `F:\work\mommy-and-baby-mobile`  
> - FastAPI Backend: `F:\work\mommy-and-baby-backend`  
> **Mục tiêu:** Giúp mẹ bỉm sữa chỉ cần liếc mắt 1 giây vào màn hình Tổng quan (Dashboard) là biết ngay:  
> 1. **Lần gần nhất con bú cách hiện tại bao lâu** (hoặc đang bú được bao nhiêu phút).  
> 2. **Lần gần nhất con ngủ cách hiện tại bao lâu / Thời gian thức (Wake Window)** (hoặc đang ngủ được bao nhiêu phút).

---

## 1. Phân Tích Nhu Cầu Người Dùng & Ý Nghĩa Nghiệp Vụ (Parenting Domain)

Trong quá trình chăm sóc trẻ sơ sinh và trẻ nhỏ (đặc biệt theo phương pháp EASY và nuôi con khoa học):

1. **Quãng thời gian từ cữ bú gần nhất (Feeding Interval):**
   - Trẻ thường bú cách nhau từ 2.5h đến 4h (tùy theo độ tuổi và lượng sữa của từng cữ).
   - Khi bé quấy khóc, câu hỏi đầu tiên của bố mẹ luôn là: *"Bé vừa bú lúc mấy giờ? Cách đây bao lâu rồi? Có phải đói không hay buồn ngủ?"*.
   - **Trạng thái đang bú:** Cần hiển thị rõ thời lượng cữ bú đang diễn ra (vd: `Đang bú 15 phút (từ 08:30)`).
   - **Trạng thái đã xong:** Cần hiển thị rõ thời gian đã trôi qua kể từ cữ bú gần nhất (vd: `Cách đây 2 giờ 15 phút (lúc 08:30)` hoặc `2g 15p trước`).

2. **Quãng thời gian từ cữ ngủ gần nhất (Wake Window & Sleep Tracker):**
   - **Wake Window (Thời gian thức tối đa giữa 2 giấc ngủ)** là chỉ số quan trọng hàng đầu để tránh tình trạng bé bị "quá giấc" (overtired - nguyên nhân số 1 khiến bé gắt ngủ, khó vào giấc và quấy khóc ban đêm).
   - **Khi bé đã thức dậy:** Mẹ cần biết chính xác bé đã thức được bao lâu kể từ lúc ngủ dậy gần nhất (vd: `Đã thức 1 giờ 45 phút (dậy lúc 11:30)`). Nhìn vào số này, mẹ đối chiếu với độ tuổi của bé (vd bé 3 tháng thức tối đa 1.5h - 2h) để chuẩn bị cho bé đi ngủ cữ tiếp theo.
   - **Khi bé đang ngủ say:** Mẹ cần biết bé đã ngủ được bao lâu (vd: `Đang ngủ ngon 1 giờ 10 phút (từ 13:00)`).

---

## 2. Khảo Sát Hiện Trạng Codebase & Điểm Cần Khắc Phục

### 2.1. Backend (`mommy-and-baby-backend`)
- **Điểm yếu ở `SleepingSummary` (`app/schemas.py` & `app/routers/activities.py`):**
  - Schema `SleepingSummary` hiện chỉ trả về: `total_sleep_minutes`, `total_sleep_formatted`, `sleep_count`, `is_currently_sleeping`, `current_sleep_id`, `current_sleep_start`.
  - **Hoàn toàn thiếu:** `last_sleep_end` (thời điểm thức dậy gần nhất), `last_sleep_start`, `minutes_since_last_sleep` (Wake window tính bằng phút), `current_sleep_duration_minutes`.
  - Kết quả: Web và Mobile không có dữ liệu chuẩn từ server để tính toán thời gian thức. Tại `DesktopDashboardView.vue` dòng 129 đang gọi `formatRecentTime(sleepSummary.last_sleep_end)` nhưng vì field này `undefined` nên luôn hiển thị mặc định `Chưa có`!
- **Điểm yếu ở `FeedingSummary`:**
  - `last_feeding_time` hiện tại chỉ lấy `start_time` của cữ bú hôm nay. Nếu hôm nay bé chưa bú cữ nào (vd sáng sớm 05:00 sáng), query fallback mới lấy cữ gần nhất nhưng chưa trả về `last_feeding_end` và `minutes_since_last_feeding` (trong khi module `pumping` đã có chuẩn `minutes_since_last_pumping`).

### 2.2. Web Frontend (`mommy-and-baby-frontend`)
- Trên **Hero Card** (cả `DashboardView.vue` và `DesktopDashboardView.vue`): Chưa có badge nhịp sinh hoạt kép hiển thị đồng thời cả cữ bú gần nhất và thời gian thức / ngủ.
- Trên **Thẻ Cữ Ngủ (Sleeping Card)**: Chỉ hiển thị tĩnh `Trạng thái: Đang ngủ ngon / Đã thức dậy` mà không có số phút/giờ trôi qua.
- **Tính phản ứng thời gian thực (Realtime Ticker):** Chưa có timer chạy ngầm mỗi 60 giây để cập nhật số phút trôi qua mà không cần người dùng reload trang.

### 2.3. Flutter Mobile App (`mommy-and-baby-mobile`)
- Model `SleepSummaryModel` và `FeedingSummaryModel` (`lib/models/activity_model.dart`) chưa có các trường dữ liệu cữ gần nhất.
- Tại `lib/views/dashboard/dashboard_view.dart`:
  - Thẻ Cữ Bú chỉ hiển thị `X cữ bú mẹ` hoặc `Hôm nay`, chưa hiển thị cữ bú gần nhất cách bao lâu.
  - Thẻ Cữ Ngủ chỉ hiển thị `Hôm nay` hoặc `Đang ngủ ngon...`, không có chỉ số Wake window hay thời gian thức.
  - Hero Card chưa hiển thị dải tóm tắt thời gian trôi qua.

---

## 3. Kiến Trúc Giải Pháp & Thiết Kế Trực Quan

### 3.1. Thiết Kế Trực Quan Trên Dashboard (Đồng bộ Web & Mobile)

#### A. Tại Hero Banner Card (Đỉnh màn hình Dashboard)
```
┌────────────────────────────────────────────────────────────────────────┐
│ 👧 Bé Bơ (Bơ)                     🎂 6 tháng 9 ngày     [🟢 Đang thức] │
│ ────────────────────────────────────────────────────────────────────── │
│ ⏱️ NHỊP SINH HOẠT THỜI GIAN THỰC (EASY PULSE):                         │
│   🍼 Bú gần nhất: 2 giờ 15 phút trước (lúc 08:30)                      │
│   ☀️ Đã thức:     1 giờ 45 phút (dậy lúc 09:00) ◄─ Wake Window         │
└────────────────────────────────────────────────────────────────────────┘
```
*(Nếu bé đang ngủ: `🟣 Đang ngủ say: 1 giờ 20 phút (từ 13:00) • 🍼 Bú gần nhất: 2g 45p trước`)*  
*(Nếu bé đang bú: `🟢 Đang bú: 15 phút (từ 10:15) • ☀️ Đã thức: 2 giờ 00 phút`)*

#### B. Tại 2 Thẻ Nổi Bật (Highlight Big Cards: Cữ Bú & Cữ Ngủ)
1. **Thẻ Cữ Bú (Feeding Card):**
   - Tiêu đề & Tổng lượng sữa: `380 ml sữa` • `4 cữ hôm nay`
   - Dòng chỉ số thời gian:
     - Nếu đang bú: `🟢 Đang bú được 18 phút (bắt đầu 10:15)`
     - Nếu đã xong: `⏰ Bú gần nhất: 2g 15p trước (lúc 08:30)`
2. **Thẻ Cữ Ngủ (Sleeping Card):**
   - Tiêu đề & Tổng thời gian ngủ: `2g 56p` • `2 giấc hôm nay`
   - Dòng chỉ số thời gian:
     - Nếu đang ngủ: `🟣 Đang ngủ được 1g 10p (từ 13:00)`
     - Nếu đã thức: `☀️ Đã thức (Wake window): 1g 45p (dậy lúc 11:15)`

---

## 4. Đặc Tả Dữ Liệu API (Backend Contract)

### 4.1. Nâng Cấp Schema `SleepingSummary` (`app/schemas.py`)
```python
class SleepingSummary(BaseModel):
    date: date
    baby_id: int
    total_sleep_minutes: int
    total_sleep_formatted: str
    sleep_count: int
    is_currently_sleeping: bool
    current_sleep_id: Optional[int] = None
    current_sleep_start: Optional[datetime] = None
    current_sleep_duration_minutes: Optional[int] = None # Số phút đang ngủ
    
    # Bổ sung các trường cữ ngủ gần nhất & thời gian thức
    last_sleep_start: Optional[datetime] = None
    last_sleep_end: Optional[datetime] = None          # Thời điểm thức dậy gần nhất
    minutes_since_last_sleep: Optional[int] = None     # Số phút đã thức (Wake window)
    sleeps: List[ActivityOut] = []
```

### 4.2. Nâng Cấp Schema `FeedingSummary` (`app/schemas.py`)
```python
class FeedingSummary(BaseModel):
    ...
    last_feeding_time: Optional[datetime] = None      # start_time cữ gần nhất
    last_feeding_end: Optional[datetime] = None       # end_time cữ gần nhất
    minutes_since_last_feeding: Optional[int] = None  # Số phút từ cữ bú gần nhất
    current_feeding_duration_minutes: Optional[int] = None # Số phút đang bú
```

---

## 5. Kế Hoạch Triển Khai Chi Tiết Từng Bước (Bite-Sized Tasks)

### Phase 1: Backend API Enhancement (`F:\work\mommy-and-baby-backend`)

#### Task 1.1: Cập nhật Pydantic Schemas trong `app/schemas.py`
- Bổ sung `last_sleep_end`, `last_sleep_start`, `minutes_since_last_sleep`, `current_sleep_duration_minutes` vào `SleepingSummary`.
- Bổ sung `last_feeding_end`, `minutes_since_last_feeding`, `current_feeding_duration_minutes` vào `FeedingSummary`.

#### Task 1.2: Cập nhật Router `app/routers/activities.py`
- Trong `get_sleeping_daily_summary`:
  - Truy vấn cữ ngủ đã kết thúc gần nhất (`Activity.activity_type == 'sleeping'`, `Activity.end_time != None`) không giới hạn trong ngày (hỗ trợ bé ngủ xuyên đêm từ hôm trước).
  - Tính `minutes_since_last_sleep = (now_utc - last_sleep.end_time).total_seconds() // 60`.
  - Nếu `active_sleep` tồn tại: tính `current_sleep_duration_minutes = (now_utc - active_sleep.start_time).total_seconds() // 60`.
- Trong `get_feeding_daily_summary`:
  - Tính `minutes_since_last_feeding = (now_utc - last_feeding.start_time).total_seconds() // 60`.
  - Nếu `active_feeding` tồn tại: tính `current_feeding_duration_minutes = (now_utc - active_feeding.start_time).total_seconds() // 60`.
- **Kiểm thử local:** Viết script kiểm tra response của 2 endpoint và test hồi quy.

---

### Phase 2: Web Frontend Implementation (`F:\work\mommy-and-baby-frontend`)

#### Task 2.1: Bổ sung Helper Định Dạng Quãng Thời Gian Sinh Hoạt (`src/utils/date.js`)
- Tạo hàm `formatElapsedDuration(minutesOrIso)`:
  - `< 1 phút` -> `"Vừa xong"`
  - `< 60 phút` -> `"${m} phút trước"` / `"${m} phút"`
  - `>= 60 phút` -> `"${h} giờ ${m} phút trước"` (hoặc `"${h}g ${m}p"`)
- Tạo hàm `formatWakeWindowText(minutes, endTimeIso)`:
  - Trả về: `"Đã thức 1g 45p (dậy lúc 11:15)"`
- Tạo hàm `formatOngoingDurationText(startTimeIso)`:
  - Trả về: `"Đang bú 18p (từ 10:15)"` hoặc `"Đang ngủ say 1g 10p (từ 13:00)"`

#### Task 2.2: Thiết Lập Reactive Ticker (Live Auto-Update mỗi 60 giây)
- Trong `DashboardView.vue` và `DesktopDashboardView.vue`, khai báo `const currentTimestamp = ref(Date.now())` được cập nhật mỗi 60s qua `setInterval` (và `clearInterval` onUnmounted).
- Giúp các nhãn thời gian trôi qua tự động nhảy số theo thời gian thực mà không cần người dùng tải lại trang.

#### Task 2.3: Nâng Cấp Giao Diện `DashboardView.vue` (Mobile Responsive)
- **Hero Card:** Thêm dải thông tin trạng thái:
  - Cữ bú gần nhất cách bao lâu.
  - Wake window (thời gian đã thức) hoặc thời gian đang ngủ say.
- **Thẻ Cữ Bú (Feeding Card):**
  - Hiển thị cữ bú gần nhất kèm giờ cụ thể và khoảng cách thời gian.
- **Thẻ Cữ Ngủ (Sleeping Card):**
  - Hiển thị rõ: Nếu đang ngủ -> thời gian đã ngủ; Nếu đã thức -> Wake window (thời gian thức từ cữ ngủ trước).

#### Task 2.4: Nâng Cấp Giao Diện `DesktopDashboardView.vue` (Desktop Pro Max)
- Cập nhật Hero Baby Card (7 cột) để hiển thị đầy đủ cả 2 chỉ số nhịp sinh hoạt song song.
- Cập nhật Bento Card Cữ Bú & Cữ Ngủ với badge thời gian trôi qua nổi bật.

#### Task 2.5: Kiểm Thử Web Frontend
- Chạy `npm run test` (hoặc `npm run build`) đảm bảo không có lỗi linter/type/template.
- Kiểm tra giao diện responsive cả 2 chế độ Mobile (390×844) và Desktop (1440×900), cả Light mode & Dark mode.

---

### Phase 3: Flutter Mobile Implementation (`F:\work\mommy-and-baby-mobile`)

#### Task 3.1: Cập Nhật Data Models (`lib/models/activity_model.dart`)
- Cập nhật `FeedingSummaryModel`: Thêm `lastFeedingEnd`, `minutesSinceLastFeeding`, `currentFeedingDurationMinutes`.
- Cập nhật `SleepSummaryModel`: Thêm `lastSleepStart`, `lastSleepEnd`, `minutesSinceLastSleep`, `currentSleepDurationMinutes`.
- Bổ sung helper getters:
  - `feedingElapsedText`: format thời gian từ cữ bú gần nhất hoặc cữ đang bú.
  - `wakeWindowText` / `sleepElapsedText`: format thời gian thức hoặc thời gian đang ngủ.

#### Task 3.2: Thiết Lập Ticker Auto-Refresh Trong `DashboardView` (`dashboard_view.dart`)
- Sử dụng `Timer.periodic(const Duration(minutes: 1), ...)` trong `_DashboardViewState` để `setState` kích hoạt tính toán lại thời gian trôi qua.

#### Task 3.3: Nâng Cấp Giao Diện `dashboard_view.dart`
- **Baby Status Hero Card:**
  - Thêm một Container phụ với nền `white.withOpacity(0.15)` bo góc `12px` hiển thị:
    - Icon 🍼 + Quãng thời gian cữ bú gần nhất (vd: `Bú gần nhất: 2g 15p trước`).
    - Dấu chấm phân cách `•`.
    - Icon 😴/☀️ + Thời gian thức hoặc ngủ (vd: `Đã thức: 1g 45p` hoặc `Đang ngủ: 1g 10p`).
- **Thẻ Cữ Bú (Expanded Big Card 1):**
  - Thay dòng chữ `breastCount > 0 ? ...` bằng thông tin cữ gần nhất:
    - Nếu đang bú: `Đang bú (từ HH:mm - Xp)`
    - Nếu đã xong: `Cữ gần nhất: Xg Yp trước (HH:mm)`
- **Thẻ Cữ Ngủ (Expanded Big Card 2):**
  - Thay dòng chữ `isSleeping ? 'Đang ngủ ngon...' : 'Hôm nay'` bằng:
    - Nếu đang ngủ: `Đang ngủ: Xg Yp (từ HH:mm)`
    - Nếu đã thức: `Đã thức: Xg Yp (dậy HH:mm)`

#### Task 3.4: Kiểm Thử Flutter Mobile App
- Cập nhật unit test trong `test/dashboard_view_test.dart` để mock các trường dữ liệu mới và verify widget hiển thị chính xác text thời gian trôi qua.
- Chạy `flutter test` đảm bảo 100% test cases pass.

---

## 6. Danh Sách Các File Cần Thay Đổi

| Project | File Path | Mục Đích Thay Đổi |
| :--- | :--- | :--- |
| **Backend** | `app/schemas.py` | Bổ sung các field thời gian trôi qua cho FeedingSummary & SleepingSummary |
| **Backend** | `app/routers/activities.py` | Tính toán `minutes_since_last_feeding`, `minutes_since_last_sleep` (Wake window) |
| **Frontend** | `src/utils/date.js` | Thêm helper định dạng quãng thời gian cữ bú & wake window |
| **Frontend** | `src/views/DashboardView.vue` | Ticker 60s, hiển thị cữ bú gần nhất & wake window trên mobile view |
| **Frontend** | `src/components/desktop/DesktopDashboardView.vue` | Hiển thị cữ bú gần nhất & wake window trên desktop hero + bento cards |
| **Mobile** | `lib/models/activity_model.dart` | Cập nhật model FeedingSummaryModel, SleepSummaryModel & helpers |
| **Mobile** | `lib/views/dashboard/dashboard_view.dart` | Ticker 60s, hiển thị cữ bú gần nhất & wake window trên hero card + big cards |
| **Mobile** | `test/dashboard_view_test.dart` | Cập nhật test case kiểm thử hiển thị thời gian cữ gần nhất |

---

## 7. Kế Hoạch Xác Minh & Nghiệm Thu (Verification & Acceptance Criteria)

1. **Kịch bản 1: Bé đang thức bình thường (Đã có cữ bú và cữ ngủ trước đó)**
   - Dashboard hiển thị rõ: Cữ bú gần nhất cách đây bao lâu (vd: `2g 15p trước`) + Wake window bé đã thức được bao lâu (vd: `Đã thức 1g 45p`).
   - Sau 1 phút không thao tác, số phút tự động nhảy tăng thêm 1 phút trên cả Web và Mobile.
2. **Kịch bản 2: Bé đang trong cữ ngủ (Bấm nút "Bắt đầu ngủ")**
   - Thẻ ngủ chuyển sang trạng thái đang ngủ say.
   - Hiển thị thời gian bé đã ngủ được bao lâu tính từ `current_sleep_start`.
   - Thẻ bú vẫn hiển thị cữ bú gần nhất trước khi bé đi ngủ.
3. **Kịch bản 3: Bé đang trong cữ bú (Bấm nút "Bắt đầu bú")**
   - Thẻ bú chuyển sang trạng thái đang bú.
   - Hiển thị thời gian bé đã bú được bao nhiêu phút tính từ `current_feeding_start`.
4. **Kịch bản 4: Đầu ngày mới (Hôm nay chưa có hoạt động nào)**
   - Hệ thống tự động fallback lấy cữ bú và cữ ngủ gần nhất từ hôm qua để tính quãng thời gian trôi qua chính xác, không bị hiện thị `Chưa có` vô nghĩa.
5. **Kịch bản 5: Đồng bộ giao diện**
   - Đảm bảo dữ liệu và cách tính hiển thị hoàn toàn đồng bộ, tương thích 100% giữa Web Frontend (`mommy-and-baby-frontend`) và Flutter Mobile (`mommy-and-baby-mobile`).
