import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualController = TextEditingController();
  bool _handled = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    final value =
                        capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
                    if (value != null) {
                      _submit(value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualController,
              decoration: const InputDecoration(
                labelText: 'Manual barcode entry',
                hintText: 'Enter or paste barcode',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _submit(_manualController.text),
                    child: const Text('Use Barcode'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit(String barcode) {
    final normalized = barcode.trim();
    if (_handled || normalized.isEmpty) {
      return;
    }
    _handled = true;
    Navigator.of(context).pop(normalized);
  }
}
