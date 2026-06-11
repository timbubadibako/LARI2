import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

final shareServiceProvider = Provider((ref) => ShareService());

class ShareService {
  /// Captures a RepaintBoundary widget as a PNG image byte array.
  Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Adjust pixel ratio for high-quality export
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget: $e');
      return null;
    }
  }

  /// Requests necessary permissions and saves the image to the gallery.
  Future<bool> saveToGallery(
    Uint8List imageBytes, {
    bool isTransparent = false,
  }) async {
    try {
      // For saving we can just rely on Gal
      await Gal.putImageBytes(
        imageBytes,
        name: 'lari_lari_run_${DateTime.now().millisecondsSinceEpoch}',
      );
      return true;
    } catch (e) {
      debugPrint('Error saving to gallery: $e');
      return false;
    }
  }

  /// Shares the image via native share dialog (Instagram, Facebook, WA, etc.)
  Future<void> shareImage(Uint8List imageBytes, {String text = ''}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/lari_lari_share.png').create();
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles([XFile(file.path)], text: text);
    } catch (e) {
      debugPrint('Error sharing image: $e');
    }
  }

  /// Copies a text summary to clipboard
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
