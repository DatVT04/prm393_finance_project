# Demo Full Project (Updated theo code hiện tại)

Tài liệu này là bản script đầy đủ để demo với thầy theo đúng mã nguồn đã update của cả frontend và backend.

---

## 1. Bối cảnh & mục tiêu thuyết trình (45 giây)

### Lời mở đầu mẫu
"Nhóm em xây dựng hệ thống quản lý tài chính cá nhân full-stack.  
Frontend dùng Flutter đa nền tảng, backend dùng Spring Boot + PostgreSQL.  
Điểm nhấn kỹ thuật là responsive layout thật, business rule xử lý ở backend, và AI assistant để nhập liệu/phân tích tài chính."

### 4 điểm phải chứng minh trong buổi demo
1. FE + BE chạy end-to-end thật.
2. Responsive thật trên Web/Desktop và Mobile.
3. Nghiệp vụ tài chính đầy đủ (auth, ví, danh mục, giao dịch, ngân sách, báo cáo).
4. Có AI + parser thông minh, không chỉ CRUD cơ bản.

---

## 2. Chuẩn bị trước buổi demo

## 2.1 Chạy backend
```bash
cd Finance_Backend
mvn spring-boot:run
```

Kiểm tra nhanh:
- `application.properties` có PostgreSQL đúng.
- Server chạy port `8080`.

## 2.2 Chạy frontend
```bash
cd prm393_finance_project
flutter pub get
flutter run -d chrome
```

Chạy mobile:
```bash
flutter run -d android
```

## 2.3 Kiểm tra kết nối FE-BE
- Mở `lib/src/core/constants/api_constants.dart`.
- Đảm bảo `baseUrl` đúng với backend đang chạy/deploy.

---

## 3. Kịch bản demo theo timeline (12 phút)

## 0:00-1:00 - Giới thiệu kiến trúc
- FE: Flutter, module theo `lib/src/features/*`.
- BE: Spring Boot controller/service/repository.
- DB: PostgreSQL.
- AI: endpoint `/api/ai/assistant`.

## 1:00-3:00 - Demo responsive bắt buộc
Thao tác:
1. Mở app ở Web/Desktop.
2. Mở app ở Mobile.
3. Đổi tab ở cả hai môi trường.
4. Resize web để thấy rẽ nhánh layout.

File giải thích:
- `lib/src/layout/main_layout.dart`

Nói khi demo:
- Mobile dùng `NavigationBar` + FAB AI kéo thả.
- Desktop/Web dùng `NavigationRail`.
- Rẽ nhánh bằng `LayoutBuilder` và breakpoint trong `AppConstants`.

## 3:00-8:00 - Demo nghiệp vụ chính

### A) Auth
- Register -> verify account -> login.
- FE dùng response lưu `userId`; BE dùng header `X-User-Id` để tách dữ liệu user.

### B) Accounts + Categories
- Tạo ví mới, tạo danh mục mới.
- Nói rule backend: ví có giao dịch thì xóa có thể bị chặn (bảo toàn dữ liệu).

### C) Transactions
- Thêm giao dịch chi/thu.
- Sửa và xóa giao dịch.
- Lọc theo ngày/tag.
- Nói điểm kỹ thuật: backend `FinancialEntryService` cập nhật lại `account.balance` khi create/update/delete.

### D) Planning/Budget
- Tạo budget hoặc income target.
- Giải thích đây là phần kế hoạch tài chính, không chỉ tracking giao dịch.

## 8:00-10:00 - Demo AI + parser thông minh

### A) AI Assistant
- Mở `ai_assistant_screen`.
- Hỏi: "Tổng chi tháng này bao nhiêu?", "Cho mình gợi ý tiết kiệm."
- Nói backend `AiAssistantService` xử lý hybrid: rule-based + Gemini.

### B) Parser nhanh
- Voice/text quick entry (`natural_language_parser.dart`).
- Clipboard parser (`clipboard_parser.dart`).
- OCR parser (`receipt_ocr_parser.dart`).

## 10:00-11:00 - Show tài liệu team
- Mở `README.md`, `PROJECT_STRUCTURE.md`.
- Nói rõ workflow chuẩn hóa: setup, branch/commit convention, organization.

## 11:00-12:00 - Chốt và Q&A
- Chốt giá trị: scalable architecture + real business rules + practical features.

---

## 4. Danh sách file cần mở theo thứ tự đề xuất

1. `pubspec.yaml`
2. `lib/src/layout/main_layout.dart`
3. `lib/src/core/constants/api_constants.dart`
4. `lib/src/core/network/finance_api_client.dart`
5. `lib/src/core/services/natural_language_parser.dart`
6. `lib/src/core/services/clipboard_parser.dart`
7. `lib/src/core/services/receipt_ocr_parser.dart`
8. `Finance_Backend/src/main/java/com/example/finance_backend/controller/AuthController.java`
9. `Finance_Backend/src/main/java/com/example/finance_backend/service/FinancialEntryService.java`
10. `Finance_Backend/src/main/java/com/example/finance_backend/service/AiAssistantService.java`
11. `README.md`
12. `PROJECT_STRUCTURE.md`

---

## 5. Ý chính phải nói ở từng file

## 5.1 `pubspec.yaml`
- Vì sao dùng `riverpod`, `fl_chart`, `http`, `speech_to_text`, `excel/pdf`.
- Dự án hướng tới production-like feature set, không chỉ demo UI.

## 5.2 `main_layout.dart`
- `LayoutBuilder` + breakpoint.
- `IndexedStack` giữ state tab.
- Mobile vs Desktop navigation.
- FAB AI có drag + persist bằng `SharedPreferences`.

## 5.3 `finance_api_client.dart`
- Tầng API tập trung (singleton).
- Header `X-User-Id`.
- Mapping endpoint đầy đủ cho auth/accounts/entries/ai/budget.

## 5.4 `api_constants.dart`
- Tập trung toàn bộ endpoint path.
- Đổi môi trường nhanh, tránh hard-code URL rải rác.

## 5.5 Backend service/controller
- `AuthService`: verify account, reset password, Google login.
- `FinancialEntryService`: check số dư và cập nhật balance nhất quán.
- `AiAssistantService`: pipeline intent/entity/handler + history.

---

## 6. Q&A nâng cao (trả lời ngắn gọn)

### "Tại sao không để rule ở frontend?"
Frontend có thể bị bypass; rule ở backend mới đảm bảo dữ liệu nhất quán cho mọi client.

### "Vì sao dùng header X-User-Id?"
Đây là cách đơn giản, phù hợp phạm vi môn học để scope dữ liệu theo user trước khi nâng cấp JWT đầy đủ.

### "AI có sai không?"
Có thể sai nếu input mơ hồ, nên hệ thống dùng hybrid + confirmation flow để giảm lỗi trước khi ghi DB.

### "Responsive khác adaptive thế nào?"
Dự án đang làm responsive theo kích thước runtime bằng `LayoutBuilder`, đồng thời thay đổi pattern navigation theo thiết bị.

---

## 7. Checklist trước giờ demo

- Backend đang chạy ổn.
- FE gọi đúng `baseUrl`.
- Có data mẫu trong tài khoản test.
- Đã chuẩn bị 1 câu prompt AI và 1 câu voice quick entry.
- Mở sẵn tab các file quan trọng để chuyển nhanh.

