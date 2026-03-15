class ApiConstants {
  /// Android emulator: 10.0.2.2. Real device / web: your machine IP (e.g. 192.168.1.x).
  /// Backend chạy port 8081 (xem application.properties). Emulator: 10.0.2.2; máy thật/Win: IP máy hoặc 127.0.0.1.
  static const String baseUrl = 'http://192.168.120.10:8080';
  static const String categoriesPath = '/api/categories';
  static const String entriesPath = '/api/entries';
  static const String accountsPath = '/api/accounts';
  static const String authPath = '/api/auth';

  /// Web Client ID (OAuth 2.0) từ Google Cloud Console. Để tắt Đăng nhập Google, đặt chuỗi rỗng ''.
  static const String googleWebClientId = '529213434141-h5plko9q9tekp6sa87ah4lqqsdglascq.apps.googleusercontent.com';
