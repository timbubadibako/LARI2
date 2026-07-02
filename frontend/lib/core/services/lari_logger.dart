import 'package:flutter/material.dart';
import '../../main.dart';

class LogEntry {
  final String timestamp;
  final String operation;
  final bool success;
  final String? error;

  LogEntry({
    required this.timestamp,
    required this.operation,
    required this.success,
    this.error,
  });

  @override
  String toString() => '[$timestamp] $operation: ${success ? 'SUCCESS' : 'FAILED - $error'}';
}

class LariLogger {
  static final List<LogEntry> _logs = [];
  static List<LogEntry> get logs => List.unmodifiable(_logs);

  static void log(bool isEnabled, String operation, {bool success = true, String? error}) {
    final entry = LogEntry(
      timestamp: DateTime.now().toCloserString(),
      operation: operation,
      success: success,
      error: error,
    );
    _logs.add(entry);
    if (_logs.length > 100) _logs.removeAt(0); // Keep last 100 logs

    if (!isEnabled) return;

    final color = success ? Colors.greenAccent : Colors.redAccent;
    final message = success 
        ? '[LARI2] $operation: SUCCESS' 
        : '[LARI2] $operation: FAILED - $error';

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        backgroundColor: color.withValues(alpha: 0.9),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void clearLogs() {
    _logs.clear();
  }
}

extension DateTimeX on DateTime {
  String toCloserString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  }
}
