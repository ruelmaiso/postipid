import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'core/repository/pos_repository.dart';
import 'core/services/backup_service.dart';
import 'core/services/bluetooth_printer_service.dart';
import 'core/services/image_storage_service.dart';
import 'core/services/local_database_service.dart';
import 'core/services/settings_service.dart';
import 'features/app/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databaseService = LocalDatabaseService();
  final repository = await PosRepository.create(databaseService);
  final settingsService = SettingsService();
  final imageStorageService = await ImageStorageService.create();
  final bluetoothPrinterService = BluetoothPrinterService();
  final backupService = BackupService(
    repository: repository,
    settingsService: settingsService,
    imageStorageService: imageStorageService,
  );

  final controller = TipidPosController(
    repository: repository,
    settingsService: settingsService,
    imageStorageService: imageStorageService,
    bluetoothPrinterService: bluetoothPrinterService,
    backupService: backupService,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<PosRepository>.value(value: repository),
        Provider<SettingsService>.value(value: settingsService),
        Provider<ImageStorageService>.value(value: imageStorageService),
        Provider<BluetoothPrinterService>.value(value: bluetoothPrinterService),
        Provider<BackupService>.value(value: backupService),
        ChangeNotifierProvider<TipidPosController>.value(value: controller),
      ],
      child: const TipidPosApp(),
    ),
  );

  unawaited(controller.bootstrap());
}
