import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void queue(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    if (kDebugMode) {
      final contextText = context.entries
          .where((entry) => entry.value != null)
          .map((entry) => '${entry.key}=${entry.value}')
          .join(' ');
      debugPrint(
        '[queue] $message${contextText.isEmpty ? '' : ' $contextText'}',
      );
      if (error != null) debugPrint('[queue] error=$error');
      if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
      return;
    }

    if (error != null) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'AntriMedis queue',
          context: ErrorDescription(message),
          informationCollector: context.isEmpty
              ? null
              : () => context.entries.map(
                  (entry) =>
                      DiagnosticsProperty<Object?>(entry.key, entry.value),
                ),
        ),
      );
    }
  }
}
