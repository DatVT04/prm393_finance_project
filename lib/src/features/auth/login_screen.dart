import 'package:flutter/material.dart';
import '../../layout/main_layout.dart';
import 'register_screen.dart';

/// Màn hình đăng nhập của ứng dụng
/// Hiển thị form đăng nhập với email và mật khẩu
/// Tài khoản cố định: chuongbui.bdc@gmail.com / 12345
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// State class quản lý trạng thái và logic của màn hình đăng nhập
class _LoginScreenState extends State<LoginScreen> {
  // Controller để quản lý input email
  final _emailController = TextEditingController();

  // Controller để quản lý input mật khẩu
  final _passwordController = TextEditingController();

  // Biến trạng thái để hiển thị loading khi đang xử lý đăng nhập
  bool _isLoading = false;

  /// Hàm xử lý sự kiện đăng nhập khi người dùng nhấn nút "Đăng nhập"
  ///
  /// Quy trình:
  /// 1. Ẩn bàn phím
  /// 2. Lấy và validate dữ liệu từ các trường input
  /// 3. Kiểm tra email và mật khẩu có đúng với tài khoản cố định không
  /// 4. Hiển thị loading indicator
  /// 5. Mô phỏng delay xử lý (giống như gọi API)
  /// 6. Điều hướng đến MainLayout nếu đăng nhập thành công
  void _handleLogin() async {
    // Ẩn bàn phím khi người dùng nhấn đăng nhập
    FocusScope.of(context).unfocus();

    // Lấy giá trị từ các trường input và loại bỏ khoảng trắng thừa
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Kiểm tra các trường có được điền đầy đủ không
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập email và mật khẩu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra email và mật khẩu có khớp với tài khoản cố định không
    // Tài khoản: chuongbui.bdc@gmail.com / Mật khẩu: 12345
    if (email != 'chuongbui.bdc@gmail.com' || password != '12345') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email hoặc mật khẩu không đúng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Hiển thị trạng thái loading
    setState(() {
      _isLoading = true;
    });

    // Mô phỏng delay xử lý (giống như gọi API thật)
    await Future.delayed(const Duration(milliseconds: 1500));

    // Kiểm tra widget còn được mount không (tránh lỗi khi widget đã bị dispose)
    if (!mounted) return;

    // Tắt trạng thái loading
    setState(() {
      _isLoading = false;
    });

    // Điều hướng đến MainLayout và xóa tất cả các route trước đó
    // Điều này đảm bảo người dùng không thể quay lại màn hình login bằng nút back
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainLayout()),
      (route) => false,
    );
  }

  /// Hàm build xây dựng giao diện người dùng của màn hình đăng nhập
  ///
  /// Cấu trúc UI:
  /// - Logo/Icon ở đầu trang
  /// - Tiêu đề và mô tả
  /// - Trường nhập email
  /// - Trường nhập mật khẩu
  /// - Nút đăng nhập (hiển thị loading khi đang xử lý)
  /// - Link chuyển đến màn hình đăng ký
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // SingleChildScrollView để có thể scroll khi bàn phím hiện lên
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // Logo/Icon của ứng dụng - hiển thị icon ví tiền
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 50,
                    color: Colors.teal,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Tiêu đề chào mừng
              Text(
                'Chào mừng trở lại!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Mô tả ngắn gọn về màn hình
              Text(
                'Đăng nhập để quản lý tài chính của bạn',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Trường nhập email
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              // Trường nhập mật khẩu (ẩn ký tự)
              TextField(
                controller: _passwordController,
                obscureText: true, // Ẩn ký tự khi nhập
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Nút đăng nhập
              // Hiển thị CircularProgressIndicator khi đang loading
              // Disable nút khi đang xử lý để tránh nhấn nhiều lần
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Link chuyển đến màn hình đăng ký
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Chưa có tài khoản? ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  // Nút chuyển đến màn hình đăng ký
                  TextButton(
                    onPressed: () {
                      // Điều hướng đến RegisterScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Đăng ký ngay',
                      style: TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
