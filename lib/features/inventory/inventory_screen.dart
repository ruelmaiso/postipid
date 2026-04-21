import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_frame.dart';
import '../../core/widgets/item_image_thumb.dart';
import '../app/app_controller.dart';
import '../scanner/barcode_scanner_screen.dart';
import 'item_editor_screen.dart';

enum InventoryFilter {
  all,
  active,
  inactive,
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  InventoryFilter _filter = InventoryFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TipidPosController>(
      builder: (context, controller, _) {
        final query = _searchController.text.trim().toLowerCase();
        final items = controller.allItems.where((item) {
          final matchesQuery = query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              item.barcode.toLowerCase().contains(query) ||
              item.category.toLowerCase().contains(query);
          final matchesFilter = switch (_filter) {
            InventoryFilter.all => true,
            InventoryFilter.active => item.isActive,
            InventoryFilter.inactive => !item.isActive,
          };
          return matchesQuery && matchesFilter;
        }).toList(growable: false);

        return RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              AppResponsiveFrame(
                maxWidth: 1320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = isMediumLayout(constraints.maxWidth);
                        final addButton = FilledButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ItemEditorScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Item'),
                        );

                        if (wide) {
                          return AppSectionHeader(
                            title: 'Inventory',
                            subtitle:
                                'Manage products, stock, images, and barcode-ready items from one clean view.',
                            helpMessage:
                                'Search or scan to find an item quickly. Use Stock In to refill and Edit to update price or details.',
                            trailing: addButton,
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppSectionHeader(
                              title: 'Inventory',
                              subtitle:
                                  'Manage products, stock, images, and barcode-ready items from one clean view.',
                              helpMessage:
                                  'Search or scan to find an item quickly. Use Stock In to refill and Edit to update price or details.',
                            ),
                            const SizedBox(height: 12),
                            addButton,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    AppSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Search item, category, or barcode',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: query.isEmpty
                                  ? IconButton(
                                      onPressed: _scanBarcode,
                                      icon: const Icon(
                                          Icons.qr_code_scanner_rounded),
                                    )
                                  : IconButton(
                                      onPressed: () => setState(
                                          () => _searchController.clear()),
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              AppInfoChip(
                                label:
                                    '${controller.allItems.length} total items',
                                icon: Icons.inventory_2_rounded,
                              ),
                              AppInfoChip(
                                label:
                                    '${controller.lowStockItems.length} low stock',
                                icon: Icons.warning_amber_rounded,
                                color: AppPalette.amberSoft,
                              ),
                              AppInfoChip(
                                label:
                                    '${controller.outOfStockItems.length} out of stock',
                                icon: Icons.error_outline_rounded,
                                color: AppPalette.coralSoft,
                              ),
                              AppDropdownChip<InventoryFilter>(
                                value: _filter,
                                items: InventoryFilter.values,
                                labelBuilder: _filterLabel,
                                onSelected: (value) =>
                                    setState(() => _filter = value),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (items.isEmpty)
                      const AppEmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No inventory items found',
                        message:
                            'Add your first product or adjust the search and filter above.',
                      )
                    else
                      ResponsiveWrapGrid(
                        maxColumns: 2,
                        children: [
                          for (final item in items)
                            _InventoryCard(
                              controller: controller,
                              item: item,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _filterLabel(InventoryFilter value) {
    switch (value) {
      case InventoryFilter.all:
        return 'All Items';
      case InventoryFilter.active:
        return 'Active';
      case InventoryFilter.inactive:
        return 'Inactive';
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (barcode == null || barcode.trim().isEmpty) {
      return;
    }

    _searchController.text = barcode;
    setState(() {});
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.controller,
    required this.item,
  });

  final TipidPosController controller;
  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        item.isActive ? AppPalette.emeraldSoft : AppPalette.coralSoft;

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ItemImageThumb(
                imageFuture: controller.imageFileForItem(item.itemId),
                size: 78,
                radius: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.category,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.barcode.isEmpty ? 'No barcode saved' : item.barcode,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppInfoChip(
                label: 'Stock ${item.stock}',
                color: item.stock <= 0
                    ? AppPalette.coralSoft
                    : item.stock <= controller.settings.lowStockThreshold
                        ? AppPalette.amberSoft
                        : AppPalette.emeraldSoft,
              ),
              AppInfoChip(
                label: item.status,
                color: statusColor,
              ),
              AppInfoChip(
                label: toPeso(item.price),
                color: AppPalette.oceanSoft,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Cost ${toPeso(item.cost)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ItemEditorScreen(itemId: item.itemId),
                    ),
                  );
                },
                child: const Text('Edit'),
              ),
              ElevatedButton(
                onPressed: item.isActive
                    ? () => _showStockInDialog(context, controller, item)
                    : null,
                child: const Text('Stock In'),
              ),
              FilledButton.tonal(
                onPressed: () async {
                  if (item.isActive) {
                    await controller.deactivateItem(item.itemId);
                  } else {
                    await controller.activateItem(item.itemId);
                  }
                },
                child: Text(item.isActive ? 'Deactivate' : 'Activate'),
              ),
              if (!item.isActive)
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    foregroundColor: AppPalette.coral,
                  ),
                  onPressed: () => _confirmPermanentDelete(
                    context,
                    controller,
                    item,
                  ),
                  child: const Text('Delete Permanently'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showStockInDialog(
    BuildContext context,
    TipidPosController controller,
    ItemModel item,
  ) async {
    final quantityController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Stock In'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name),
              const SizedBox(height: 6),
              Text('Current stock: ${item.stock}'),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity to add'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final quantity = int.tryParse(quantityController.text.trim());
                if (quantity == null || quantity <= 0) {
                  controller.showMessage('Enter a valid quantity');
                  return;
                }
                await controller.stockIn(item.itemId, quantity);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    quantityController.dispose();
  }

  Future<void> _confirmPermanentDelete(
    BuildContext context,
    TipidPosController controller,
    ItemModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item permanently?'),
        content: Text(
          '${item.name} will be removed from inventory and search. Transaction history will stay intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await controller.deleteInactiveItem(item.itemId);
    } catch (error) {
      controller.showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }
}
