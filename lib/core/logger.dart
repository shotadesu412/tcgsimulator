import 'package:flutter/foundation.dart';

// T03: ロガー・例外ハンドラ

enum LogLevel { debug, info, warning, error }

class AppLogger {
  AppLogger._();

  static void init() {
    // 初期化フック（将来の拡張用）
  }

  static void d(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.debug, message, error: error, stackTrace: stackTrace);

  static void i(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.info, message, error: error, stackTrace: stackTrace);

  static void w(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.warning, message, error: error, stackTrace: stackTrace);

  static void e(String message, {Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.error, message, error: error, stackTrace: stackTrace);

  static void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode && level == LogLevel.debug) return;

    final prefix = switch (level) {
      LogLevel.debug => '[D]',
      LogLevel.info => '[I]',
      LogLevel.warning => '[W]',
      LogLevel.error => '[E]',
    };

    debugPrint('$prefix $message');
    if (error != null) debugPrint('  error: $error');
    if (stackTrace != null && kDebugMode) debugPrint('  $stackTrace');
  }
}

class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException: $message${cause != null ? ' (cause: $cause)' : ''}';
}
