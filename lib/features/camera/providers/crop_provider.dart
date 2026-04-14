import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:crop_image/crop_image.dart';
import 'package:path_provider/path_provider.dart';

/// Provider for handling image cropping logic.
///
/// Manages the [CropController] and transitions the
/// image from raw file to a cropped version.
class CropProvider with ChangeNotifier {
  final CropController controller = CropController(aspectRatio: 4.0 / 3.0);
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;

  /// Crops the image using the current controller state.
  ///
  /// Returns the [File] of the cropped image, or null if failed.
  Future<File?> cropImage() async {
    if (_isProcessing) return null;

    _isProcessing = true;
    notifyListeners();

    try {
      // Get the bitmap from controller
      final ui.Image bitmap = await controller.croppedBitmap();
      final byteData = await bitmap.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to generate bitmap from crop.');
      }

      final bytes = byteData.buffer.asUint8List();

      // Save to temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath =
          '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png';
      final File croppedFile = File(tempPath);
      await croppedFile.writeAsBytes(bytes);

      return croppedFile;
    } catch (e) {
      debugPrint('Crop Error: $e');
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
