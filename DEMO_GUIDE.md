## PRM393 Finance Project – Hướng dẫn Demo & Giới thiệu Tính năng

### 1. Mục tiêu & Nghiệp vụ của ứng dụng

- **Mục tiêu chính**: Giúp người dùng quản lý chi tiêu cá nhân một cách rõ ràng, nhanh, trực quan, hoạt động tốt trên nhiều nền tảng (Android, Web, Desktop).
- **Đối tượng**: Sinh viên, người đi làm, bất kỳ ai muốn theo dõi thu/chi, số dư ví, và phân tích thói quen chi tiêu.
- **Lý do nên dùng app**:
  - Quản lý **nhiều ví / tài khoản** cùng lúc (tiền mặt, Momo, ngân hàng…).
  - Ghi lại **mọi giao dịch thu/chi** theo danh mục, ví, ngày tháng, ghi chú, vị trí, ảnh kèm theo.
  - Có **báo cáo, biểu đồ** để nhìn nhanh: chi theo danh mục, theo tháng, theo tag…
  - Hỗ trợ **nhập nhanh bằng giọng nói** nhiều giao dịch trong một câu, tiết kiệm thời gian nhập.
  - Có **AI Assistant** (text) để trả lời câu hỏi tài chính trong app.
  - Dữ liệu lưu về backend (PostgreSQL + Spring Boot), có thể mở rộng thêm chức năng đồng bộ, auth…

Khi demo với giảng viên, bạn có thể mở đầu:  
“Đây là ứng dụng quản lý chi tiêu cá nhân, cho phép em theo dõi nhiều ví, phân loại chi tiêu, xem báo cáo và nhập nhanh giao dịch bằng giọng nói. Em sẽ demo lần lượt từng phần.”

---

### 2. Kiến trúc tổng quan

- **Frontend**: Flutter (`PRM393_Finance_Project`)
  - State management: **Riverpod**
  - Thư mục chính: `lib/src`
    - `core/` – models, theme, formatter, dịch vụ chung
    - `features/` – từng màn chức năng (auth, accounts, categories, transactions, dashboard, reports, settings, ai)
    - `shared/` – widget dùng chung
- **Backend**: Spring Boot (`Finance_Backend`)
  - DB: PostgreSQL
  - Các API chính:
    - `/api/auth` – login/register
    - `/api/accounts` – ví/tài khoản
    - `/api/categories` – danh mục
    - `/api/entries` – giao dịch
    - `/api/ai/assistant` – AI chat

Khi demo, bạn có thể mở `PROJECT_STRUCTURE.md` để minh hoạ.

---

### 3. Đăng ký, đăng nhập & phân quyền nhẹ

**Màn hình liên quan**:
- `lib/src/features/auth/login_screen.dart`
- `lib/src/features/auth/register_screen.dart`
- `Finance_Backend/src/main/java/com/example/finance_backend/controller/AuthController.java`

**Luồng demo**:
1. Mở app → nếu chưa login sẽ vào màn **Đăng nhập**.
2. Chọn **Đăng ký**:
   - Nhập email, password, tên hiển thị.
   - Gửi request lên `/api/auth/register`.
3. Đăng nhập:
   - Backend trả về `userId`, frontend lưu tạm và set vào header `X-User-Id` cho các API tiếp theo.
4. Giải thích:
   - App không dùng JWT phức tạp, mà dùng `X-User-Id` để tách dữ liệu từng user (phù hợp phạm vi môn học).

---

### 4. Quản lý tài khoản / ví (Accounts)

**File quan trọng**:
- Frontend:
  - `lib/src/features/accounts/screens/account_list_screen.dart`
  - `lib/src/features/accounts/widgets/add_account_modal.dart`
  - `lib/src/core/models/account_model.dart`
- Backend:
  - `AccountController`, `AccountService`, `Account` entity

**Chức năng & demo**:
- **Xem danh sách ví**:
  - Mở màn “Tài khoản / Ví”.
  - Hiển thị tên ví, số dư hiện tại (định dạng tiền `vi_VN`).
- **Thêm ví mới**:
  - Bấm nút `+`, nhập tên ví (VD: “Tiền mặt”), số dư ban đầu.
  - Gửi `POST /api/accounts`.
- **Sửa / Xoá ví**:
  - Sửa: bấm vào 1 ví, cập nhật tên/số dư → `PUT /api/accounts/{id}`.
  - Xoá: nếu ví còn giao dịch, backend có rule **không cho xoá** (trả lỗi 409) để tránh mất dữ liệu.

Nghiệp vụ: Người dùng có thể theo dõi **nhiều nguồn tiền** cùng lúc, mỗi giao dịch luôn gắn với một ví cụ thể.

---

### 5. Quản lý danh mục thu/chi (Categories)

**File quan trọng**:
- Model: `lib/src/core/models/category_model.dart`
- Màn hình:
  - `lib/src/features/categories/category_list_screen.dart`
  - `lib/src/features/categories/add_category_modal.dart`
  - Cũ: `category_management_screen.dart` (vẫn hoạt động, dùng chung modal mới)

**Chức năng & demo**:
- Vào **Cài đặt → Quản lý danh mục**:
  - Hiển thị danh mục dạng **Grid 2 cột**:
    - Tên danh mục (Ăn uống, Mua sắm…)
    - Icon FontAwesome + màu nền đại diện.
- **Thêm danh mục**:
  - Bấm nút `+`:
    - Nhập tên.
    - Chọn **Icon** trong grid (FontAwesome).
    - Chọn **Màu** trong dải màu.
  - Lưu → call `/api/categories`.
- **Sửa / Xoá danh mục**:
  - Tap vào 1 danh mục để sửa → cùng modal.
  - Bấm nút `⋮` → Xoá → xác nhận → call `DELETE /api/categories/{id}`.
- Danh sách danh mục được dùng ở:
  - Dropdown chọn danh mục trong màn **Thêm giao dịch**.
  - Báo cáo chi tiêu theo danh mục.

Nghiệp vụ: Giúp người dùng **tùy biến hoàn toàn** cách phân loại chi tiêu cho phù hợp với bản thân.

---

### 6. Ghi chú chi tiêu (Transactions)

**File quan trọng**:
- Frontend:
  - `lib/src/features/transactions/transaction_screen.dart`
  - `lib/src/features/transactions/widgets/add_entry_modal.dart`
  - `lib/src/core/models/financial_entry_model.dart`
- Backend:
  - `FinancialEntryController`, `FinancialEntryService`, `FinancialEntry` entity

**Chức năng & demo**:

#### 6.1 Danh sách giao dịch
- Mở màn **Ghi chú chi tiêu**:
  - Header có **lọc theo tag** (`#tag`).
  - Thanh chip lọc theo **Tất cả / Tháng này / Năm nay / Ngày cụ thể**.
  - Danh sách nhóm theo **ngày**, mỗi ngày có tổng thu – chi (net).

#### 6.2 Thêm giao dịch thủ công
- Bấm FAB `+`:
  - Mở `AddEntryModal`:
    - Chọn **Chi / Thu** (SegmentedButton).
    - Nhập **Số tiền** (parser hỗ trợ `k`, `tr`).
    - Chọn **Danh mục**.
    - Chọn **Tài khoản / Ví**.
    - Nhập **Ghi chú** (hỗ trợ `#tag` và `@mention`).
    - Tuỳ chọn:
      - Đính kèm ảnh (ví dụ ảnh hoá đơn).
      - Thêm vị trí GPS.
      - Chọn ngày giao dịch.
  - Lưu → call `POST /api/entries` + upload ảnh nếu có.
- Nghiệp vụ:
  - Mỗi giao dịch luôn có:
    - Số tiền, loại (INCOME/EXPENSE), danh mục, ví, ngày.
  - Backend có rule kiểm tra **không cho chi vượt quá số dư ví**.

#### 6.3 Sửa / Xoá giao dịch
- Vuốt sang trái để **xoá** (Dismissible + confirm dialog).
- Tap vào giao dịch để **sửa**:
  - Mở lại `AddEntryModal` với `entryToEdit`.
  - Sau khi lưu → call `PUT /api/entries/{id}`.

---

### 7. Nhập nhanh bằng giọng nói (Voice Quick Entry)

**File quan trọng**:
- `lib/src/features/transactions/widgets/ai_quick_entry_sheet.dart`
- `lib/src/core/services/natural_language_parser.dart`

**Mục tiêu**: Thêm giao dịch cực nhanh bằng giọng nói hoặc gõ câu tự nhiên.

#### 7.1 Mở tính năng
- Từ màn **Ghi chú chi tiêu**:
  - FAB nhỏ icon **mic** → `_openAiQuickEntry()` → mở `AiQuickEntrySheet`.

#### 7.2 Giao diện Nhập nhanh bằng giọng nói
- Tiêu đề: **“Nhập nhanh bằng giọng nói”**.
- Nếu clipboard có nội dung giống giao dịch → hiển thị gợi ý → bấm “Lưu” để tạo nhanh.
- Ô TextField:
  - Label: `Nói hoặc gõ: "Ăn phở 50k", "Đổ xăng 100k"`.
  - Có nút **mic** để ghi âm bằng `speech_to_text`.
- Nút **“Tạo ghi chú từ nội dung trên”**:
  - Gọi `NaturalLanguageParser.parseMultiple(text)` để phân tích.

#### 7.3 Parser nhiều giao dịch trong một câu

Ví dụ bạn nói:  
**“đi chơi hết 200k, mua sắm hết 300k, ăn cơm hết 50k”**

- `NaturalLanguageParser.parseMultiple` sẽ:
  - Tách câu theo `,` / `;` / xuống dòng.
  - Nếu không có dấu câu, parser fallback tách theo **vị trí xuất hiện các số tiền**.
  - Mỗi đoạn → một `ParsedQuickEntry`:
    - `amount`: 200000, 300000, 50000
    - `suggestedCategoryName`: dựa trên từ khoá (`đi chơi` → “Giải trí”, `mua sắm` → “Mua sắm”, `ăn cơm` → “Ăn uống”)
    - `note`: nguyên câu con đó (rút gọn 200 ký tự nếu quá dài).
  - Heuristic: nếu parser chỉ thấy **“100”** (không có `k`/`tr`) thì coi là **100k** (nhân 1000) để phù hợp văn nói.

#### 7.4 Màn “Xem lại các giao dịch”
- Nếu parser nhận được **>1 giao dịch**, app mở bottom sheet:
  - Tiêu đề: `Xem lại các giao dịch`.
  - Mô tả: `Đã nhận diện N giao dịch từ câu nói. Chọn những giao dịch bạn muốn lưu.`
  - Mỗi dòng:
    - Checkbox.
    - Số tiền (định dạng `k`).
    - Gợi ý danh mục (nếu có).
    - Ghi chú (câu gốc).
- User tick chọn các giao dịch muốn lưu → bấm **“Tiếp tục”**.

#### 7.5 Tạo giao dịch thật từ danh sách đã chọn
- Sau khi bấm **Tiếp tục**:
  - Lần lượt gọi `_openSingleFromParsed` cho từng `ParsedQuickEntry` đã chọn.
  - Mỗi lần sẽ:
    - Gọi API lấy danh sách danh mục để map `suggestedCategoryName` → `categoryId`.
    - Mở `AddEntryModal` **prefill sẵn** số tiền, danh mục, ghi chú.
    - User kiểm tra, chỉnh lại nếu cần, bấm Lưu → call API tạo giao dịch.
  - Nếu user hủy ở giữa, chuỗi dừng lại.

Khi demo, bạn có thể:
1. Bấm nút mic.
2. Nói 2–3 giao dịch liên tiếp.
3. Cho giảng viên xem sheet “Xem lại các giao dịch”.
4. Chọn 1–2 giao dịch → Tiếp tục → show modal từng cái.

---

### 8. Dashboard & thống kê nhanh

**File quan trọng**:
- `lib/src/features/dashboard/dashboard_screen.dart`
- Các widget:
  - `total_balance_card.dart`
  - `recent_transactions_list.dart`
  - `quick_action_buttons.dart`

**Chức năng & demo**:
- **Tổng số dư**: hiển thị tổng tài sản = sum(balance các ví).
- **Giao dịch gần đây**: 5–10 giao dịch mới nhất.
- **Quick actions**:
  - Thêm giao dịch mới.
  - Nhảy đến báo cáo / quản lý ví / danh mục.

Giải thích: Dashboard cho người dùng **cái nhìn 1 màn hình** về tình hình tài chính hiện tại.

---

### 9. Báo cáo & biểu đồ (Reports)

**File quan trọng**:
- `lib/src/features/reports/report_screen.dart`
- Widgets:
  - `expenses_pie_chart.dart`
  - `report_summary_card.dart`
  - `report_period_selector.dart`
  - `category_breakdown_list.dart`

**Chức năng & demo**:
- Chọn **khoảng thời gian**: tháng / năm / custom.
- Biểu đồ **pie chart** theo danh mục:
  - Màu sắc theo `CategoryColors`.
  - Tỷ lệ phần trăm chi tiêu từng danh mục.
- **Danh sách breakdown**:
  - Tên danh mục, tổng chi tiêu, phần trăm.
- Giải thích: Người dùng có thể trả lời câu hỏi “Tháng này mình chi nhiều nhất vào đâu?”.

---

### 10. Cài đặt & cá nhân hoá

**File quan trọng**:
- `lib/src/features/settings/settings_screen.dart`
- `lib/src/core/theme/theme_provider.dart`
- `lib/src/core/theme/app_theme.dart`

**Chức năng & demo**:
- **Đổi theme Light/Dark**:
  - Switch “Chế độ tối” → cập nhật `themeModeProvider`.
- **Quản lý danh mục** như đã trình bày ở trên.
- **Thông tin nhóm**:
  - Show dialog `About` với tên app, version, thông tin nhóm, thành viên.

---

### 11. AI Assistant (text)

**File quan trọng**:
- Frontend:
  - `lib/src/features/ai/ai_assistant_screen.dart`
  - `lib/src/core/models/ai_assistant_response.dart`
  - `lib/src/core/network/finance_api_client.dart` – `askAssistant`
- Backend:
  - `AiAssistantController`, `AiAssistantService`
  - Sử dụng thư viện `google-genai` (Gemini)

**Chức năng & demo**:
- Màn chat với AI:
  - Nhập câu hỏi như:
    - “Tháng này mình chi nhiều cho ăn uống không?”
    - “Gợi ý cách tiết kiệm tiền từ dữ liệu chi tiêu của mình.”
  - Backend gọi Gemini model (`ai.gemini.model=gemini-flash-latest`) và trả câu trả lời.

Giải thích: Đây là phần mở rộng thông minh, giúp người dùng nhận gợi ý / giải thích về thói quen chi tiêu.

---

### 12. Cách chạy project khi demo

1. **Chạy backend**:
   - Mở terminal tại `Finance_Backend`:
   - Chạy:
     - `mvn spring-boot:run`
   - Đảm bảo PostgreSQL đang chạy, DB `finance_db` sẵn sàng (config trong `application.properties`).
2. **Chạy frontend Flutter**:
   - Mở terminal tại `PRM393_Finance_Project`:
   - Chạy:
     - `flutter pub get`
     - `flutter run -d chrome` (hoặc Android/emulator).
3. Đảm bảo `ApiConstants.baseUrl` trỏ đúng tới backend (VD: `http://192.168.x.x:8081`).

Khi demo, bạn có thể đi theo thứ tự:
1. Đăng ký / đăng nhập.
2. Tạo ví.
3. Tạo danh mục.
4. Thêm giao dịch thủ công.
5. Dùng **Nhập nhanh bằng giọng nói** để thêm nhanh nhiều giao dịch.
6. Xem Dashboard.
7. Xem Báo cáo.
8. Vào Cài đặt: đổi theme, quản lý danh mục.
9. Thử AI Assistant.

Như vậy, giảng viên sẽ thấy rõ đầy đủ **nghiệp vụ tài chính**, **kiến trúc full-stack**, và **các tính năng nổi bật** của project. 

