import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/utils/receipt_formatter.dart';
import '../../core/widgets/app_frame.dart';
import '../../core/widgets/receipt_preview.dart';
import '../app/app_controller.dart';
import '../manual/manual_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _storeAddressController = TextEditingController();
  final TextEditingController _receiptHeaderController = TextEditingController();
  final TextEditingController _receiptFooterController = TextEditingController();
  final TextEditingController _lowStockController = TextEditingController();

  bool _autoPrint = false;
  bool _soundEnabled = true;
  bool _notificationsEnabled = true;
  bool _seeded = false;
  bool _loadingPrinters = false;
  AppThemePreference _themePreference = AppThemePreference.light;
  ReceiptPaperSize _paperSize = ReceiptPaperSize.mm58;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) {
      return;
    }

    final settings = context.read<TipidPosController>().settings;
    _storeNameController.text = settings.storeName;
    _ownerNameController.text = settings.ownerName;
    _contactNumberController.text = settings.contactNumber;
    _storeAddressController.text = settings.storeAddress;
    _receiptHeaderController.text = settings.receiptHeader;
    _receiptFooterController.text = settings.receiptFooter;
    _lowStockController.text = settings.lowStockThreshold.toString();
    _autoPrint = settings.autoPrintReceipt;
    _soundEnabled = settings.soundEnabled;
    _notificationsEnabled = settings.notificationsEnabled;
    _themePreference = settings.themePreference;
    _paperSize = settings.receiptPaperSize;
    _seeded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPrinters());
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _contactNumberController.dispose();
    _storeAddressController.dispose();
    _receiptHeaderController.dispose();
    _receiptFooterController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TipidPosController>(
      builder: (context, controller, _) {
        final sampleReceipt = _buildSampleReceipt(controller);
        final settings = controller.settings;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            AppResponsiveFrame(
              maxWidth: 1320,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = isWideLayout(constraints.maxWidth);
                  final primaryColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(
                        title: 'Settings',
                        subtitle: 'Finalize store identity, receipt behavior, appearance, printer, and backup controls.',
                        helpMessage:
                            'Save your changes after editing. Theme and printer choices affect the day-to-day experience immediately after saving.',
                      ),
                      const SizedBox(height: 14),
                      _SettingsCard(
                        title: 'Appearance',
                        helpMessage:
                            'Use one theme and paper size across the app so the interface and printed receipt stay consistent.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SettingsRow(
                              label: 'Theme',
                              description: 'Switch the full app look instantly.',
                              control: SegmentedButton<AppThemePreference>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment(
                                    value: AppThemePreference.light,
                                    label: Text('Light'),
                                    icon: Icon(Icons.light_mode_rounded),
                                  ),
                                  ButtonSegment(
                                    value: AppThemePreference.dark,
                                    label: Text('Dark'),
                                    icon: Icon(Icons.dark_mode_rounded),
                                  ),
                                ],
                                selected: {_themePreference},
                                onSelectionChanged: (selection) async {
                                  final value = selection.first;
                                  setState(() => _themePreference = value);
                                  await context
                                      .read<TipidPosController>()
                                      .updateThemePreference(value);
                                },
                              ),
                            ),
                            const Divider(height: 28),
                            Text(
                              'Theme preference applies instantly once selected.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SettingsCard(
                        title: 'Store Profile',
                        helpMessage:
                            'These details appear in the app identity and on printed receipts, so keep them short and correct.',
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final fields = [
                              TextField(
                                controller: _storeNameController,
                                decoration:
                                    const InputDecoration(labelText: 'Store name'),
                              ),
                              TextField(
                                controller: _ownerNameController,
                                decoration:
                                    const InputDecoration(labelText: 'Owner name'),
                              ),
                              TextField(
                                controller: _contactNumberController,
                                decoration: const InputDecoration(
                                    labelText: 'Contact number'),
                              ),
                              TextField(
                                controller: _storeAddressController,
                                decoration:
                                    const InputDecoration(labelText: 'Store address'),
                                minLines: 2,
                                maxLines: 3,
                              ),
                            ];
                            return ResponsiveWrapGrid(
                              minColumns: 1,
                              maxColumns:
                                  isMediumLayout(constraints.maxWidth) ? 2 : 1,
                              children: fields,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SettingsCard(
                        title: 'Receipt',
                        helpMessage:
                            'Use short receipt lines for better thermal printing, especially when you choose 58mm paper.',
                        child: Column(
                          children: [
                            TextField(
                              controller: _receiptHeaderController,
                              decoration: const InputDecoration(
                                  labelText: 'Receipt header'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _receiptFooterController,
                              decoration: const InputDecoration(
                                  labelText: 'Receipt footer'),
                              minLines: 2,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 14),
                            _SettingsRow(
                              label: 'Receipt paper size',
                              description:
                                  'Keep preview and real printer output aligned.',
                              control: AppDropdownChip<ReceiptPaperSize>(
                                value: _paperSize,
                                items: ReceiptPaperSize.values,
                                labelBuilder: _paperLabel,
                                onSelected: (value) async {
                                  setState(() => _paperSize = value);
                                  await context
                                      .read<TipidPosController>()
                                      .updateReceiptPaperSize(value);
                                },
                              ),
                            ),
                            const Divider(height: 18),
                            _SettingsToggleRow(
                              label: 'Auto-print after checkout',
                              description:
                                  'Send the receipt to the paired printer immediately after payment.',
                              value: _autoPrint,
                              onChanged: (value) =>
                                  setState(() => _autoPrint = value),
                            ),
                            const Divider(height: 18),
                            _SettingsRow(
                              label: 'Low stock threshold',
                              description:
                                  'Products at or below this quantity appear in monitoring.',
                              control: SizedBox(
                                width: 96,
                                child: TextField(
                                  controller: _lowStockController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Qty',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: _saveSettings,
                        child: const Text('Save Settings'),
                      ),
                    ],
                  );

                  final secondaryColumn = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SettingsCard(
                        title: 'Printer',
                        helpMessage:
                            'Choose a paired Bluetooth printer so receipt preview and print testing use the same target device.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppInfoChip(
                              label: settings.preferredPrinterName.isEmpty
                                  ? 'No printer selected'
                                  : settings.preferredPrinterName,
                              icon: Icons.print_rounded,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              settings.preferredPrinterAddress.isEmpty
                                  ? 'Choose a paired printer to enable direct receipt printing.'
                                  : settings.preferredPrinterAddress,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                IconButton.filledTonal(
                                  onPressed: _loadingPrinters ? null : _refreshPrinters,
                                  icon: const Icon(Icons.refresh_rounded),
                                ),
                                FilledButton.icon(
                                  onPressed: _showPrinterPicker,
                                  icon: const Icon(Icons.bluetooth_searching_rounded),
                                  label: const Text('Choose Printer'),
                                ),
                                IconButton.filledTonal(
                                  onPressed: () => controller.clearPrinterSelection(),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SettingsCard(
                        title: 'Receipt Preview',
                        helpMessage:
                            'Use this preview to check spacing before printing on the actual thermal paper size you selected.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IgnorePointer(
                              child: ReceiptPaper(
                                receipt: sampleReceipt,
                                paperSize: _paperSize,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await showReceiptPreviewSheet(
                                  context: context,
                                  receipt: sampleReceipt,
                                  paperSize: _paperSize,
                                  title: 'Sample Receipt',
                                  onPrint: () =>
                                      context.read<TipidPosController>().printReceipt(sampleReceipt),
                                );
                              },
                              icon: const Icon(Icons.visibility_rounded),
                              label: const Text('Open Full Preview'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SettingsCard(
                        title: 'Data and Support',
                        helpMessage:
                            'Export a backup before big changes or before publishing to another device. Clear data only when you are certain.',
                        child: ResponsiveWrapGrid(
                          minColumns: 2,
                          maxColumns: 2,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _IconActionButton(
                              icon: Icons.backup_rounded,
                              label: 'Export',
                              onPressed: _exportBackup,
                            ),
                            _IconActionButton(
                              icon: Icons.file_open_rounded,
                              label: 'Import',
                              onPressed: _importBackup,
                            ),
                            _IconActionButton(
                              icon: Icons.menu_book_rounded,
                              label: 'Manual',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ManualScreen(),
                                  ),
                                );
                              },
                            ),
                            _IconActionButton(
                              icon: Icons.delete_sweep_rounded,
                              label: 'Clear',
                              onPressed: _confirmClearData,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: primaryColumn),
                        const SizedBox(width: 16),
                        Expanded(child: secondaryColumn),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      primaryColumn,
                      const SizedBox(height: 14),
                      secondaryColumn,
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _paperLabel(ReceiptPaperSize value) {
    switch (value) {
      case ReceiptPaperSize.mm58:
        return '58mm';
      case ReceiptPaperSize.mm80:
        return '80mm';
    }
  }

  String _buildSampleReceipt(TipidPosController controller) {
    final lowStock =
        int.tryParse(_lowStockController.text.trim()) ?? controller.settings.lowStockThreshold;
    final settings = AppSettingsModel(
      storeName: _storeNameController.text.trim().isEmpty
          ? 'TipidPOS'
          : _storeNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      contactNumber: _contactNumberController.text.trim(),
      storeAddress: _storeAddressController.text.trim(),
      receiptHeader: _receiptHeaderController.text.trim(),
      receiptFooter: _receiptFooterController.text.trim(),
      lowStockThreshold: lowStock.clamp(1, 50).toInt(),
      autoPrintReceipt: _autoPrint,
      preferredPrinterName: controller.settings.preferredPrinterName,
      preferredPrinterAddress: controller.settings.preferredPrinterAddress,
      soundEnabled: _soundEnabled,
      notificationsEnabled: _notificationsEnabled,
      themePreference: _themePreference,
      receiptPaperSize: _paperSize,
      introSeen: controller.settings.introSeen,
    );

    const transaction = TransactionModel(
      transactionId: 1052,
      customerName: 'Sample Customer',
      status: 'PAID',
      createdAt: 1738742400000,
      totalAmount: 104,
      totalCost: 74,
      totalProfit: 30,
      paymentType: 'Cash',
      cashReceived: 120,
      changeAmount: 16,
    );

    const items = [
      TransactionItemModel(
        transactionId: 1052,
        itemId: 1,
        itemName: 'Sardines',
        quantity: 2,
        price: 24,
        cost: 16,
        subtotal: 48,
        costSubtotal: 32,
      ),
      TransactionItemModel(
        transactionId: 1052,
        itemId: 2,
        itemName: '3-in-1 Coffee',
        quantity: 2,
        price: 18,
        cost: 11,
        subtotal: 36,
        costSubtotal: 22,
      ),
      TransactionItemModel(
        transactionId: 1052,
        itemId: 3,
        itemName: 'Bath Soap',
        quantity: 1,
        price: 20,
        cost: 20,
        subtotal: 20,
        costSubtotal: 20,
      ),
    ];

    return ReceiptFormatter.format(settings, transaction, items);
  }

  Future<void> _refreshPrinters() async {
    setState(() => _loadingPrinters = true);
    await context.read<TipidPosController>().refreshPairedPrinters();
    if (mounted) {
      setState(() => _loadingPrinters = false);
    }
  }

  Future<void> _showPrinterPicker() async {
    final controller = context.read<TipidPosController>();
    if (controller.pairedPrinters.isEmpty) {
      await _refreshPrinters();
    }
    if (!mounted) {
      return;
    }
    if (controller.pairedPrinters.isEmpty) {
      controller.showMessage('No paired Bluetooth printers found');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text('Choose Printer', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...controller.pairedPrinters.map(
              (printer) => ListTile(
                title: Text(printer.name),
                subtitle: Text(printer.address),
                onTap: () async {
                  await controller.selectPrinter(printer);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportBackup() async {
    final directory = await FilePicker.platform.getDirectoryPath();
    if (directory == null || !mounted) {
      return;
    }
    await context.read<TipidPosController>().exportBackup(directory);
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) {
      return;
    }
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import backup?'),
        content: const Text('Importing a backup will replace the current data on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (shouldImport == true && mounted) {
      await context.read<TipidPosController>().importBackup(path);
    }
  }

  Future<void> _confirmClearData() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This will remove all items, transactions, credits, and logs from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (shouldClear == true && mounted) {
      await context.read<TipidPosController>().clearAllData();
    }
  }

  Future<void> _saveSettings() async {
    final controller = context.read<TipidPosController>();
    final lowStock =
        int.tryParse(_lowStockController.text.trim()) ?? controller.settings.lowStockThreshold;
    final settings = AppSettingsModel(
      storeName: _storeNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      contactNumber: _contactNumberController.text.trim(),
      storeAddress: _storeAddressController.text.trim(),
      receiptHeader: _receiptHeaderController.text.trim(),
      receiptFooter: _receiptFooterController.text.trim(),
      lowStockThreshold: lowStock.clamp(1, 50).toInt(),
      autoPrintReceipt: _autoPrint,
      preferredPrinterName: controller.settings.preferredPrinterName,
      preferredPrinterAddress: controller.settings.preferredPrinterAddress,
      soundEnabled: _soundEnabled,
      notificationsEnabled: _notificationsEnabled,
      themePreference: _themePreference,
      receiptPaperSize: _paperSize,
      introSeen: controller.settings.introSeen,
    );
    await controller.saveSettings(settings);
    controller.showMessage('Settings saved');
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.helpMessage,
    required this.child,
  });

  final String title;
  final String helpMessage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: title,
            helpMessage: helpMessage,
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.description,
    required this.control,
  });

  final String label;
  final String description;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              control,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(child: control),
          ],
        );
      },
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      label: label,
      description: description,
      control: Switch.adaptive(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
      ),
    );
  }
}
