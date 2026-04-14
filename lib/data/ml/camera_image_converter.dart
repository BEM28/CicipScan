import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

img.Image? convertCameraImage(CameraImage image) {
  try {
    if (image.format.group == ImageFormatGroup.yuv420) {
      return _convertYUV420(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888(image);
    }
    return null;
  } catch (e) {
    return null;
  }
}

img.Image _convertBGRA8888(CameraImage image) {
  return img.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: image.planes[0].bytes.buffer,
    order: img.ChannelOrder.bgra,
  );
}

img.Image _convertYUV420(CameraImage image) {
  final width = image.width;
  final height = image.height;

  final uvRowStride = image.planes[1].bytesPerRow;
  final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

  final imageOut = img.Image(width: width, height: height);

  for (int y = 0; y < height; y++) {
    int pY = y * image.planes[0].bytesPerRow;
    int pUV = (y >> 1) * uvRowStride;

    for (int x = 0; x < width; x++) {
      int uvOffset = pUV + (x >> 1) * uvPixelStride;

      final yValue = image.planes[0].bytes[pY + x];
      final uValue = image.planes[1].bytes[uvOffset];
      final vValue = image.planes[2].bytes[uvOffset];

      int r = (yValue + 1.402 * (vValue - 128)).toInt();
      int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
          .toInt();
      int b = (yValue + 1.772 * (uValue - 128)).toInt();

      imageOut.setPixelRgb(
        x,
        y,
        r.clamp(0, 255),
        g.clamp(0, 255),
        b.clamp(0, 255),
      );
    }
  }
  return imageOut;
}
