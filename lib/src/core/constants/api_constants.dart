class ApiConstants {
  /// Android emulator: 10.0.2.2. Real device / web: your machine IP (e.g. 192.168.1.x).
  /// Backend chạy port 8080 (xem application.properties). Emulator: 10.0.2.2; máy thật/Win: IP máy hoặc 127.0.0.1.

<<<<<<< HEAD
  static const String baseUrl = 'http://192.168.0.102:8080';
=======
  /// Current backend base URL.
  static const String baseUrl = 'http://192.168.1.9:8080';

  // Alternative hosted backend (if you want to switch to Render):
  // static const String baseUrl = 'https://finance-backend-4m21.onrender.com';
>>>>>>> d8effd672e665def688d8ed8ac820393828df3b3
  static const String categoriesPath = '/api/categories';
  static const String entriesPath = '/api/entries';
  static const String accountsPath = '/api/accounts';
  static const String authPath = '/api/auth';
  static const String ocrReceiptPath = '/api/ocr/receipt';
}
