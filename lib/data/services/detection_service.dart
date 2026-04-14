import 'dart:io';

class DetectionService {
  Future<String> detectFood(File image) async {
    await Future.delayed(const Duration(seconds: 2));
    return "Detected: Pizza (Confidence: 95%)";
  }
}
