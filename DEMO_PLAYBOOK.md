# LEADER DEMO PLAYBOOK - Finance Project

Tài liệu để thuyết trình với thầy theo đúng code thực tế của dự án, gồm:
- Tầm nhìn kỹ thuật và cách hệ thống vận hành FE + BE.
- Kịch bản demo responsive trên 2 môi trường.
- Thứ tự mở file để giải thích.
- Mỗi phần code đều có phần giải thích ngay bên dưới: code có ý nghĩa gì và tại sao chạy được.

---

## 1) Tầm nhìn kỹ thuật (mở đầu 45-60 giây)

### Lời thoại gợi ý
"Nhóm em xây dựng hệ thống quản lý tài chính cá nhân full-stack. Frontend dùng Flutter để chạy đa nền tảng (Web/Desktop/Mobile), backend dùng Spring Boot + PostgreSQL để xử lý nghiệp vụ và lưu trữ dữ liệu.  
Điểm nhấn kỹ thuật là: kiến trúc module theo feature, responsive layout rõ ràng, luồng API chuẩn REST, và có AI Assistant hỗ trợ nhập liệu/phân tích tài chính."

### Ý đồ kỹ thuật bạn cần nhấn mạnh
- **Cross-platform thật sự:** cùng một codebase Flutter nhưng render khác nhau theo kích thước màn hình.
- **Separation of concerns:** UI/State/API/Business được tách theo thư mục và theo service.
- **Dễ mở rộng:** thêm feature mới bằng cách mở rộng module trong `lib/src/features/` và endpoint backend.
- **Tính thực tiễn:** có auth, account, entries, budget, report, AI assistant, export.

---

## 2) Kiến trúc tổng thể FE + BE (1-2 phút)

## 2.1 Frontend (Flutter)

Các điểm đã đọc từ dự án:
- Entry: `lib/main.dart` (khởi tạo app và providers).
- Điều hướng chính: `lib/src/layout/main_layout.dart`.
- Gọi API tập trung: `lib/src/core/network/finance_api_client.dart`.
- Cấu hình endpoint: `lib/src/core/constants/api_constants.dart`.
- Service parser/utility: `lib/src/core/services/`.

### Lời thoại ngắn
"Frontend được tổ chức theo feature để mỗi màn hình là một module độc lập. Tầng gọi API được gom vào `FinanceApiClient` để toàn app dùng chung, tránh lặp code."

## 2.2 Backend (Spring Boot)

Các thành phần chính:
- Controllers: `AuthController`, `FinancialEntryController`, `AiAssistantController`, ...
- Services: `AuthService`, `FinancialEntryService`, `AiAssistantService`.
- DB: PostgreSQL cấu hình trong `Finance_Backend/src/main/resources/application.properties`.
- Build: Maven `Finance_Backend/pom.xml`.

### Lời thoại ngắn
"Backend dùng REST controller để nhận request, service để xử lý nghiệp vụ, repository để truy vấn DB. Nghiệp vụ quan trọng như kiểm tra số dư khi chi tiêu nằm ở service, không để ở UI."

---

## 3) Luồng hệ thống vận hành end-to-end (2 phút)

### Luồng chuẩn khi người dùng thao tác
1. Người dùng thao tác trên UI Flutter.
2. Flutter gọi `FinanceApiClient` -> request HTTP đến backend.
3. Backend controller nhận request và tách tham số/body.
4. Service xử lý nghiệp vụ (validation, rules, update balance...).
5. Service ghi/đọc PostgreSQL qua repository.
6. Backend trả JSON về Flutter.
7. Flutter parse model và cập nhật state/UI.

### Ví dụ cụ thể để nói
- Tạo giao dịch chi: Flutter gửi `POST /api/entries` -> backend kiểm tra ví có đủ số dư -> nếu đủ thì trừ tiền và lưu entry -> trả dữ liệu mới về app.
- Nếu không đủ số dư: backend trả lỗi nghiệp vụ và app hiển thị thông báo.

### Vì sao cách này "đúng kỹ thuật"
- Business rule nằm ở backend nên **dù client nào gọi** vẫn tuân thủ cùng một luật.
- Client chỉ tập trung trải nghiệm UI, backend đảm bảo dữ liệu đúng.

---

## 4) Kịch bản demo chuẩn với thầy (8-12 phút)

## 4.1 Demo responsive bắt buộc (Web/Desktop + Mobile)

### Mục tiêu
Chứng minh app không chỉ "co giãn UI", mà thực sự có chiến lược layout khác nhau:
- Desktop/Web: Side Menu (`NavigationRail`)
- Mobile: Bottom Bar (`NavigationBar`) + FAB AI kéo thả

### Cách làm
1. Mở app trên Web/Desktop trước.
2. Mở song song app trên Mobile/Emulator.
3. Chuyển tab giống nhau để thầy thấy cấu trúc navigation khác nhau nhưng logic thống nhất.

### Câu chốt
"Cùng một business flow nhưng tùy form factor, app đổi layout để tối ưu thao tác theo thiết bị."

---

## 4.2 Giới thiệu nhanh cấu trúc thư mục dự án

Mở file:
- `README.md`
- `PROJECT_STRUCTURE.md`

### Điều nên nói
- Team có chuẩn hóa docs, workflow branch, convention commit.
- Cấu trúc `core / features / layout / shared` giúp chia task song song.
- Leader review dễ vì mỗi module có ranh giới rõ.

---

## 5) File code cần mở và script giải thích (phần quan trọng nhất)

## 5.1 `pubspec.yaml`

### Bạn nói gì khi mở file
"Đây là nơi định nghĩa nền tảng kỹ thuật của frontend. Mỗi dependency được chọn theo vai trò rõ ràng."

### Thư viện trọng tâm cần giải thích
- `flutter_riverpod`: quản lý state theo hướng rõ phụ thuộc, dễ test, ít side-effect.
- `fl_chart`: vẽ biểu đồ báo cáo chi tiêu.
- `http`: giao tiếp REST API.
- `shared_preferences`: lưu trạng thái nhẹ ở máy client (ví dụ position FAB).
- `speech_to_text`, `image_picker`: nhập liệu thông minh (voice + ảnh).
- `excel`, `pdf`, `share_plus`: export và chia sẻ báo cáo.
- `easy_localization` + `flutter_localizations`: đa ngôn ngữ.

### Tại sao code này chạy được
- Flutter build-time đọc `pubspec.yaml` để tải package qua `flutter pub get`.
- Code import package và gọi API tương ứng; dependency đã được quản lý version nên môi trường nhất quán.

---

## 5.2 `lib/src/layout/main_layout.dart` (file huyết mạch #1)

### Đoạn bạn nên cuộn và giải thích trước
- `LayoutBuilder` + `constraints.maxWidth`
- Nhánh `if (width < AppConstants.mobileBreakpoint)` cho Mobile
- Nhánh `else` cho Desktop/Web
- `IndexedStack` giữ state màn hình khi đổi tab
- `NavigationBar` (mobile) vs `NavigationRail` (desktop)

### Ý nghĩa code
- `LayoutBuilder` nhận kích thước thực tế vùng render -> quyết định layout runtime.
- `IndexedStack` giữ widget con không bị dispose khi đổi tab -> UX mượt, dữ liệu tab không mất.
- Dùng `AppConstants.mobileBreakpoint`/`desktopBreakpoint` để chuẩn hóa breakpoint toàn app.

### Tại sao chạy được
- Flutter render tree theo cơ chế declarative: khi width thay đổi (resize/orientation), widget rebuild.
- Điều kiện width đổi -> nhánh UI đổi tức thời nhưng state chính (`_selectedIndex`) vẫn giữ trong `StatefulWidget`.
- Vì vậy cùng logic điều hướng nhưng hiển thị khác theo thiết bị.

### Điểm nâng cao để ghi điểm
- Mobile có FAB AI kéo thả và lưu vị trí bằng `SharedPreferences` (`_loadFabPosition`, `_saveFabPosition`) -> chứng minh quan tâm UX thực tế.
- Có `_previousIndex` để quay lại tab cũ khi bật/tắt AI assistant -> flow tự nhiên.

---

## 5.3 `lib/src/core/constants/api_constants.dart`

### Bạn nói gì
"File này là single source of truth cho endpoint. Đổi base URL một lần là toàn app đổi theo."

### Ý nghĩa code
- `baseUrl` trỏ backend đang deploy (`onrender`).
- Các path tách rõ theo domain: auth/categories/entries/accounts/ocr.

### Tại sao chạy được
- `FinanceApiClient` ghép `baseUrl + path` khi gọi HTTP.
- Tránh hard-code URL rải rác -> giảm lỗi khi đổi môi trường.

---

## 5.4 `lib/src/core/network/finance_api_client.dart` (file huyết mạch #2)

### Mở và nói theo 3 lớp
1. **Thiết kế client:**
   - Singleton `FinanceApiClient()` để dùng chung toàn app.
2. **Header user scope:**
   - `_userHeaders` gắn `X-User-Id`.
3. **Các hàm nghiệp vụ:**
   - `login/register`, `getEntries/createEntry`, `askAssistant`, `getBudgets`, ...

### Ý nghĩa code
- Gom toàn bộ network logic một nơi -> UI gọi service thay vì tự dựng request.
- Chuẩn hóa parse lỗi (`_errorMessage`) để thông báo thân thiện hơn.
- API method theo domain giúp maintain dễ và mapping 1-1 với endpoint backend.

### Tại sao chạy được
- `http` package gửi request async, nhận status/body.
- JSON decode ra map/list rồi map sang model (`fromJson`) -> dữ liệu typed trong Dart.
- Khi method throw exception, UI bắt lỗi và hiển thị message.

### Câu chốt kỹ thuật
"Tầng API này giống gateway của frontend, giúp tách UI khỏi chi tiết protocol HTTP."

---

## 5.5 `lib/src/core/services/` (file huyết mạch #3 - parser/services)

Bạn có thể mở nhanh các file để chứng minh chiều sâu kỹ thuật:
- `clipboard_parser.dart`
- `receipt_ocr_parser.dart`
- `natural_language_parser.dart`
- `note_tag_parser.dart`
- `export_service.dart`

### A) `clipboard_parser.dart`
- **Ý nghĩa:** bóc tách số tiền + gợi ý category từ text copy (tin nhắn ngân hàng).
- **Tại sao chạy được:** regex tìm amount, heuristic ngôn ngữ để suy luận category.

### B) `receipt_ocr_parser.dart`
- **Ý nghĩa:** xử lý text OCR hóa đơn để lấy tổng tiền, cửa hàng, ngày.
- **Tại sao chạy được:** duyệt theo line + keyword (`tổng`, `total`, `thanh toán`) + regex date/amount.

### C) `natural_language_parser.dart`
- **Ý nghĩa:** parse câu tự nhiên/giọng nói thành nhiều giao dịch.
- **Tại sao chạy được:** parser tách câu theo dấu câu, fallback theo vị trí amount; map keyword -> category.

### D) `note_tag_parser.dart`
- **Ý nghĩa:** tách `#tag` và `@mention` từ ghi chú để lọc/phân tích.
- **Tại sao chạy được:** regex unicode hỗ trợ tiếng Việt.

### E) `export_service.dart`
- **Ý nghĩa:** xuất Excel/PDF và share.
- **Tại sao chạy được:** dùng package chuyên dụng (`excel`, `pdf`, `share_plus`, `path_provider`) cho từng nền tảng.

---

## 6) Phần backend bạn nên trình bày ngắn nhưng sắc (2-3 phút)

## 6.1 `AuthController` + `AuthService`

### Ý nghĩa
- Quản lý login/register/google-login, verify account, reset password, upload avatar.
- Dùng `X-User-Id` cho các thao tác cập nhật user profile.

### Tại sao chạy được
- Controller nhận request DTO, service xử lý logic, repository thao tác DB.
- Mật khẩu được encode (`PasswordEncoder`), token xác thực mail/password reset có expiry.

## 6.2 `FinancialEntryController` + `FinancialEntryService`

### Ý nghĩa
- CRUD entries, filter theo date/tag, upload ảnh giao dịch.
- Rule nghiệp vụ quan trọng: không cho chi vượt số dư ví.
- Khi tạo/sửa/xóa entry thì số dư account được cập nhật tương ứng.

### Tại sao chạy được
- Service dùng transaction (`@Transactional`) để đảm bảo cập nhật entry + account balance nhất quán.
- Nếu lỗi rule, service throw exception -> controller trả lỗi có message rõ.

## 6.3 `AiAssistantController` + `AiAssistantService`

### Ý nghĩa
- Xử lý chat AI: insert/query/update/delete transaction, budget query, monthly summary, financial score.
- Dùng pipeline hybrid (rule-based + Gemini) và lưu conversation history.

### Tại sao chạy được
- Service điều phối từng bước: preprocess -> detect intent -> extract entity -> dispatch handler.
- Khi người dùng xác nhận, service tạo entry/budget thật trong DB rồi trả response cho app refresh.

---

## 7) Show tài liệu để thể hiện làm việc chuyên nghiệp

Mở:
- `README.md`
- `PROJECT_STRUCTURE.md`

Nhấn mạnh:
- Có hướng dẫn setup/chạy đa môi trường.
- Có chuẩn Git workflow (branching, commit convention).
- Có quy tắc tổ chức code và import.

Lời thoại ngắn:
"Nhóm em không chỉ code chức năng, mà còn chuẩn hóa tài liệu và quy trình để maintain dài hạn như dự án thật."

---

## 8) Timeline thuyết trình gợi ý (12 phút)

- **Phút 0-1:** Tầm nhìn kỹ thuật + mục tiêu hệ thống.
- **Phút 1-3:** Kiến trúc FE/BE + luồng vận hành end-to-end.
- **Phút 3-5:** Demo responsive (Desktop/Web + Mobile).
- **Phút 5-8:** Mở file code bắt buộc (`pubspec.yaml`, `main_layout.dart`, `api_constants.dart`, `finance_api_client.dart`).
- **Phút 8-10:** Nhấn phần services parser/AI và nghiệp vụ backend.
- **Phút 10-12:** Mở docs `.md`, chốt giá trị team, trả lời Q&A.

---

## 9) Câu trả lời mẫu khi thầy hỏi sâu

### "Tại sao dùng Riverpod thay vì setState toàn cục?"
- Riverpod tách state khỏi widget tree, dễ test, scale tốt khi app lớn.

### "Responsive chạy kiểu gì?"
- `LayoutBuilder` đọc `constraints.maxWidth` ở runtime để rẽ nhánh widget tree.

### "Vì sao backend giữ rule số dư?"
- Vì backend là nguồn sự thật dữ liệu; không phụ thuộc vào client nào gọi.

### "AI có ổn định không?"
- Dùng hybrid: Gemini cho hiểu ngữ nghĩa phức tạp, rule-based fallback khi AI không chắc.

---

## 10) Checklist ngay trước lúc demo

- Backend chạy ổn (`/health` nếu có).
- Frontend gọi đúng `ApiConstants.baseUrl`.
- Chuẩn bị sẵn 1 user test.
- Có sẵn vài dữ liệu giao dịch để demo report/AI.
- Mở sẵn các file cần trình bày để chuyển tab nhanh.
- Kiểm tra network để tránh timeout khi gọi AI/deploy server.

---

Nếu bạn muốn, mình có thể tạo thêm bản **"script nói từng câu trong 12 phút"** (đúng kiểu học thuộc) dựa trên playbook này.
