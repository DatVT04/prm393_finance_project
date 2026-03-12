# 🎯 Hướng dẫn Demo Code - Chương (Thành viên 1)

## 📋 Mục lục
1. [Chuẩn bị trước khi demo](#chuẩn-bị-trước-khi-demo)
2. [Luồng demo chi tiết](#luồng-demo-chi-tiết)
3. [Giải thích code](#giải-thích-code)
4. [Các điểm cần highlight](#các-điểm-cần-highlight)
5. [Q&A dự kiến](#qa-dự-kiến)

---

## 🚀 Chuẩn bị trước khi demo

### 1. Kiểm tra môi trường
```bash
# Đảm bảo app chạy được trên cả 3 platform
flutter doctor
flutter pub get

# Test nhanh
flutter run -d windows
flutter run -d chrome
flutter run -d android
```

### 2. Chuẩn bị dữ liệu demo
- Chuẩn bị sẵn 3-5 giao dịch mẫu để nhập nhanh khi demo
- Ví dụ:
  - Ăn uống: 150.000 đ - "Bữa trưa"
  - Xăng xe: 200.000 đ - "Đổ xăng"
  - Mua sắm: 500.000 đ - "Mua đồ dùng"

### 3. Mở sẵn các file quan trọng
- `lib/src/layout/main_layout.dart` - Navigation
- `lib/src/features/transactions/transaction_screen.dart` - Transaction screen
- `lib/main.dart` - Entry point
- `pubspec.yaml` - Dependencies

---

## 🎬 Luồng demo chi tiết

### **PHẦN 1: Giới thiệu tổng quan (2 phút)**

#### 1.1. Giới thiệu dự án
```
"Xin chào thầy và các bạn, em là Chương - thành viên 1 của nhóm.
Em phụ trách 2 phần chính:
1. Setup dự án và Navigation (Leader)
2. Màn hình quản lý Giao dịch (Transaction Screen)
```

#### 1.2. Demo app chạy trên 3 platform
```
"App của chúng em hỗ trợ đa nền tảng:
- Desktop (Windows/macOS/Linux)
- Web (Chrome)
- Mobile (Android/iOS)

Em sẽ demo trên Windows trước..."
```

**Hành động:**
- Mở app trên Windows
- Code liên quan nằm ở: `lib/src/layout/main_layout.dart`
- Giải thích: "App tự động phát hiện kích thước màn hình và chuyển layout dựa theo kích thước"

---

### **PHẦN 2: Setup và Navigation (5 phút)**

#### 2.1. Cấu trúc dự án
```
"Đầu tiên, em xin trình bày về cấu trúc dự án mà em đã setup..."
```

**Mở VS Code/IDE và show:**
```
lib/src/
├── core/           # Core functionality
│   ├── constants/  # App constants (breakpoints, indices)
│   └── theme/      # App theme (light/dark)
├── features/       # Feature modules
│   ├── dashboard/
│   ├── transactions/  ← Phần làm
│   ├── reports/
│   └── settings/
├── layout/         # Navigation layout
│   └── main_layout.dart  ← Responsive navigation
└── shared/         # Shared resources
    ├── utils/      # CurrencyFormatter, DateFormatter
    └── widgets/    # EmptyStateWidget
```

**Giải thích:**
- "Cấu trúc này tuân thủ Clean Architecture"
- "Mỗi feature độc lập, dễ maintain và scale"
- "Shared folder chứa code dùng chung"

#### 2.2. Dependencies (pubspec.yaml)
```
"Em đã cấu hình các thư viện cần thiết..."
```

**Show pubspec.yaml:**
```yaml
dependencies:
  flutter_riverpod: ^2.5.1  # State management
  fl_chart: ^0.66.0         # Charts (cho phần báo cáo)
  font_awesome_flutter: ^10.7.0  # Icons
  intl: ^0.19.0             # Internationalization
```

**Giải thích:**
- "flutter_riverpod: State management cho app"
- "fl_chart: Sẽ dùng cho phần báo cáo của bạn khác"
- "intl: Format date, currency theo locale"

#### 2.3. Responsive Navigation
```
"Phần navigation em làm responsive, tự động chuyển đổi giữa Mobile và Desktop..."
```

**Mở `lib/src/layout/main_layout.dart`:**

**Giải thích code:**
```dart
// Dùng LayoutBuilder để detect kích thước màn hình
LayoutBuilder(
  builder: (context, constraints) {
    // Mobile: < 600px → Bottom Navigation Bar
    if (constraints.maxWidth < AppConstants.mobileBreakpoint) {
      return Scaffold(
        bottomNavigationBar: NavigationBar(...),
      );
    }
    // Desktop/Web: >= 600px → Side Navigation Rail
    else {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(...),  // Side menu
            Expanded(child: screen),
          ],
        ),
      );
    }
  },
)
```

**Demo:**
1. Resize cửa sổ app (nếu web/desktop)
2. Show: "Khi thu nhỏ < 600px → chuyển sang Bottom Bar"
3. Show: "Khi mở rộng >= 600px → chuyển sang Side Rail"

**Highlight:**
- ✅ Tự động responsive
- ✅ Chạy được trên cả 3 platform
- ✅ UX tốt trên mọi kích thước màn hình

---

### **PHẦN 3: Transaction Screen - Giao diện (5 phút)**

#### 3.1. Giới thiệu màn hình
```
"Bây giờ em sẽ trình bày phần Transaction Screen - màn hình quản lý giao dịch..."
```

**Chuyển sang tab "Giao dịch" trong app**

#### 3.2. Floating Action Button và Modal
```
"Màn hình này có nút (+) ở góc dưới bên phải để thêm giao dịch mới.
Khi click, sẽ mở Modal Bottom Sheet với form nhập liệu..."
```

**Demo:**
1. Click nút FloatingActionButton (+)
2. Show: "Modal slide up từ dưới lên"
3. Form có các trường:
   - Số tiền (TextField với validation)
   - Danh mục (DropdownButton với 7 danh mục)
   - Ghi chú (TextField, tùy chọn, max 250 ký tự)
   - Ngày (DatePicker)

**Show code `add_transaction_modal.dart`:**
```dart
// Modal Bottom Sheet
void _openAddTransactionModal(BuildContext context) async {
  final newTransaction = await showModalBottomSheet<Transaction>(
    context: context,
    isScrollControlled: true,  // Cho phép modal mở rộng
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => AddTransactionModal(),
  );
  
  if (newTransaction != null) {
    setState(() {
      _transactions.add(newTransaction);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    });
  }
}

// Form trong Modal
TextFormField(
  controller: _amountController,
  keyboardType: TextInputType.numberWithOptions(decimal: true),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số tiền';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Số tiền không hợp lệ';
    }
    if (amount <= 0) {
      return 'Số tiền phải lớn hơn 0';
    }
    if (amount > 10000000000) {
      return 'Số tiền quá lớn';
    }
    return null;
  },
)
```

**Giải thích:**
- "Dùng Modal Bottom Sheet - UX tốt trên mobile"
- "isScrollControlled: true để modal có thể mở rộng khi keyboard hiện"
- "Form có validation đầy đủ (required, type, range)"
- "DatePicker dùng locale tiếng Việt"

#### 3.3. Danh sách giao dịch (Grouped by Date)
```
"Danh sách giao dịch được nhóm theo ngày và sắp xếp mới nhất trước..."
```

**Demo:**
1. Show: "Giao dịch được group theo ngày"
2. Show: "Header hiển thị 'Hôm nay', 'Hôm qua', hoặc ngày cụ thể"
3. Show: "Tổng tiền trong ngày hiển thị ở header"

**Show code:**
```dart
// Group transactions by date
Map<String, List<Transaction>> _groupTransactionsByDate() {
  Map<String, List<Transaction>> grouped = {};
  for (var tx in _transactions) {
    String dateKey = DateFormat('dd/MM/yyyy').format(tx.date);
    if (grouped.containsKey(dateKey)) {
      grouped[dateKey]!.add(tx);
    } else {
      grouped[dateKey] = [tx];
    }
  }
  return grouped;
}

// Build transaction item với Dismissible
Widget _buildTransactionItem(Transaction tx) {
  return Dismissible(
    key: Key(tx.id),
    direction: DismissDirection.endToStart,  // Swipe từ phải sang trái
    background: Container(
      alignment: Alignment.centerRight,
      child: Icon(Icons.delete, color: Colors.red),
    ),
    onDismissed: (_) => _deleteTransaction(tx.id),
    child: ListTile(
      leading: Container(
        decoration: BoxDecoration(
          color: _getCategoryColor(tx.category).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(_getCategoryIcon(tx.category)),
      ),
      title: Text(tx.category),
      subtitle: Text(tx.note),
      trailing: Text(formatCurrency(tx.amount)),
    ),
  );
}
```

**Giải thích:**
- "Group transactions theo ngày để dễ xem"
- "Dùng Dismissible để swipe delete (UX tốt trên mobile)"
- "Mỗi category có icon và màu riêng"
- "Format số tiền theo locale Việt Nam (1.500.000 đ)"

---

### **PHẦN 4: Transaction Screen - Logic (8 phút)**

#### 4.1. Validation
```
"Khi nhấn nút Lưu, code sẽ validate..."
```

**Show code validation:**
```dart
void _saveTransaction() {
  // 1. Validate form
  if (!_formKey.currentState!.validate()) {
    return;  // Hiển thị lỗi trên form
  }

  // 2. Validate số tiền > 0
  final amount = double.tryParse(_amountController.text) ?? 0;
  if (amount <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Số tiền phải lớn hơn 0!')),
    );
    return;
  }

  // 3. Validate đã chọn danh mục
  if (_selectedCategory == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Vui lòng chọn danh mục!')),
    );
    return;
  }
  // ...
}
```

**Demo validation:**
1. Thử nhấn "Lưu" khi chưa nhập gì → Show lỗi
2. Nhập số tiền = 0 → Show "Số tiền phải lớn hơn 0!"
3. Không chọn danh mục → Show "Vui lòng chọn danh mục!"

**Giải thích:**
- "Validation 2 lớp: Form validation + Business logic validation"
- "Hiển thị lỗi bằng SnackBar (màu đỏ) để user dễ thấy"

#### 4.2. Lưu giao dịch (Fake Action)
```
"Khi validation pass, Modal sẽ return Transaction object về screen chính..."
```

**Show code trong Modal:**
```dart
void _submitData() {
  if (!_formKey.currentState!.validate()) {
    return;  // Validation failed
  }

  final enteredAmount = double.parse(_amountController.text);
  
  if (_selectedCategory == null) return;

  // Tạo Transaction object
  final newTransaction = Transaction(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    amount: enteredAmount,
    note: _noteController.text,
    category: _selectedCategory!,
    date: _selectedDate,
  );

  // Return về screen chính
  Navigator.of(context).pop(newTransaction);
}
```

**Show code trong Screen:**
```dart
void _openAddTransactionModal(BuildContext context) async {
  final newTransaction = await showModalBottomSheet<Transaction>(...);
  
  if (newTransaction != null) {
    setState(() {
      _transactions.add(newTransaction);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm giao dịch mới')),
    );
  }
}
```

**Demo:**
1. Nhập đầy đủ form trong Modal → Nhấn "Lưu Giao dịch"
2. Show: "Modal đóng lại"
3. Show: "Giao dịch xuất hiện ngay trong danh sách (đã group theo ngày)"
4. Show: "Thông báo thành công (màu xanh)"

**Giải thích:**
- "Modal return Transaction object về screen chính"
- "Screen chính nhận data và update List"
- "Dùng setState() để trigger rebuild UI"
- "Data lưu tạm trong RAM (List _transactions)"
- "Sắp xếp theo ngày mới nhất trước"

#### 4.3. Xóa giao dịch (Swipe to Delete)
```
"User có thể xóa giao dịch bằng cách swipe từ phải sang trái..."
```

**Show code:**
```dart
Widget _buildTransactionItem(Transaction tx) {
  return Dismissible(
    key: Key(tx.id),
    direction: DismissDirection.endToStart,  // Chỉ swipe từ phải sang trái
    background: Container(
      alignment: Alignment.centerRight,
      child: Icon(Icons.delete, color: Colors.red),
    ),
    onDismissed: (_) => _deleteTransaction(tx.id),
    child: ListTile(...),
  );
}

void _deleteTransaction(String id) {
  setState(() {
    _transactions.removeWhere((tx) => tx.id == id);
  });
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Đã xóa giao dịch')),
  );
}
```

**Demo:**
1. Swipe một giao dịch từ phải sang trái
2. Show: "Background màu đỏ với icon delete hiện ra"
3. Show: "Khi swipe hết → giao dịch biến mất"
4. Show: "Thông báo 'Đã xóa giao dịch'"

**Giải thích:**
- "Dùng Dismissible widget - UX tốt trên mobile"
- "Swipe gesture tự nhiên, không cần nút"
- "Dùng removeWhere() để xóa theo ID"
- "setState() để cập nhật UI ngay lập tức"

#### 4.4. Data Model
```
"Em đã tạo Transaction model để quản lý data..."
```

**Show `transaction_model.dart`:**
```dart
class Transaction {
  final String id;
  final double amount;
  final String note;
  final String category;
  final DateTime date;

  Transaction({
    required this.id,
    required this.amount,
    required this.note,
    required this.category,
    required this.date,
  });
}
```

**Giải thích:**
- "Model đơn giản, immutable"
- "Dễ mở rộng sau này (thêm fields như type: income/expense)"

---

### **PHẦN 5: Shared Utilities (3 phút)**

#### 5.1. Currency Formatter
```
"Em đã tạo CurrencyFormatter trong shared/utils để format số tiền..."
```

**Show `currency_formatter.dart`:**
```dart
class CurrencyFormatter {
  static String format(num amount) {
    return "${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), 
      (match) => '.'
    )} đ";
  }
}
```

**Giải thích:**
- "Format: 25000000 → '25.000.000 đ'"
- "Dùng regex để thêm dấu chấm phân cách"
- "Có thể dùng lại ở các màn hình khác"

#### 5.2. Date Formatter
```
"Tương tự, DateFormatter để format ngày tháng..."
```

**Show `date_formatter.dart`:**
```dart
class DateFormatter {
  static String format(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
           "${date.month.toString().padLeft(2, '0')}/"
           "${date.year}";
  }
}
```

**Giải thích:**
- "Format: DateTime(2024, 1, 15) → '15/01/2024'"
- "Dùng padLeft để đảm bảo 2 chữ số"

---

### **PHẦN 6: Tổng kết (2 phút)**

#### 6.1. Tóm tắt những gì đã làm
```
"Tóm lại, em đã hoàn thành:

1. Setup dự án:
   ✅ Cấu trúc thư mục chuẩn
   ✅ Cấu hình dependencies
   ✅ Responsive navigation (3 platform)

2. Transaction Screen:
   ✅ Modal Bottom Sheet để thêm giao dịch
   ✅ Form nhập liệu đầy đủ với validation
   ✅ Group transactions theo ngày
   ✅ Swipe to delete (Dismissible)
   ✅ Lưu/xóa giao dịch (fake data)
   ✅ UI/UX đẹp, responsive

3. Shared utilities:
   ✅ CurrencyFormatter
   ✅ DateFormatter
   ✅ EmptyStateWidget"
```

#### 6.2. Điểm nổi bật
```
"Điểm nổi bật:
- ✅ App chạy được trên 3 platform (Desktop, Web, Mobile)
- ✅ Responsive tự động
- ✅ Code clean, dễ maintain
- ✅ Validation đầy đủ
- ✅ UI/UX tốt"
```

#### 6.3. Hướng phát triển
```
"Sau này có thể mở rộng:
- Kết nối Backend API
- Lưu vào database (SQLite/Hive)
- Thêm tính năng sửa giao dịch
- Thêm filter, search
- Export/Import data"
```

---

## 💡 Các điểm cần highlight

### 1. Responsive Design
- ✅ Tự động chuyển layout theo kích thước màn hình
- ✅ Chạy tốt trên cả Desktop, Web, Mobile

### 2. Code Quality
- ✅ Clean Architecture
- ✅ Separation of Concerns
- ✅ Reusable components (shared/utils, shared/widgets)

### 3. User Experience
- ✅ Validation rõ ràng
- ✅ Feedback ngay lập tức (SnackBar)
- ✅ Form tự động reset sau khi lưu

### 4. Best Practices
- ✅ Dùng FormKey cho validation
- ✅ setState() để update UI
- ✅ Immutable models
- ✅ Constants trong AppConstants

---

## ❓ Q&A dự kiến

### Q1: "Tại sao dùng List trong RAM thay vì database?"
**A:** 
"Hiện tại em dùng fake data trong RAM để demo UI/UX. Sau này sẽ tích hợp Backend API hoặc local database (SQLite/Hive) để lưu trữ persistent."

### Q2: "Làm sao để data không mất khi đóng app?"
**A:**
"Sau này sẽ dùng:
- SharedPreferences cho settings đơn giản
- SQLite/Hive cho data phức tạp
- Hoặc Backend API để sync data"

### Q3: "Navigation responsive hoạt động như thế nào?"
**A:**
"Dùng LayoutBuilder để detect kích thước màn hình. Nếu < 600px → Bottom Bar, >= 600px → Side Rail. Flutter tự động rebuild khi resize."

### Q4: "Có thể thêm tính năng sửa giao dịch không?"
**A:**
"Có thể. Chỉ cần:
1. Thêm nút Edit trên mỗi item
2. Mở dialog/modal với form đã điền sẵn
3. Update transaction trong List
4. setState() để refresh UI"

### Q5: "Validation có đủ không?"
**A:**
"Hiện tại có:
- Form validation (required fields)
- Business logic validation (amount > 0, category selected)
- Type validation (số tiền phải là số)

Có thể thêm:
- Max amount limit
- Date range validation
- Note length limit"

---

## 📝 Checklist trước khi demo

- [ ] App chạy được trên Windows
- [ ] App chạy được trên Web (Chrome)
- [ ] App chạy được trên Android (nếu có)
- [ ] Chuẩn bị 3-5 giao dịch mẫu
- [ ] Mở sẵn các file quan trọng trong IDE
- [ ] Test lại các tính năng:
  - [ ] Nhập form
  - [ ] Validation
  - [ ] Lưu giao dịch
  - [ ] Xóa giao dịch
  - [ ] Responsive navigation
- [ ] Chuẩn bị sẵn câu trả lời cho Q&A

---

## 🎯 Tips khi demo

1. **Nói rõ ràng, không nói nhanh quá**
2. **Vừa demo vừa giải thích code**
3. **Highlight các điểm nổi bật**
4. **Sẵn sàng trả lời câu hỏi**
5. **Nếu có lỗi, bình tĩnh xử lý**

**Chúc bạn demo thành công! 🚀**
