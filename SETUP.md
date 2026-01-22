# Hướng dẫn Setup Dự án

## 📋 Yêu cầu

- Flutter SDK >= 3.10.4
- Dart SDK >= 3.10.4
- Git
- IDE: VS Code / Android Studio / IntelliJ IDEA

## 🚀 Cài đặt

### 1. Kiểm tra Flutter

```bash
flutter doctor
```

Đảm bảo tất cả các mục đều có dấu ✓ (hoặc ít nhất không có lỗi nghiêm trọng).

### 2. Clone và setup dự án

```bash
# Clone repository
git clone <repository-url>
cd PRM393_Finance_Project

# Cài đặt dependencies
flutter pub get

# Chạy code analysis
flutter analyze
```

### 3. Chạy ứng dụng

#### Trên Mobile (Android/iOS)

```bash
# Liệt kê devices
flutter devices

# Chạy trên device/emulator
flutter run
```

#### Trên Web

```bash
# Chạy trên Chrome
flutter run -d chrome

# Hoặc build production
flutter build web
```

#### Trên Desktop

**Windows:**
```bash
flutter run -d windows
flutter build windows
```

**macOS:**
```bash
flutter run -d macos
flutter build macos
```

**Linux:**
```bash
flutter run -d linux
flutter build linux
```

## 🛠️ Cấu hình IDE

### VS Code

Cài đặt extensions:
- Flutter
- Dart
- Flutter Widget Snippets

### Android Studio

Cài đặt plugins:
- Flutter
- Dart

## 📦 Dependencies

Sau khi clone, chạy `flutter pub get` để cài đặt:

- **flutter_riverpod**: State management
- **fl_chart**: Charts và biểu đồ
- **font_awesome_flutter**: Icon library
- **intl**: Internationalization

## 🔧 Troubleshooting

### Lỗi: "Expected to find project root"

Đảm bảo bạn đang ở thư mục gốc của dự án (có file `pubspec.yaml`).

### Lỗi: "Package not found"

```bash
flutter clean
flutter pub get
```

### Lỗi build trên Web

```bash
flutter config --enable-web
flutter clean
flutter pub get
flutter run -d chrome
```

### Lỗi build trên Desktop

Đảm bảo đã enable platform:
```bash
# Windows
flutter config --enable-windows-desktop

# macOS
flutter config --enable-macos-desktop

# Linux
flutter config --enable-linux-desktop
```

## ✅ Verify Setup

Chạy các lệnh sau để verify:

```bash
# Check Flutter
flutter doctor -v

# Check dependencies
flutter pub get
flutter pub outdated

# Analyze code
flutter analyze

# Test build (chọn 1 platform)
flutter build web --release
# hoặc
flutter build windows --release
```

Nếu tất cả đều pass, setup thành công! 🎉
