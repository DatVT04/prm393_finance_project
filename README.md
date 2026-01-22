# Personal Finance Manager

Ứng dụng quản lý tài chính cá nhân được xây dựng bằng Flutter, hỗ trợ đa nền tảng (Mobile, Web, Desktop).

## 📋 Mục lục

- [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
- [Cài đặt](#cài-đặt)
- [Cấu trúc dự án](#cấu-trúc-dự-án)
- [Công nghệ sử dụng](#công-nghệ-sử-dụng)
- [Git Workflow](#git-workflow)
- [Build và Deploy](#build-và-deploy)
- [Phân công nhiệm vụ](#phân-công-nhiệm-vụ)

## 🖥️ Yêu cầu hệ thống

- Flutter SDK: ^3.10.4
- Dart SDK: ^3.10.4
- IDE: VS Code / Android Studio / IntelliJ IDEA
- Git

## 🚀 Cài đặt

### 1. Clone repository

```bash
git clone <repository-url>
cd PRM393_Finance_Project
```

### 2. Cài đặt dependencies

```bash
flutter pub get
```

### 3. Chạy ứng dụng

```bash
# Chạy trên thiết bị/emulator mặc định
flutter run

# Chạy trên web
flutter run -d chrome

# Chạy trên desktop (Windows)
flutter run -d windows

# Chạy trên desktop (macOS)
flutter run -d macos

# Chạy trên desktop (Linux)
flutter run -d linux
```

## 📁 Cấu trúc dự án

```
lib/
├── main.dart                 # Entry point
└── src/
    ├── core/                 # Core functionality
    │   ├── constants/        # App constants
    │   └── theme/            # App theme
    ├── features/             # Feature modules
    │   ├── auth/            # Authentication
    │   ├── dashboard/       # Dashboard screen
    │   ├── transactions/    # Transaction management
    │   └── reports/         # Reports & Analytics
    ├── layout/              # Layout components
    │   └── main_layout.dart # Main navigation layout
    ├── shared/              # Shared resources
    │   ├── models/         # Shared models
    │   ├── utils/          # Utility functions
    │   └── widgets/        # Reusable widgets
    └── utils/              # General utilities
```

## 🛠️ Công nghệ sử dụng

### Dependencies chính

- **flutter_riverpod** (^2.5.1): State management
- **fl_chart** (^0.66.0): Charts và biểu đồ
- **font_awesome_flutter** (^10.7.0): Icon library
- **intl** (^0.19.0): Internationalization và date formatting

### Dev Dependencies

- **flutter_lints** (^6.0.0): Linting rules

## 🔀 Git Workflow

### Branch Strategy

- **main**: Branch chính, code production-ready
- **develop**: Branch phát triển chính
- **feature/**: Các tính năng mới (ví dụ: `feature/transaction-screen`)
- **fix/**: Sửa lỗi (ví dụ: `fix/navigation-bug`)

### Quy trình làm việc

1. **Tạo branch mới từ develop**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

2. **Commit code**
   ```bash
   git add .
   git commit -m "feat: mô tả tính năng"
   ```

3. **Push và tạo Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```
   Sau đó tạo Pull Request trên GitHub/GitLab để review.

4. **Merge code**
   - Leader sẽ review và merge vào `develop`
   - Sau khi test, merge `develop` vào `main`

### Commit Message Convention

- `feat:` Tính năng mới
- `fix:` Sửa lỗi
- `docs:` Cập nhật documentation
- `style:` Formatting, thiếu semicolon, etc.
- `refactor:` Refactor code
- `test:` Thêm/sửa tests
- `chore:` Cập nhật build tasks, package manager configs, etc.

Ví dụ:
```bash
git commit -m "feat: thêm màn hình quản lý giao dịch"
git commit -m "fix: sửa lỗi validation số tiền"
git commit -m "refactor: tách currency formatter ra shared utils"
```

## 📦 Build và Deploy

### Build cho Web

```bash
flutter build web
```

### Build cho Windows

```bash
flutter build windows
```

### Build cho Android

```bash
flutter build apk --release
# hoặc
flutter build appbundle --release
```

### Build cho iOS

```bash
flutter build ios --release
```

## 👥 Phân công nhiệm vụ

### Thành viên 1: Chương (Leader)
- ✅ Setup dự án và cấu hình
- ✅ Navigation và layout
- ✅ Review và merge code

### Thành viên 2: [Tên]
- Giao diện Transaction Screen
- Xử lý logic form và validation

### Thành viên 3: [Tên]
- Màn hình Báo cáo và Analytics
- Tích hợp charts

### Thành viên 4: [Tên]
- [Nhiệm vụ]

### Thành viên 5: [Tên]
- Màn hình Cài đặt
- User preferences

## 📝 Ghi chú

- Code phải tuân thủ Flutter style guide
- Chạy `flutter analyze` trước khi commit
- Đảm bảo app chạy được trên cả Mobile, Web và Desktop
- Test trên nhiều kích thước màn hình khác nhau

## 📄 License

[Thêm license nếu cần]
