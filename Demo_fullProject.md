# 🎯 Hướng dẫn Demo Code - Toàn Dự Án (PRM393 Finance Project)

## 📋 Mục lục
1. [Chuẩn bị trước khi demo](#chuẩn-bị-trước-khi-demo)
2. [Luồng demo chi tiết (đính kèm code thực tế từ dự án)](#luồng-demo-chi-tiết-đính-kèm-code-thực-tế-từ-dự-án)
3. [Các điểm cần highlight & Q&A](#các-điểm-cần-highlight)

---

## 🚀 Chuẩn bị trước khi demo

### 1. Kiểm tra môi trường & chạy project
```bash
flutter pub get
flutter run
```
- **Khuyến nghị:** Demo trên **Windows** (dễ show responsive), hoặc Android/Web đều được.

### 2. Chuẩn bị
- **Mở sẵn trong IDE:**  
  - `lib/main.dart` (entry point)
  - `lib/src/layout/main_layout.dart`
  - `lib/src/features/transactions/transaction_screen.dart`

---

## 🛠️ Luồng demo chi tiết (Đính kèm code thực tế từng phần)

### 1️⃣. Giới thiệu nhanh (30 giây)
**Lời thoại mẫu:**  
"Chào thầy & các bạn, nhóm em demo app quản lý tài chính cá nhân, kiến trúc chia theo module feature để dễ maintain, mở rộng."

- 🏆 App Flutter chạy đa nền tảng (Windows/Web/Mobile)
- 📦 Code tổ chức theo `lib/src/features/*` (mỗi màn hình là 1 feature)

**Cấu trúc thư mục đã setup trong dự án:**
```plaintext
lib/
 └─ src/
     ├─ features/
     │   ├─ transactions/
     │   │   └─ transaction_screen.dart
     │   ├─ dashboard/
     │   ├─ reports/
     │   └─ settings/
     ├─ layout/
     │   └─ main_layout.dart
     └─ core/
         ├─ constants/
         └─ theme/
```

---

### 2️⃣. Màn hình chính (không cần đăng nhập)
- **Thao tác:** Chạy app → vào luôn **MainLayout** (Dashboard).
- **Giải thích:** App tập trung vào quản lý chi tiêu, kiểm soát thu chi – không có tài khoản, mật khẩu hay nạp/chuyển tiền.
- **Trích code thực tế (`lib/main.dart`):**
```dart
home: const MainLayout(),
```

---

### 3️⃣. Demo Navigation + Responsive

#### 2.1 Tính năng Navigation
- **Thao tác:** Nhấn các tab: Dashboard, Transactions, Reports, Settings...
- **Giải thích:** `main_layout.dart` gom và điều hướng các màn chính.
- **Điểm nhấn:** App quản lý chi tiêu thuần túy, kiến trúc clean.
- **Trích code thực tế `lib/src/layout/main_layout.dart` (chỉ đoạn navigation, có chú thích):**
```dart
// Biến lưu tab (index) hiện tại đang được chọn
int _currentIndex = 0;

// Danh sách các screen chính của app, mỗi tab ứng với 1 màn hình
final List<Widget> _screens = [
  DashboardScreen(),
  TransactionScreen(),
  ReportsScreen(),
  SettingsScreen(),
];

@override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Kiểm tra nếu chiều rộng lớn hơn 800, dùng NavigationRail (giao diện dạng sidebar - desktop/tablet)
      if (constraints.maxWidth > 800) {
        return Row(
          children: [
            // Sidebar navigation (dọc bên trái)
            NavigationRail(
              selectedIndex: _currentIndex, // tab đang active
              onDestinationSelected: (int index) {
                // Khi chọn tab mới: cập nhật index qua setState
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: const [
                // Các icon/tab của sidebar
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.swap_horiz),
                  label: Text('Transactions'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.pie_chart),
                  label: Text('Reports'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            // Hiển thị nội dung màn hình tương ứng tab chọn
            Expanded(child: _screens[_currentIndex]),
          ],
        );
      } else {
        // Nếu màn hình nhỏ (<800), dùng BottomNavigationBar (mobile/web nhỏ)
        return Scaffold(
          body: _screens[_currentIndex], // nội dung tab hiện tại
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex, // tab đang active
            onTap: (int index) {
              // Khi click tab: cập nhật index
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              // Các item/tab ở dưới đáy màn hình (bottom navigation)
              BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
              BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: "Transactions"),
              BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: "Reports"),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
            ],
          ),
        );
      }
    }
  );
}
```
/*
Giải thích tổng thể:
- Code check kích thước màn hình, nếu rộng thì show navigation dạng Sidebar (NavigationRail), nếu hẹp thì show dạng BottomNavigationBar (mobile).
- Mỗi navigation (sidebar hoặc bottom) khi chọn sẽ gọi setState để đổi tab, cập nhật _currentIndex, app sẽ hiện screen tương ứng.
- Các màn hình chính được ngăn cách rõ ràng (Dashboard/Transactions/Reports/Settings), mỗi màn hình là một Widget riêng, đúng hướng clean architecture.
*/

#### 2.2 Responsive (kéo dãn cửa sổ)
- **Thao tác:** Resize cửa sổ/thay đổi kích thước web để show navigation tự chuyển (bottom bar ↔ side bar...)
- **Giải thích:** Code responsive nằm trong `main_layout.dart` (xem đoạn trên)

---

### 4️⃣. Demo tính năng chính

> Tuỳ project bạn làm đến đâu: chỉ cần demo flow/happy path chính.

#### 4.1 Dashboard
- Show tổng quan (Overview nếu có).
- **Nếu chưa có gì đặc sắc thì demo hiển thị widget đơn giản hoặc stats tổng.**
```dart
// Ví dụ (lib/src/features/dashboard/dashboard_screen.dart)
Card(
  margin: EdgeInsets.all(16),
  child: ListTile(
    title: Text("Tổng số dư"),
    subtitle: Text("20.000.000 đ"),
  ),
)
```

#### 4.2 Transactions
- Thêm, hiển thị list giao dịch, lọc, trạng thái trống...
- **Điểm nhấn:** Có format tiền/ngày (`intl`).
- **Trích code ví dụ thực tế cho hiển thị format (lib/src/features/transactions/transaction_screen.dart):**
```dart
import 'package:intl/intl.dart';

ListView.builder(
  itemCount: transactions.length,
  itemBuilder: (context, index) {
    final t = transactions[index];
    return ListTile(
      leading: Icon(Icons.monetization_on),
      title: Text(t.title),
      subtitle: Text(DateFormat('dd/MM/yyyy').format(t.date)),
      trailing: Text(
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(t.amount),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
      ),
    );
  },
);

// Nếu rỗng:
if (transactions.isEmpty) {
  return Center(child: Text("Chưa có giao dịch nào..."));
}
```

#### 4.3 Reports
- Show charts/thống kê nếu có.
- **Trích code thực tế (nếu dùng fl_chart cho PieChart):**
```dart
// lib/src/features/reports/reports_screen.dart
PieChart(
  PieChartData(sections: [
    PieChartSectionData(value: 60, title: "Ăn uống"),
    PieChartSectionData(value: 40, title: "Mua sắm"),
  ]),
)
```

#### 4.4 Settings
- Show tuỳ chọn: theme, language, profile...
```dart
// lib/src/features/settings/settings_screen.dart
SwitchListTile(
  title: Text("Giao diện tối"),
  value: isDark,
  onChanged: (value) { ... },
),
DropdownButton(
  value: currentLang,
  items: [...],
  onChanged: (val) { ... },
)
```

---

## 💡 Các điểm cần highlight & Q&A

### A. Các file code cần biết/thầy hỏi
- `lib/main.dart`: Home là MainLayout (màn chính).
- `lib/src/features/transactions/`: ghi nhận, quản lý giao dịch thu chi.
- `lib/src/layout/main_layout.dart`: navigation chính, code responsive.

### B. Giải thích ngắn:
- **Không có login?**  
  App tập trung nghiệp vụ quản lý tài chính, kiểm soát chi tiêu – không phải app ngân hàng.
- **Không nạp/chuyển tiền?**  
  Chỉ ghi nhận thu chi, note, thống kê – người dùng tự quản lý số liệu.
- **Vì sao chia feature?**  
  Độc lập, dễ maintain, dễ chia task team.

---

## ⏰ Gợi ý timeline demo

- 0:00–1:00 Giới thiệu (app quản lý chi tiêu, không login)
- 1:00–4:00 Navigation + Responsive
- 4:00–10:00 Transactions/Reports/Dashboard/Settings
- 10:00–12:00 Q&A

