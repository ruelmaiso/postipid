import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  ImageStorageService._(this._directory);

  final Directory _directory;

  static Future<ImageStorageService> create() async {
    final baseDirectory = await getApplicationSupportDirectory();
    final directory = Directory(path.join(baseDirectory.path, 'item_images'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return ImageStorageService._(directory);
  }

  String imagePathFor(int itemId) => path.join(_directory.path, 'item_$itemId.jpg');

  Future<String?> existingImagePath(int itemId) async {
    final file = File(imagePathFor(itemId));
    return file.existsSync() ? file.path : null;
  }

  Future<void> saveImageForItem(int itemId, String sourcePath) async {
    final source = File(sourcePath);
    if (!source.existsSync()) {
      return;
    }

    final target = File(imagePathFor(itemId));
    await source.copy(target.path);
  }

  Future<void> deleteImageForItem(int itemId) async {
    final file = File(imagePathFor(itemId));
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> clearAllImages() async {
    if (!await _directory.exists()) {
      return;
    }

    for (final entity in _directory.listSync()) {
      if (entity is File) {
        await entity.delete();
      }
    }
  }
}
