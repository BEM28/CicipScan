import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImagePreprocessor {
  static const int inputSize = 224;

  static Float32List preprocessImage(File imageFile) {
    final bytes = imageFile.readAsBytesSync();

    final img.Image? decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) {
      throw Exception('Failed to decode image from file.');
    }

    final img.Image resizedImage = img.copyResize(
      decodedImage,
      width: inputSize,
      height: inputSize,
    );

    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int inputIndex = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final img.Pixel pixel = resizedImage.getPixel(x, y);

        buffer[inputIndex++] = pixel.r / 255.0;
        buffer[inputIndex++] = pixel.g / 255.0;
        buffer[inputIndex++] = pixel.b / 255.0;
      }
    }

    return convertedBytes;
  }
}
