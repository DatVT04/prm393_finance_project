# Cấu trúc Dự án

## 📁 Tổng quan

```
PRM393_Finance_Project/
├── lib/
│   ├── main.dart                    # Entry point, khởi tạo app
│   └── src/
│       ├── core/                    # Core functionality
│       │   ├── constants/           # App constants
│       │   │   └── app_constants.dart
│       │   └── theme/               # App theme
│       │       └── app_theme.dart
│       ├── features/                # Feature modules (theo domain)
│       │   ├── auth/               # Authentication feature
│       │   ├── dashboard/          # Dashboard feature
│       │   │   └── dashboard_screen.dart
│       │   ├── transactions/       # Transaction management
│       │   │   ├── transaction_model.dart
│       │   │   └── transaction_screen.dart
│       │   └── reports/            # Reports & Analytics
│       ├── layout/                 # Layout components
│       │   └── main_layout.dart    # Main navigation (Mobile/Web)
│       ├── shared/                 # Shared resources
│       │   ├── models/            # Shared data models
│       │   ├── utils/             # Utility functions
│       │   │   ├── currency_formatter.dart
│       │   │   └── date_formatter.dart
│       │   └── widgets/           # Reusable widgets
│       │       └── empty_state_widget.dart
│       └── utils/                  # General utilities
├── pubspec.yaml                    # Dependencies
├── README.md                       # Tài liệu chính
├── CONTRIBUTING.md                 # Hướng dẫn Git workflow
├── SETUP.md                        # Hướng dẫn setup
└── PROJECT_STRUCTURE.md            # File này
```

## 📂 Chi tiết từng thư mục

### `lib/main.dart`
- Entry point của ứng dụng
- Khởi tạo `ProviderScope` (Riverpod)
- Cấu hình `MaterialApp` với theme

### `lib/src/core/`
Chứa các thành phần cốt lõi của app, không phụ thuộc vào business logic.

- **constants/**: Các hằng số (breakpoints, navigation indices, etc.)
- **theme/**: Theme configuration (light/dark mode)

### `lib/src/features/`
Mỗi feature là một module độc lập, có thể chứa:
- `*_screen.dart`: Màn hình chính
- `*_model.dart`: Data models
- `*_provider.dart`: Riverpod providers (nếu dùng)
- `widgets/`: Widgets riêng của feature đó

**Nguyên tắc:**
- Mỗi feature độc lập, không import lẫn nhau
- Chỉ import từ `shared/` và `core/`

### `lib/src/layout/`
Chứa các layout components:
- `main_layout.dart`: Navigation chính (responsive: Mobile Bottom Bar / Desktop Side Menu)

### `lib/src/shared/`
Chứa các thành phần được dùng chung:

- **models/**: Data models dùng chung nhiều features
- **utils/**: Utility functions (formatters, validators, etc.)
- **widgets/**: Reusable widgets (EmptyState, LoadingIndicator, etc.)

## 🎯 Quy tắc Import

### ✅ Đúng:
```dart
// Feature import từ core và shared
import 'package:prm393_finance_project/src/core/constants/app_constants.dart';
import 'package:prm393_finance_project/src/shared/utils/currency_formatter.dart';
```

### ❌ Sai:
```dart
// Feature KHÔNG được import từ feature khác
import '../transactions/transaction_model.dart'; // ❌
```

## 🔄 Navigation Flow

```
MainLayout (Responsive)
├── Mobile (< 600px): Bottom Navigation Bar
└── Desktop/Web (>= 600px): Side Navigation Rail
    └── Screens:
        ├── DashboardScreen
        ├── TransactionScreen
        ├── ReportsScreen (placeholder)
        └── SettingsScreen (placeholder)
```

## 📝 Naming Conventions

- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables/Functions**: `camelCase`
- **Constants**: `UPPER_SNAKE_CASE`

## 🚀 Thêm Feature Mới

1. Tạo thư mục trong `lib/src/features/`
2. Tạo các file cần thiết:
   - `*_screen.dart`
   - `*_model.dart` (nếu cần)
   - `*_provider.dart` (nếu dùng Riverpod)
3. Thêm screen vào `main_layout.dart`
4. Update navigation destinations

## 📦 Dependencies

Xem `pubspec.yaml` để biết danh sách đầy đủ.

**Chính:**
- `flutter_riverpod`: State management
- `fl_chart`: Charts
- `font_awesome_flutter`: Icons
- `intl`: i18n & date formatting

## 🔍 Code Organization Best Practices

1. **Separation of Concerns**: Mỗi file có một nhiệm vụ rõ ràng
2. **DRY (Don't Repeat Yourself)**: Dùng shared utils/widgets
3. **Single Responsibility**: Mỗi class/function chỉ làm một việc
4. **Feature-based Structure**: Tổ chức theo feature, không theo layer

## 📚 Tài liệu liên quan

- [README.md](README.md) - Tổng quan dự án
- [CONTRIBUTING.md](CONTRIBUTING.md) - Git workflow
- [SETUP.md](SETUP.md) - Hướng dẫn setup
