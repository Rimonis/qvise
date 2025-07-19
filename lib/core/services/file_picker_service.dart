// lib/core/services/file_picker_service.dart
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

enum FileSource { camera, gallery, files }

class FilePickerService {
  final ImagePicker _imagePicker = ImagePicker();

  Future<String?> pickFile(FileSource source) async {
    switch (source) {
      case FileSource.camera:
        final XFile? photo = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
        return photo?.path;
      case FileSource.gallery:
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
        return image?.path;
      case FileSource.files:
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: [
            'pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt',
            'jpg', 'jpeg', 'png', 'gif', 'webp'
          ],
          allowMultiple: false,
        );
        return result?.files.single.path;
    }
  }

  Future<List<String>> pickMultipleFiles(FileSource source) async {
    switch (source) {
      case FileSource.camera:
        // Camera can only take one photo at a time
        final path = await pickFile(source);
        return path != null ? [path] : [];
      case FileSource.gallery:
        final List<XFile> images = await _imagePicker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
        return images.map((image) => image.path).toList();
      case FileSource.files:
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: [
            'pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt',
            'jpg', 'jpeg', 'png', 'gif', 'webp'
          ],
          allowMultiple: true,
        );
        return result?.files
            .where((file) => file.path != null)
            .map((file) => file.path!)
            .toList() ?? [];
    }
  }
}