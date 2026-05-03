import 'dart:io';
import 'dart:ui';
import 'package:image_cropper/image_cropper.dart';

class ImageEditorService {
  static final ImageCropper _cropper = ImageCropper();

  static Future<File?> editImage(File imageFile) async {
    try {
      final CroppedFile? croppedFile = await _cropper.cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Редактор',
            toolbarColor: const Color(0xFF673AB7), // Deep Purple
            toolbarWidgetColor: const Color(0xFFFFFFFF),
          ),
          IOSUiSettings(
            title: 'Редактор',
          ),
        ],
      );
      if (croppedFile != null) {
        return File(croppedFile.path);
      }
    } catch (_) {
      // редактор не поддерживается или отменён
    }
    return null;
  }
}