# Kế Hoạch Nâng Cấp UI/UX Màn Hình "Sinh Hoạt" (PLAN-timeline-ui-ux-upgrade.md)

> **Mục tiêu thiết kế:** Biến màn hình "Sinh Hoạt" (`TimelineView`) từ một danh sách thẻ phẳng đơn điệu thành một **Nhật Ký Nhịp Sinh Hoạt Trực Quan (Daily Rhythm Timeline)** — nơi mẹ bỉm có thể thao tác lọc loại sinh hoạt chỉ bằng **1 chạm (không cần scroll ngang)** và nắm bắt toàn bộ lịch trình trong ngày của bé qua **trục thời gian (Timeline) có mã màu ngữ nghĩa**.

---

## 1. Phân Tích Hiện Trạng & Điểm Nghẽn UX (Pain Points)

Qua khảo sát mã nguồn tại `lib/views/timeline/timeline_view.dart` và `lib/providers/activity_provider.dart`, giao diện hiện tại đang gặp 4 vấn đề lớn về UX/UI:

1. **Menu lọc loại sinh hoạt phải cuộn ngang (`ListView.horizontal`):**
   - Các chip lọc ở cuối (`Thay tã 🧷`, `Khác 🎈`) bị khuất khỏi màn hình, buộc mẹ bỉm (thường đang bế bé bằng 1 tay) phải thực hiện 2 thao tác: **vuốt ngang tìm kiếm + chạm chọn**.
   - Các `ChoiceChip` hiện tại không hiển thị số lượng bản ghi của từng loại trong ngày, khiến người dùng bấm vào mới biết là không có dữ liệu.
2. **Danh sách hoạt động chưa mang hình thái "Timeline":**
   - Hiện tại chỉ là các hộp chữ nhật rời rạc xếp chồng lên nhau (`ListView.builder`), thiếu hoàn toàn **trục thời gian dọc (vertical spine)**, **nút mốc giờ (timeline node)** và **cột giờ tách biệt bên trái**.
   - Ngày tháng năm (`dd/MM/yyyy`) bị lặp lại vô ích ở mọi thẻ trong khi người dùng đang xem theo từng ngày.
3. **Thiếu phân cấp thị giác & mã màu ngữ nghĩa (Semantic Color Coding):**
   - Mọi loại hoạt động (Bú, Ngủ, Ăn dặm, Thay tã, Tắm) đều dùng chung một nền xám `AppTheme.gray100` / `gray800` cho icon và kiểu chữ giống hệt nhau. Mẹ không thể nhìn lướt qua màu sắc để phân biệt các cữ.
   - Các thông số quan trọng nhất (`120 ml`, `45 phút`, `Tè + Ị`, `Đang ngủ...`) bị trộn lẫn vào chuỗi tiêu đề thay vì được làm nổi bật bằng **Metric Badge**.
4. **Lỗi đồng bộ ngày & bộ lọc trong `ActivityProvider`:**
   - Khi đang xem một ngày trong quá khứ và bấm chọn chip lọc, `activityProvider.setFilterType(type, babyId)` gọi lại API mà **không truyền `targetDate`**, làm dữ liệu bị nhảy về ngày hôm nay.
   - Bộ lọc `'other'` gửi query `activity_type=other` lên server khiến các hoạt động `bath` (Tắm bé) và `play` (Vận động) bị bỏ sót.

---

## 2. Hệ Thống Thiết Kế (UI/UX Design System)

Áp dụng phương pháp thiết kế từ skill **UI/UX Frontend Design**, màn hình được định hình với bảng màu ngữ nghĩa đồng bộ cùng `lib/core/theme/app_theme.dart`:

### 2.1. Bảng màu ngữ nghĩa theo loại sinh hoạt (Semantic Tokens)

| Phân loại | Key | Icon | Màu chủ đạo (Accent) | Nền nhẹ (Light Surface) | Nền tối (Dark Surface) |
| :--- | :--- | :---: | :--- | :--- | :--- |
| **Tất cả** | `all` | ✨ | `AppTheme.brand500` (`#DF4D67`) | `#FDF4F5` | `#2D1219` |
| **Cữ bú** | `feeding` | 🍼 / 🤱 | `AppTheme.brand500` (`#DF4D67`) | `#FDF4F5` | `#4C0519` |
| **Ăn dặm** | `solid` | 🥣 | `AppTheme.amber500` (`#F59E0B`) | `#FFFBEB` | `#451A03` |
| **Giấc ngủ** | `sleeping` | 😴 | `AppTheme.indigo500` (`#6366F1`) | `#EEF2FF` | `#1E1B4B` |
| **Thay tã** | `diaper` | 🧷 | `AppTheme.emerald500` (`#10B981`) | `#ECFDF5` | `#064E3B` |
| **Tắm & Khác** | `other` (`bath`, `play`, `other`) | 🛁 / 🎈 | `Sky 500` (`#0EA5E9`) | `#F0F9FF` | `#0C4A6E` |

---

## 3. Kiến Trúc Layout Mới (3 Phân Vùng)

```
┌──────────────────────────────────────────────────────────────┐
│ [ < ]     📅 Hôm nay, 07/11/2026  [Hôm nay ↺]          [ > ] │  ◄─ Vùng 1: Thanh Ngày + Nút Nhảy Nhanh
│  🍼 480ml (4 cữ)  •  🥣 120g  •  😴 3g 45p  •  🧷 5 tã       │  ◄─ Thanh Tóm Tắt Nhịp Sinh Hoạt Ngày
├──────────────────────────────────────────────────────────────┤
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐  │
│ │ ✨ Tất cả   [12]│ │ 🍼 Cữ bú    [4] │ │ 🥣 Ăn dặm   [2] │  │  ◄─ Vùng 2: Menu Lưới Bento 2x3
│ └─────────────────┘ └─────────────────┘ └─────────────────┘  │     (Không cuộn ngang, chạm 1 tay,
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐  │      hiển thị số lượng trực tiếp)
│ │ 😴 Giấc ngủ [3] │ │ 🧷 Thay tã  [2] │ │ 🛁 Tắm/Khác [1] │  │
│ └─────────────────┘ └─────────────────┘ └─────────────────┘  │
├──────────────────────────────────────────────────────────────┤
│ 🌅 BUỔI SÁNG (5 hoạt động)                                   │  ◄─ Vùng 3: Timeline Trực Quan
│                                                              │
│  09:30   (😴)───┬──────────────────────────────────────────┐ │
│  Đang ngủ  │    │ Giấc ngủ                      [🟢 ĐANG NGỦ] │ │
│            │    │ Chưa kết thúc • Bắt đầu 09:30            │ │
│            │    └──────────────────────────────────────────┘ │
│            │    ⏱ Cách 1 giờ 00 phút                        │
│  08:30   (🍼)───┬──────────────────────────────────────────┐ │
│  08:45     │    │ Bú bình • Sữa mẹ              [+120 ml]  │ │
│            │    │ 📝 "Bé bú hết veo, ợ hơi tốt"            │ │
│            │    └──────────────────────────────────────────┘ │
│            │                                                 │
│  07:15   (🧷)───┬──────────────────────────────────────────┐ │
│            ╵    │ Thay tã                       [Tè + Ị]   │ │
│                 └──────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

### Vùng 1: Thanh Điều Hướng Ngày & Tóm Tắt Nhanh Trong Ngày
- **Thanh chọn ngày thông minh:**
  - Giữ nút `<` và `>` cùng nút chạm mở lịch `showDatePicker`.
  - Khi người dùng đang ở một ngày khác hôm nay (`!_isToday`), hiển thị nút pill nhỏ **"Hôm nay ↺"** để quay về ngày hiện tại chỉ với 1 chạm.
- **Dải Tóm Tắt Nhịp Sinh Hoạt (Daily Pulse Bar):**
  - Tính toán trực tiếp từ danh sách hoạt động trong ngày đang chọn để hiển thị 4 chỉ số tổng kết gọn gàng: Tổng lượng sữa bú (`ml` / số cữ), lượng ăn dặm (`g`), tổng thời gian ngủ (`giờ/phút`), và số lần thay tã.

### Vùng 2: Menu Chọn Loại Sinh Hoạt Dạng Lưới 2×3 (No-Scroll Bento Filter Grid)
- **Thay thế hoàn toàn `ListView` cuộn ngang bằng Lưới 2 hàng × 3 cột:**
  - Hiển thị trọn vẹn cả 6 danh mục trên màn hình cùng lúc: `Tất cả`, `Cữ bú`, `Ăn dặm`, `Giấc ngủ`, `Thay tã`, `Tắm & Khác`.
  - **Thiết kế từng ô (Filter Tile):**
    - Chiều cao vừa vặn (`42px`), bo góc `12px`, bố cục ngang gồm: `Icon` + `Tên loại` + `Badge số lượng` (ví dụ: `4`).
    - Khi được chọn (`isSelected`): Nền chuyển sang màu ngữ nghĩa của loại đó (hoặc viền sáng + nền tint đậm), chữ in đậm nổi bật kèm phản hồi xúc giác nhẹ (`HapticFeedback.selectionClick()`).
    - Khi một loại có `0` hoạt động trong ngày: Hiển thị mờ nhẹ (`opacity: 0.55`) để mẹ nhận biết ngay lập tức mà không cần bấm thử.

### Vùng 3: Danh Sách Timeline Trực Quan Theo Dòng Thời Gian
1. **Phân nhóm theo buổi trong ngày (Time-of-Day Sections):**
   - Tự động gom nhóm các hoạt động theo khung giờ tự nhiên của bé:
     - `🌅 Buổi sáng` (`05:00 – 11:59`)
     - `☀️ Buổi trưa & chiều` (`12:00 – 17:59`)
     - `🌙 Buổi tối & đêm` (`18:00 – 04:59`)
   - Mỗi buổi có một header thanh mảnh hiển thị tên buổi và tổng số hoạt động trong buổi đó.
2. **Cấu trúc Dòng Thời Gian 3 Cột (Timeline Row với `IntrinsicHeight`):**
   - **Cột 1 — Cột Giờ (`52px`):**
     - Hiển thị giờ bắt đầu rõ nét (`08:30`) với `FontFeature.tabularFigures()`.
     - Phía dưới hiển thị giờ kết thúc (`~08:45`) hoặc nhãn `Đang diễn ra` nếu cữ ngủ/bú chưa kết thúc.
   - **Cột 2 — Trục Timeline & Node (`32px`):**
     - **Node tròn (`28x28`):** Nền màu ngữ nghĩa ứng với loại hoạt động, chứa icon (`🍼`, `😴`, `🥣`, `🧷`, `🛁`), có viền sáng bao quanh.
     - **Đường kẻ nối dọc (`2px`):** Nối liền mạch từ node này xuống node tiếp theo thông qua `IntrinsicHeight`.
   - **Cột 3 — Thẻ Sự Kiện Ngữ Nghĩa (Semantic Event Card):**
     - Có dải màu nhấn bên trái (`3.5px` semantic accent bar) hoặc viền màu tinh tế.
     - **Hàng tiêu đề:** Tên hoạt động rõ ràng + **Badge chỉ số chính** nằm bên phải (VD: `+120 ml`, `15 phút`, `1g 20p`, `80g`, `Tè + Ị`, hoặc badge `ĐANG DIỄN RA`).
     - **Hàng chi tiết phụ:** Hiển thị thông tin bổ trợ dạng tag nhỏ (VD: `Sữa mẹ vắt ra`, `Ngực trái`, `Ngủ sâu giấc`).
     - **Khối ghi chú (`act.notes`):** Nếu có ghi chú của mẹ, hiển thị trong một khung trích dẫn bo góc mềm mại kèm icon `📝`.
     - **Giữ nguyên tương tác quen thuộc:** Chạm vào thẻ để mở `ActivityDetailSheet` xem ảnh/video đính kèm hoặc chỉnh sửa; vuốt sang trái (`Dismissible`) để xóa bản ghi.

---

## 4. Cải Tiến Tầng State & Dữ Liệu (`ActivityProvider`)

- Lưu trữ danh sách gốc của ngày đang chọn (`List<ActivityModel> _allTimeline = []`) và ngày hiện tại đang xem (`String? _currentTargetDate`).
- Getter `timeline` sẽ lọc trực tiếp trên `_allTimeline` theo `_selectedType`:
  - `'all'` → trả về toàn bộ `_allTimeline`.
  - `'other'` → trả về các hoạt động có `activityType` thuộc `['bath', 'play', 'other']`.
  - Các loại khác (`'feeding'`, `'solid'`, `'sleeping'`, `'diaper'`) → lọc khớp `activityType`.
- Cung cấp `Map<String, int> get categoryCounts` đếm số lượng từng nhóm trên `_allTimeline` để hiển thị lên 6 ô menu Bento 2×3.
- Sửa `setFilterType(String type, int babyId)` lọc tức thì tại client (0ms delay) và giữ nguyên ngày đang chọn.
