import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../models/app_models.dart';
import '../repository/pos_repository.dart';
import 'image_storage_service.dart';
import 'settings_service.dart';

class BackupService {
  BackupService({
    required PosRepository repository,
    required SettingsService settingsService,
    required ImageStorageService imageStorageService,
  })  : _repository = repository,
        _settingsService = settingsService,
        _imageStorageService = imageStorageService;

  final PosRepository _repository;
  final SettingsService _settingsService;
  final ImageStorageService _imageStorageService;

  Future<BackupSummary> exportToDirectory(String directoryPath) async {
    final items = await _repository.getAllItems();
    final transactions = await _repository.getAllTransactions();
    final transactionItems = await _repository.getAllTransactionItems();
    final inventoryLogs = await _repository.getAllInventoryLogs();
    final settings = await _settingsService.load();

    final images = <Map<String, Object?>>[];
    var imageCount = 0;
    for (final item in items) {
      final imagePath = await _imageStorageService.existingImagePath(item.itemId);
      if (imagePath != null) {
        final bytes = await File(imagePath).readAsBytes();
        images.add({
          'itemId': item.itemId,
          'base64': base64Encode(bytes),
        });
        imageCount++;
      }
    }

    final backupFile = File(
      path.join(
        directoryPath,
        'tipidpos-backup-${DateTime.now().millisecondsSinceEpoch}.json',
      ),
    );

    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'settings': settings.toMap(),
      'items': items.map((item) => item.toMap()).toList(growable: false),
      'transactions': transactions.map((item) => item.toMap()).toList(growable: false),
      'transactionItems': transactionItems.map((item) => item.toMap()).toList(growable: false),
      'inventoryLogs': inventoryLogs.map((item) => item.toMap()).toList(growable: false),
      'images': images,
    };

    await backupFile.writeAsString(jsonEncode(payload));

    return BackupSummary(
      itemCount: items.length,
      transactionCount: transactions.length,
      transactionItemCount: transactionItems.length,
      inventoryLogCount: inventoryLogs.length,
      imageCount: imageCount,
    );
  }

  Future<BackupSummary> importFromFile(String filePath) async {
    final root = jsonDecode(await File(filePath).readAsString()) as Map<String, dynamic>;
    if ((root['version'] as num?)?.toInt() != 1) {
      throw Exception('Unsupported backup version.');
    }

    final items = (root['items'] as List<dynamic>? ?? const [])
        .map((entry) => ItemModel.fromMap(Map<String, Object?>.from(entry as Map)))
        .toList(growable: false);
    final transactions = (root['transactions'] as List<dynamic>? ?? const [])
        .map((entry) => TransactionModel.fromMap(Map<String, Object?>.from(entry as Map)))
        .toList(growable: false);
    final transactionItems = (root['transactionItems'] as List<dynamic>? ?? const [])
        .map((entry) => TransactionItemModel.fromMap(Map<String, Object?>.from(entry as Map)))
        .toList(growable: false);
    final inventoryLogs = (root['inventoryLogs'] as List<dynamic>? ?? const [])
        .map((entry) => InventoryLogModel.fromMap(Map<String, Object?>.from(entry as Map)))
        .toList(growable: false);
    final settings = AppSettingsModel.fromMap(
      Map<Object?, Object?>.from(root['settings'] as Map? ?? const {}),
    );
    final images = (root['images'] as List<dynamic>? ?? const []);

    await _repository.replaceAllData(
      items: items,
      transactions: transactions,
      transactionItems: transactionItems,
      inventoryLogs: inventoryLogs,
    );
    await _settingsService.save(settings);
    await _imageStorageService.clearAllImages();

    var restoredImageCount = 0;
    for (final image in images) {
      final map = Map<Object?, Object?>.from(image as Map);
      final itemId = (map['itemId'] as num?)?.toInt() ?? 0;
      final base64Value = map['base64'] as String? ?? '';
      if (itemId > 0 && base64Value.isNotEmpty) {
        final file = File(_imageStorageService.imagePathFor(itemId));
        await file.writeAsBytes(base64Decode(base64Value));
        restoredImageCount++;
      }
    }

    return BackupSummary(
      itemCount: items.length,
      transactionCount: transactions.length,
      transactionItemCount: transactionItems.length,
      inventoryLogCount: inventoryLogs.length,
      imageCount: restoredImageCount,
    );
  }
}
