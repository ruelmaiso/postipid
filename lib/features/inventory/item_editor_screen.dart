import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/utils/formatters.dart';
import '../app/app_controller.dart';
import '../scanner/barcode_scanner_screen.dart';

class ItemEditorScreen extends StatefulWidget {
  const ItemEditorScreen({super.key, this.itemId});

  final int? itemId;

  @override
  State<ItemEditorScreen> createState() => _ItemEditorScreenState();
}

class _ItemEditorScreenState extends State<ItemEditorScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  ItemModel? _currentItem;
  String _category = InventoryCategories.food;
  String? _imagePath;
  bool _removePhoto = false;
  bool _loading = true;
  bool _saving = false;
  bool _priceOverridden = false;
  bool _applyingSuggestedPrice = false;
  PriceSuggestionUiState _suggestion = const PriceSuggestionUiState();

  bool get _isEditing => widget.itemId != null;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => _refreshSuggestion(allowAutoFill: !_priceOverridden));
    _costController.addListener(() => _refreshSuggestion(allowAutoFill: !_priceOverridden));
    _priceController.addListener(() {
      if (_applyingSuggestedPrice) {
        return;
      }
      _priceOverridden = true;
      _refreshSuggestion(allowAutoFill: false);
    });
    _load();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TipidPosController>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Item' : 'Add Item'),
        actions: [
          if (_isEditing && _currentItem != null)
            IconButton(
              onPressed: _toggleStatus,
              icon: Icon(_currentItem!.isActive ? Icons.block_rounded : Icons.check_circle_rounded),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _EditorSection(
                  title: 'Barcode',
                  child: TextField(
                    controller: _barcodeController,
                    decoration: InputDecoration(
                      labelText: _isEditing
                          ? 'Barcode'
                          : 'Leave blank to auto-generate',
                      suffixIcon: IconButton(
                        onPressed: _scanBarcode,
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _EditorSection(
                  title: 'Item Photo',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: const Color(0xFFE8F1EE),
                          image: _imagePath != null
                              ? DecorationImage(
                                  image: FileImage(File(_imagePath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _imagePath == null
                            ? const Center(
                                child: Icon(Icons.add_a_photo_rounded, size: 42, color: Colors.black54),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickImage(ImageSource.camera),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(42),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              child: const Text('Camera'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(42),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              child: const Text('Gallery'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() {
                                _imagePath = null;
                                _removePhoto = true;
                              }),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(42),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              child: const Text('Remove'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _EditorSection(
                  title: 'Product Details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Item name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _costController,
                        decoration: const InputDecoration(labelText: 'Cost'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      if (_isEditing)
                        Text(
                          'Current stock: ${_currentItem?.stock ?? 0}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        )
                      else
                        TextField(
                          controller: _stockController,
                          decoration: const InputDecoration(labelText: 'Stock'),
                          keyboardType: TextInputType.number,
                        ),
                      const SizedBox(height: 14),
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: InventoryCategories.food, label: Text('Food')),
                          ButtonSegment(value: InventoryCategories.nonFood, label: Text('Non-food')),
                        ],
                        selected: {_category},
                        onSelectionChanged: (selection) => setState(() => _category = selection.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _EditorSection(
                  title: 'Smart Price Suggestion',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _suggestion.hasSuggestion
                            ? toPeso(_suggestion.suggestedPrice)
                            : 'Waiting for item name and cost',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _suggestion.hasSuggestion
                            ? _suggestion.source == PriceSuggestionSource.existingAverage
                                ? 'Based on average price of an existing matching item'
                                : 'Based on 20% markup from item cost'
                            : 'Enter item name and cost to generate a suggestion.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Profit: ${toPeso(_suggestion.profit)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _saving ? null : () => _save(controller),
                  child: Text(_saving ? 'Saving...' : _isEditing ? 'Save Changes' : 'Save Item'),
                ),
              ],
            ),
    );
  }

  Future<void> _load() async {
    if (!_isEditing) {
      setState(() => _loading = false);
      return;
    }

    final controller = context.read<TipidPosController>();
    final item = await controller.getItemById(widget.itemId!);
    final imagePath = await controller.imagePathForItem(widget.itemId!);
    if (!mounted || item == null) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    _currentItem = item;
    _barcodeController.text = item.barcode;
    _nameController.text = item.name;
    _costController.text = item.cost.toString();
    _priceController.text = item.price.toString();
    _category = InventoryCategories.normalize(item.category);
    _imagePath = imagePath;
    _loading = false;
    _priceOverridden = false;
    setState(() {});
    await _refreshSuggestion(allowAutoFill: true);
  }

  Future<void> _refreshSuggestion({required bool allowAutoFill}) async {
    final controller = context.read<TipidPosController>();
    final suggestion = await controller.computePriceSuggestion(
      itemName: _nameController.text,
      costText: _costController.text,
      currentPriceText: _priceController.text,
      allowAutoFillPrice: allowAutoFill,
    );
    if (!mounted) {
      return;
    }
    setState(() => _suggestion = suggestion);
    if (suggestion.hasSuggestion && allowAutoFill) {
      final textValue = suggestion.appliedPrice.toInt().toString();
      if (_priceController.text != textValue) {
        _applyingSuggestedPrice = true;
        _priceController.text = textValue;
        _priceController.selection = TextSelection.collapsed(offset: textValue.length);
        _applyingSuggestedPrice = false;
      }
    }
  }

  Future<void> _scanBarcode() async {
    final navigator = Navigator.of(context);
    final controller = context.read<TipidPosController>();
    final barcode = await navigator.push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (!mounted || barcode == null || barcode.trim().isEmpty) {
      return;
    }
    _barcodeController.text = barcode;
    final found = await controller.getItemByBarcode(barcode);
    if (!mounted || _isEditing || found == null) {
      return;
    }
    _nameController.text = found.name;
    _costController.text = found.cost.toString();
    _priceController.text = found.price.toString();
    _category = InventoryCategories.normalize(found.category);
    final imagePath = await controller.imagePathForItem(found.itemId);
    if (!mounted) {
      return;
    }
    _imagePath = imagePath;
    setState(() {});
    controller.showMessage(
      'Existing item found. Enter stock to add more.',
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(source: source, imageQuality: 88);
    if (image == null || !mounted) {
      return;
    }
    setState(() {
      _imagePath = image.path;
      _removePhoto = false;
    });
  }

  Future<void> _toggleStatus() async {
    if (_currentItem == null) {
      return;
    }
    final controller = context.read<TipidPosController>();
    final shouldChange = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentItem!.isActive ? 'Deactivate item?' : 'Activate item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_currentItem!.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
    if (shouldChange != true) {
      return;
    }
    if (_currentItem!.isActive) {
      await controller.deactivateItem(_currentItem!.itemId);
      if (!mounted) {
        return;
      }
      setState(() => _currentItem = _currentItem!.copyWith(status: 'INACTIVE'));
    } else {
      await controller.activateItem(_currentItem!.itemId);
      if (!mounted) {
        return;
      }
      setState(() => _currentItem = _currentItem!.copyWith(status: 'ACTIVE'));
    }
  }

  Future<void> _save(TipidPosController controller) async {
    final name = _nameController.text.trim();
    final cost = double.tryParse(_costController.text.trim());
    final price = double.tryParse(_priceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());
    final barcode = _barcodeController.text.trim();

    if (name.isEmpty) {
      controller.showMessage('Item name is required');
      return;
    }
    if (cost == null || cost < 0) {
      controller.showMessage('Enter a valid cost');
      return;
    }
    if (price == null || price <= 0) {
      controller.showMessage('Enter a valid price');
      return;
    }
    if (!_isEditing && (stock == null || stock < 0)) {
      controller.showMessage('Enter a valid stock quantity');
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await controller.updateItem(
          itemId: widget.itemId!,
          name: name,
          price: price,
          cost: cost,
          category: _category,
          barcode: barcode,
          imagePath: _imagePath,
          removePhoto: _removePhoto,
        );
      } else {
        await controller.saveNewItem(
          name: name,
          price: price,
          cost: cost,
          stock: stock ?? 0,
          category: _category,
          barcode: barcode,
          imagePath: _imagePath,
        );
      }
    } catch (error) {
      controller.showMessage(error.toString().replaceFirst('Exception: ', ''));
      if (mounted) {
        setState(() => _saving = false);
      }
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
