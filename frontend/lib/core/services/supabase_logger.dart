import 'package:flutter/material.dart';
import '../../main.dart';

class SupabaseLogger {
  static void log(bool isEnabled, String operation, {bool success = true, String? error}) {
    if (!isEnabled) return;

    final color = success ? Colors.greenAccent : Colors.redAccent;
    final message = success 
        ? '[SUPABASE] $operation: SUCCESS' 
        : '[SUPABASE] $operation: FAILED - $error';

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        backgroundColor: color.withOpacity(0.9),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
