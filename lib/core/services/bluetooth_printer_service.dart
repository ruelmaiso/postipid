import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../models/app_models.dart';

class BluetoothPrinterService {
  Future<bool> ensurePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final alreadyGranted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
    if (alreadyGranted) {
      return true;
    }

    final status = await Permission.bluetoothConnect.request();
    return status.isGranted;
  }

  Future<List<PairedBluetoothPrinter>> getPairedPrinters() async {
    final hasPermission = await ensurePermission();
    if (!hasPermission) {
      return const [];
    }

    final printers = await PrintBluetoothThermal.pairedBluetooths;
    return printers
        .map(
          (printer) => PairedBluetoothPrinter(
            name: printer.name.trim().isEmpty ? 'Bluetooth Printer' : printer.name,
            address: printer.macAdress,
          ),
        )
        .toList(growable: false);
  }

  Future<void> printText({
    required String printerAddress,
    required String text,
  }) async {
    if (printerAddress.trim().isEmpty) {
      throw Exception('No Bluetooth printer selected');
    }
    if (text.trim().isEmpty) {
      throw Exception('Receipt is empty');
    }

    final hasPermission = await ensurePermission();
    if (!hasPermission) {
      throw Exception('Bluetooth permission was denied');
    }

    final bluetoothEnabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (!bluetoothEnabled) {
      throw Exception('Bluetooth is turned off');
    }

    await PrintBluetoothThermal.disconnect;
    final connected = await PrintBluetoothThermal.connect(
      macPrinterAddress: printerAddress,
    );
    if (!connected) {
      throw Exception('Unable to connect to the selected printer');
    }

    final result = await PrintBluetoothThermal.writeBytes(
      <int>[...text.codeUnits, 10, 10, 10],
    );
    if (!result) {
      throw Exception('Failed to send receipt to printer');
    }
  }
}
