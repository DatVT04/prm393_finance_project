# 📝 Quick Reference - Demo Code

## ⏱️ Timeline (Tổng: ~25 phút)

1. **Giới thiệu tổng quan** (2 phút)
2. **Setup và Navigation** (5 phút)
3. **Transaction Screen - UI** (5 phút)
4. **Transaction Screen - Logic** (8 phút)
5. **Shared Utilities** (3 phút)
6. **Tổng kết** (2 phút)

---

## 🎯 Luồng Demo Nhanh

### 1. Mở app → Show 3 platform
```
"App chạy được trên Desktop, Web, Mobile"
→ Resize window để show responsive
```

### 2. Show cấu trúc code
```
lib/src/
├── core/        ← Constants, Theme
├── features/    ← Transaction screen ở đây
├── layout/      ← Responsive navigation
└── shared/      ← Utils, Widgets dùng chung
```

### 3. Demo Navigation
```
- Mobile (< 600px): Bottom Bar
- Desktop (>= 600px): Side Rail
→ Resize để show chuyển đổi
```

### 4. Demo Transaction Screen
```
1. Click nút (+) → Modal mở lên
2. Nhập form:
   - Số tiền: 150000
   - Danh mục: Ăn uống
   - Ghi chú: Bữa trưa
   - Ngày: Chọn ngày
3. Nhấn "Lưu" → Modal đóng, giao dịch hiện ra
4. Swipe giao dịch → Xóa
```

### 5. Show code highlights
```
- Validation (2 lớp)
- Modal Bottom Sheet
- Group by date
- Swipe to delete
- Format currency/date
```

---

## 💬 Script Nói

### Mở đầu
```
"Xin chào thầy và các bạn, em là Chương - thành viên 1.
Em phụ trách Setup dự án và màn hình Transaction.
Em xin trình bày..."
```

### Kết thúc
```
"Tóm lại, em đã hoàn thành:
1. Setup dự án với cấu trúc chuẩn
2. Responsive navigation (3 platform)
3. Transaction screen đầy đủ tính năng
4. Shared utilities để tái sử dụng

Cảm ơn thầy và các bạn đã lắng nghe!"
```

---

## 🎨 Điểm cần highlight

✅ **Responsive**: Tự động chuyển layout
✅ **Clean Code**: Cấu trúc rõ ràng, dễ maintain
✅ **UX tốt**: Modal, Swipe delete, Group by date
✅ **Validation**: Đầy đủ, rõ ràng
✅ **Reusable**: Shared utils, widgets

---

## ⚠️ Lưu ý

- Nói rõ ràng, không nhanh quá
- Vừa demo vừa giải thích code
- Sẵn sàng trả lời câu hỏi
- Nếu có lỗi → bình tĩnh xử lý

---

**Xem chi tiết trong DEMO_GUIDE.md**
