import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImageFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    return picked?.path;
  }
}
