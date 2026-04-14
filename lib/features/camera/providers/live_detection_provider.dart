import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'package:cicipscan/data/ml/camera_image_converter.dart';
import 'package:cicipscan/data/ml/ml_service.dart';
import 'package:cicipscan/data/services/camera_service.dart';

/// Provider for live camera detection using TFLite.
///
/// Manages camera lifecycle, live image stream,
/// and real-time ML inference on camera frames.
class LiveDetectionProvider with ChangeNotifier {
  final CameraService _cameraService = CameraService();
  final MLService _mlService = MLService();

  bool _isInitialized = false;
  bool _isDetecting = false;
  String _liveResult = 'Point at food...';
  double _liveConfidence = 0.0;
  String? _error;

  bool get isInitialized => _isInitialized;
  String get liveResult => _liveResult;
  double get liveConfidence => _liveConfidence;
  String? get error => _error;
  CameraController? get controller => _cameraService.controller;

  /// Initializes camera + loads ML model & labels.
  Future<void> initialize() async {
    try {
      await _cameraService.initialize();
      await _mlService.init();

      _isInitialized = true;
      _error = null;
      notifyListeners();

      _startImageStream();
    } catch (e) {
      debugPrint('LiveDetection init error: $e');
      _error = 'Failed to initialize: $e';
      notifyListeners();
    }
  }

  int _lastFrameTime = 0;

  /// Starts the camera image stream for live
  /// detection.
  void _startImageStream() {
    _cameraService.controller?.startImageStream((
      CameraImage cameraImage,
    ) async {
      if (_isDetecting) return;

      // Limit processing to 1 frame every 400ms to ensure the camera UI stays smooth
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime - _lastFrameTime < 400) return;

      _isDetecting = true;
      _lastFrameTime = currentTime;

      try {
        // Run asynchronously so we don't completely lock the main thread for too long
        await Future.delayed(Duration.zero);
        _processFrame(cameraImage);
      } catch (_) {
        // Silently handle frame errors
      } finally {
        _isDetecting = false;
      }
    });
  }

  /// Converts a CameraImage frame, preprocesses it,
  /// and runs TFLite inference directly.
  void _processFrame(CameraImage cameraImage) {
    final img.Image? converted = convertCameraImage(cameraImage);
    if (converted == null) return;

    try {
      final result = _mlService.runInferenceOnImage(converted);

      // Directly update the label without enforcing a confidence threshold.
      _liveResult = result.label;
      _liveConfidence = result.confidence;
      notifyListeners();
    } catch (e) {
      debugPrint('Live frame error: $e');
    }
  }

  /// Switches between front and back camera.
  Future<void> switchCamera() async {
    try {
      if (_cameraService.controller?.value.isStreamingImages ?? false) {
        await _cameraService.controller?.stopImageStream();
      }
    } catch (_) {}

    _isInitialized = false;
    notifyListeners();

    await _cameraService.switchCamera();

    _isInitialized = true;
    notifyListeners();

    _startImageStream();
  }

  /// Stops the image stream and takes a still photo.
  Future<File?> capturePhoto() async {
    try {
      if (_cameraService.controller?.value.isStreamingImages ?? false) {
        await _cameraService.controller?.stopImageStream();
      }
    } catch (_) {}

    final xFile = await _cameraService.takePicture();
    if (xFile != null) {
      return File(xFile.path);
    }
    return null;
  }

  @override
  void dispose() {
    try {
      if (_cameraService.controller?.value.isStreamingImages ?? false) {
        _cameraService.controller?.stopImageStream();
      }
    } catch (_) {}
    _cameraService.dispose();
    _mlService.dispose();
    super.dispose();
  }
}
