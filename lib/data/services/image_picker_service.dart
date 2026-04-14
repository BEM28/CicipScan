import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage(ImageSource source) async {
    try {
      return await _picker.pickImage(source: source);
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }
}
