## PRM393 Finance Project - DEMO GUIDE (Updated theo source code FE + BE)

## 1) Mục tiêu demo

Mục tiêu buổi demo là chứng minh 4 điểm:
- Hệ thống chạy full-stack thật: Flutter FE + Spring Boot BE + PostgreSQL.
- App responsive thật trên 2 môi trường: Web/Desktop và Mobile.
- Nghiệp vụ tài chính đầy đủ: auth, ví, danh mục, thu/chi, báo cáo, kế hoạch ngân sách.
- Có AI assistant và parser thông minh (voice, clipboard, OCR).

---

## 2) Tech stack thực tế của dự án

### Frontend (`prm393_finance_project`)
- Flutter + Dart
- State: `flutter_riverpod`
- Chart: `fl_chart`
- Network: `http`
- Local persistence: `shared_preferences`
- Voice: `speech_to_text`
- OCR/photo input: `image_picker`
- Export: `excel`, `pdf`, `share_plus`
- i18n: `easy_localization`, `flutter_localizations`

### Backend (`Finance_Backend`)
- Spring Boot (Maven)
- Spring Web MVC + Validation + JPA
- PostgreSQL
- Security/password encode
- AI integration: `google-genai`
- Email service: SendGrid

---

## 3) Kịch bản demo nhanh 10-12 phút

## 3.1 Mở đầu (30-45 giây)
Lời thoại gợi ý:
"Đây là hệ thống quản lý tài chính cá nhân đa nền tảng. Nhóm em tập trung cả trải nghiệm người dùng và nền tảng kỹ thuật: responsive layout, business rule ở backend, và AI hỗ trợ nhập liệu/phân tích."

## 3.2 Demo responsive bắt buộc (1-2 phút)
1. Mở app trên Web hoặc Desktop.
2. Mở app song song trên Mobile/emulator.
3. Chuyển tab giống nhau ở 2 bên để thầy thấy:
   - Desktop/Web dùng side menu (`NavigationRail`).
   - Mobile dùng bottom bar (`NavigationBar`) + FAB AI.
4. Resize cửa sổ Web để thấy layout chuyển theo breakpoint.

File giải thích: `lib/src/layout/main_layout.dart`

## 3.3 Demo luồng nghiệp vụ chính (6-7 phút)
1. Auth: register/login, verify account.
2. Accounts: tạo ví, cập nhật số dư.
3. Categories: tạo/sửa/xóa danh mục.
4. Transactions: thêm/sửa/xóa giao dịch; filter theo thời gian/tag.
5. Planning/Budget: đặt hạn mức chi tiêu hoặc mục tiêu thu nhập.
6. Reports + Dashboard: xem tổng quan và biểu đồ.
7. AI Assistant: hỏi tổng chi tháng này, xin gợi ý tiết kiệm.

## 3.4 Show sự chuyên nghiệp của team (1 phút)
Mở:
- `README.md`
- `PROJECT_STRUCTURE.md`

Nhấn mạnh:
- Có Git workflow/convention.
- Có docs setup + cấu trúc rõ ràng.
- Dễ chia task và maintain.

---

## 4) Các file bắt buộc mở khi thuyết trình

## 4.1 `pubspec.yaml`
Giải thích lý do chọn thư viện:
- `flutter_riverpod`: state management chuẩn, dễ scale.
- `fl_chart`: vẽ biểu đồ thống kê tài chính.
- `http`: giao tiếp REST.
- `shared_preferences`: lưu cấu hình nhỏ phía client.
- `speech_to_text`, `image_picker`: nhập liệu nhanh bằng giọng nói/hình ảnh.
- `excel`, `pdf`, `share_plus`: export báo cáo.

## 4.2 `lib/src/layout/main_layout.dart`
Điểm cần nói:
- `LayoutBuilder` là lõi responsive.
- `width < mobileBreakpoint` -> mobile UI.
- `else` -> web/desktop UI với `NavigationRail`.
- Dùng `IndexedStack` để giữ state các tab.
- FAB AI kéo thả và lưu vị trí bằng `SharedPreferences`.

## 4.3 Docs
- `README.md`
- `PROJECT_STRUCTURE.md`

Ý nghĩa:
- Team có chuẩn hóa quy trình, không làm ad-hoc.

---

## 5) Luồng vận hành FE -> BE -> DB (nói ngắn, dễ hiểu)

1. Người dùng thao tác UI ở Flutter.
2. FE gọi `FinanceApiClient` (`lib/src/core/network/finance_api_client.dart`).
3. Gửi request đến endpoint backend (`/api/auth`, `/api/entries`, `/api/ai/...`).
4. Controller nhận request, service xử lý nghiệp vụ.
5. Service đọc/ghi PostgreSQL.
6. Backend trả JSON; FE parse model và cập nhật UI.

Điểm nhấn kỹ thuật:
- Header `X-User-Id` dùng để scope dữ liệu theo user.
- Business rule quan trọng đặt ở backend (ví dụ không cho chi vượt số dư ví).

---

## 6) Mapping tính năng với code thực tế

## 6.1 Auth
- FE: `lib/src/features/auth/*`
- BE: `controller/AuthController.java`, `service/AuthService.java`
- Endpoint: `/api/auth/login`, `/register`, `/verify-account`, `/forgot-password`, `/reset-password`

## 6.2 Transaction/Entry
- FE: `lib/src/features/transactions/*`
- BE: `controller/FinancialEntryController.java`, `service/FinancialEntryService.java`
- Endpoint: `/api/entries`
- Rule: tạo/sửa/xóa entry sẽ cập nhật balance account tương ứng.

## 6.3 AI Assistant
- FE: `lib/src/features/ai/ai_assistant_screen.dart`
- BE: `controller/AiAssistantController.java`, `service/AiAssistantService.java`
- Endpoint: `/api/ai/assistant`, `/api/ai/history`
- Có pipeline hybrid: rule-based + Gemini.

## 6.4 Core services parser (điểm cộng khi demo)
- `clipboard_parser.dart`: parse text ngân hàng thành gợi ý giao dịch.
- `receipt_ocr_parser.dart`: parse text OCR hóa đơn.
- `natural_language_parser.dart`: parse câu nói thành nhiều giao dịch.
- `note_tag_parser.dart`: tách `#tag`, `@mention`.
- `export_service.dart`: xuất PDF/Excel.

---

## 7) Cách chạy project khi demo

## 7.1 Backend
```bash
cd Finance_Backend
mvn spring-boot:run
```

Yêu cầu:
- PostgreSQL running
- DB theo config `Finance_Backend/src/main/resources/application.properties`
- Port backend: `8080`

## 7.2 Frontend
```bash
cd prm393_finance_project
flutter pub get
flutter run -d chrome
```

Mobile:
```bash
flutter run -d android
```

Lưu ý:
- Kiểm tra `lib/src/core/constants/api_constants.dart` để đảm bảo `baseUrl` đúng môi trường demo.

---

## 8) Q&A mẫu (thường gặp)

### Q1: Vì sao chọn Riverpod?
Vì quản lý state rõ dependency, dễ test và scale hơn khi nhiều màn/feature.

### Q2: Vì sao phải responsive bằng 2 kiểu menu?
Desktop cần side menu để tận dụng không gian ngang; mobile cần bottom bar để thao tác một tay nhanh.

### Q3: Vì sao business rule ở backend?
Để mọi client đều tuân thủ cùng luật dữ liệu, tránh sai lệch nếu chỉ check ở frontend.

### Q4: AI có ổn định không?
Hệ thống dùng hybrid: AI mạnh ở hiểu ngôn ngữ tự nhiên, rule-based fallback khi không chắc.

---

## 9) Checklist trước khi vào lớp

- Backend đã chạy ổn định.
- Frontend gọi đúng base URL.
- Có sẵn tài khoản test và dữ liệu mẫu.
- Mở sẵn các file cần giải thích:
  - `pubspec.yaml`
  - `lib/src/layout/main_layout.dart`
  - `README.md`
  - `PROJECT_STRUCTURE.md`
- Chuẩn bị 1 câu AI demo, 1 luồng tạo giao dịch nhanh bằng voice/text.

