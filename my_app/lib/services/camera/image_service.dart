import 'package:image_picker/image_picker.dart';

/// Handles image acquisition from the camera and gallery.
class ImageService {
  const ImageService(this._picker);

  final ImagePicker _picker;

  Future<XFile?> pickFromGallery() async {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 95,
    );
  }

  Future<XFile?> takePhoto() async {
    return _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 95,
    );
  }
}
