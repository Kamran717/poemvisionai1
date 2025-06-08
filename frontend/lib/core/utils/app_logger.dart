import 'package:logger/logger.dart';

/// A utility class for logging messages throughout the app
class AppLogger {
  // Private constructor to prevent instantiation
  AppLogger._();
  
  // Logger instance
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );
  
  // Whether debug logs should be printed
  static bool _debugLogsEnabled = true;
  
  /// Enable or disable debug logs
  static void setDebugLogsEnabled(bool enabled) {
    _debugLogsEnabled = enabled;
  }
  
  /// Log a debug message
  static void d(String message) {
    if (_debugLogsEnabled) {
      _logger.d(message);
    }
  }
  
  /// Log an info message
  static void i(String message) {
    _logger.i(message);
  }
  
  /// Log a warning message
  static void w(String message) {
    _logger.w(message);
  }
  
  /// Log an error message with optional error object and stack trace
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log a verbose message
  static void v(String message) {
    if (_debugLogsEnabled) {
      _logger.v(message);
    }
  }
  
  /// Log a wtf message (What a Terrible Failure)
  static void wtf(String message) {
    _logger.f(message);
  }
}
