# Hướng dẫn đóng góp (Contributing Guide)

## 🔀 Git Workflow cho Team

### 1. Setup ban đầu

```bash
# Clone repository
git clone <repository-url>
cd PRM393_Finance_Project

# Tạo branch develop nếu chưa có
git checkout -b develop
git push -u origin develop
```

### 2. Quy trình làm việc hàng ngày

#### Bước 1: Cập nhật code mới nhất

```bash
# Chuyển về develop
git checkout develop

# Pull code mới nhất
git pull origin develop
```

#### Bước 2: Tạo branch mới cho tính năng

```bash
# Tạo branch từ develop
git checkout -b feature/transaction-screen
# hoặc
git checkout -b fix/navigation-bug
```

#### Bước 3: Làm việc và commit

```bash
# Sau khi code xong, add files
git add .

# Commit với message rõ ràng
git commit -m "feat: thêm màn hình quản lý giao dịch"
```

**Quy tắc commit message:**
- `feat:` - Tính năng mới
- `fix:` - Sửa lỗi
- `docs:` - Cập nhật tài liệu
- `style:` - Formatting code
- `refactor:` - Refactor code
- `test:` - Thêm/sửa tests
- `chore:` - Cập nhật config, dependencies

#### Bước 4: Push và tạo Pull Request

```bash
# Push branch lên remote
git push origin feature/transaction-screen
```

Sau đó:
1. Vào GitHub/GitLab
2. Tạo Pull Request từ `feature/transaction-screen` → `develop`
3. Ghi rõ mô tả những gì đã làm
4. Tag Leader để review

#### Bước 5: Review và Merge (Leader)

```bash
# Sau khi review xong, merge vào develop
git checkout develop
git pull origin develop
git merge feature/transaction-screen
git push origin develop

# Xóa branch đã merge (tùy chọn)
git branch -d feature/transaction-screen
git push origin --delete feature/transaction-screen
```

### 3. Quy trình Release

Khi code đã ổn định trên `develop`:

```bash
# Merge develop vào main
git checkout main
git pull origin main
git merge develop
git push origin main

# Tạo tag version
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

## 📋 Checklist trước khi commit

- [ ] Code đã chạy được không có lỗi
- [ ] Đã chạy `flutter analyze` và không có lỗi nghiêm trọng
- [ ] Đã test trên ít nhất 1 platform (mobile/web/desktop)
- [ ] Commit message rõ ràng, tuân thủ convention
- [ ] Không commit file không cần thiết (.DS_Store, build/, .dart_tool/, etc.)

## 🚫 Những gì KHÔNG nên commit

- File build artifacts (`build/`, `.dart_tool/`)
- File cấu hình IDE (`.idea/`, `.vscode/` - trừ khi team đồng ý)
- File tạm, log files
- Dependencies đã có trong `pubspec.yaml` (không commit `pubspec.lock` vào repo chính)

## 🔍 Review Checklist (cho Leader)

- [ ] Code tuân thủ Flutter style guide
- [ ] Không có lỗi lint nghiêm trọng
- [ ] Logic code đúng và hiệu quả
- [ ] UI/UX phù hợp với design
- [ ] Đã test trên nhiều kích thước màn hình
- [ ] Không có hardcode values không cần thiết
- [ ] Comments và documentation đầy đủ (nếu cần)

## 📞 Liên hệ

Nếu có thắc mắc về Git workflow, liên hệ Leader (Chương).
