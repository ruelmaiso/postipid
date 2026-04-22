import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_frame.dart';
import '../../core/widgets/item_image_thumb.dart';
import '../../core/widgets/receipt_preview.dart';
import '../app/app_controller.dart';
import '../scanner/barcode_scanner_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _cashController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _customerController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TipidPosController>(
      builder: (context, controller, _) {
        final query = _searchController.text.trim();
        final cashAmount = double.tryParse(_cashController.text.trim());
        final change =
            cashAmount == null ? null : cashAmount - controller.cartTotal;

        return RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              AppResponsiveFrame(
                maxWidth: 1320,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = isWideLayout(constraints.maxWidth);
                    final discoveryPanel = _DiscoveryPanel(
                      controller: controller,
                      query: query,
                      searchController: _searchController,
                      onChanged: _handleSearchChanged,
                      onClear: _clearSearch,
                      onScan: _scanBarcode,
                      onAddItem: (item) => _addItemToCart(controller, item),
                    );
                    final cartPanel = _CartPanel(
                      controller: controller,
                      customerController: _customerController,
                      cashController: _cashController,
                      change: change,
                      wide: wide,
                      onCashChanged: () => setState(() {}),
                      onCheckoutCash: _checkoutCash,
                      onCheckoutCredit: _checkoutCredit,
                    );

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: discoveryPanel),
                          const SizedBox(width: 16),
                          SizedBox(width: 418, child: cartPanel),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        discoveryPanel,
                        const SizedBox(height: 14),
                        cartPanel,
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSearchChanged(String value) async {
    setState(() {});
    await context.read<TipidPosController>().searchItems(value);
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<TipidPosController>().clearSearchResults();
    setState(() {});
  }

  void _addItemToCart(TipidPosController controller, ItemModel item) {
    final result = controller.addToCart(item);
    switch (result) {
      case AddToCartResult.added:
        controller.showMessage('${item.name} added to cart');
      case AddToCartResult.outOfStock:
        controller.showMessage('${item.name} is out of stock');
      case AddToCartResult.limitReached:
        controller.showMessage('No more stock available for ${item.name}');
    }

    _clearSearch();
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

    _searchController.clear();
    controller.clearSearchResults();
    await controller.findAndAddToCartByBarcode(barcode);
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _checkoutCash() async {
    final controller = context.read<TipidPosController>();
    final cashAmount = double.tryParse(_cashController.text.trim());
    if (cashAmount == null) {
      controller.showMessage('Enter a valid cash amount');
      return;
    }

    final receipt = await controller.checkoutCash(
      customerName: _customerController.text,
      cashReceived: cashAmount,
    );
    if (receipt == null || !mounted) {
      return;
    }

    if (controller.settings.autoPrintReceipt) {
      await controller.printReceipt(receipt);
      if (!mounted) {
        return;
      }
    }

    _customerController.clear();
    _cashController.clear();
    _clearSearch();
    setState(() {});

    await showReceiptPreviewSheet(
      context: context,
      receipt: receipt,
      paperSize: controller.settings.receiptPaperSize,
      onPrint: () => controller.printReceipt(receipt),
    );
  }

  Future<void> _checkoutCredit() async {
    final controller = context.read<TipidPosController>();
    final receipt = await controller.checkoutCredit(
      customerName: _customerController.text,
    );
    if (receipt == null || !mounted) {
      return;
    }

    if (controller.settings.autoPrintReceipt) {
      await controller.printReceipt(receipt);
      if (!mounted) {
        return;
      }
    }

    _customerController.clear();
    _cashController.clear();
    _clearSearch();
    setState(() {});

    await showReceiptPreviewSheet(
      context: context,
      receipt: receipt,
      paperSize: controller.settings.receiptPaperSize,
      onPrint: () => controller.printReceipt(receipt),
    );
  }
}

class _DiscoveryPanel extends StatelessWidget {
  const _DiscoveryPanel({
    required this.controller,
    required this.query,
    required this.searchController,
    required this.onChanged,
    required this.onClear,
    required this.onScan,
    required this.onAddItem,
  });

  final TipidPosController controller;
  final String query;
  final TextEditingController searchController;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final Future<void> Function() onScan;
  final ValueChanged<ItemModel> onAddItem;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.isNotEmpty;
    final hasResults = controller.searchResults.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'POS Checkout',
          subtitle:
              'Clean selling flow with search, scan, cart review, and receipt print.',
          helpMessage:
              'Use search or scan to add items. Use Credit only for unpaid balances that you will settle later.',
        ),
        const SizedBox(height: 14),
        Text(
          'Search or scan item',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        AppSurfaceCard(
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Search item or barcode',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? IconButton(
                      onPressed: onScan,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                    )
                  : IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 14),
        if (!hasQuery)
          Text(
            'Type item name or scan barcode to add to cart.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else if (!hasResults)
          const AppEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matching items',
            message:
                'Check the barcode or spelling, or add the product first in Inventory.',
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(
                title: 'Search Results',
                helpMessage:
                    'Tap Add to move the product into the cart. Inactive or out-of-stock items cannot be sold.',
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  for (final item in controller.searchResults) ...[
                    _SearchResultCard(
                      controller: controller,
                      item: item,
                      onTap: () => onAddItem(item),
                    ),
                    if (item != controller.searchResults.last)
                      const SizedBox(height: 12),
                  ],
                ],
              ),
            ],
          ),
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.controller,
    required this.item,
    required this.onTap,
  });

  final TipidPosController controller;
  final ItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final canAdd = item.isActive && item.stock > 0;
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ItemImageThumb(
            imageFuture: controller.imageFileForItem(item.itemId),
            size: 72,
            radius: 22,
            icon: Icons.shopping_bag_rounded,
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
                const SizedBox(height: 4),
                Text(
                  item.barcode.isEmpty ? 'No barcode saved' : item.barcode,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppInfoChip(
                      label: item.category,
                      color: AppPalette.lilacSoft,
                    ),
                    AppInfoChip(
                      label: 'Stock ${item.stock}',
                      color: item.stock > 0
                          ? AppPalette.emeraldSoft
                          : AppPalette.coralSoft,
                    ),
                    AppInfoChip(
                      label: toPeso(item.price),
                      color: AppPalette.oceanSoft,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            child: FilledButton.tonal(
              onPressed: canAdd ? onTap : null,
              child: Text(canAdd ? 'Add' : 'Out'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({
    required this.controller,
    required this.customerController,
    required this.cashController,
    required this.change,
    required this.wide,
    required this.onCashChanged,
    required this.onCheckoutCash,
    required this.onCheckoutCredit,
  });

  final TipidPosController controller;
  final TextEditingController customerController;
  final TextEditingController cashController;
  final double? change;
  final bool wide;
  final VoidCallback onCashChanged;
  final Future<void> Function() onCheckoutCash;
  final Future<void> Function() onCheckoutCredit;

  @override
  Widget build(BuildContext context) {
    final cartItems = controller.cart;
    final cardTint = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.nightSurfaceAlt
        : AppPalette.surfaceAlt;
    final changeVal = change;
    final changeLabel = changeVal == null
        ? 'PHP 0.00'
        : changeVal >= 0
            ? toPeso(changeVal)
            : 'Need ${toPeso(changeVal.abs())} more';
    final changeValueColor = changeVal != null && changeVal < 0
        ? AppPalette.coral
        : Theme.of(context).colorScheme.onSurface;

    return AppSurfaceCard(
      backgroundColor: wide ? cardTint : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: AppSectionHeader(
                  title: 'Current Cart',
                  helpMessage:
                      'Adjust quantity here before checkout. Removing an item only affects the current sale.',
                ),
              ),
              if (cartItems.isNotEmpty)
                TextButton(
                  onPressed: controller.clearCart,
                  child: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (cartItems.isEmpty)
            const AppEmptyState(
              icon: Icons.remove_shopping_cart_rounded,
              title: 'Cart is empty',
              message: 'Products added from search or scan will appear here.',
            )
          else ...[
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: wide ? 370 : 430),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: cartItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _CartItemTile(
                  controller: controller,
                  item: cartItems[index],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppPalette.midnight
                  : AppPalette.surfaceTint,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Total items',
                  value: '${controller.cartItemCount}',
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: 'Amount due',
                  value: toPeso(controller.cartTotal),
                  emphasis: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _FieldLabel(
            title: 'Customer name',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: customerController,
            decoration: const InputDecoration(
              hintText: 'Optional for cash, required for credit',
            ),
          ),
          const SizedBox(height: 12),
          const _FieldLabel(
            title: 'Cash received',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: cashController,
            decoration: const InputDecoration(
              hintText: 'Enter amount',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onCashChanged(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel(
                  title: 'Payment summary',
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: 'Change',
                  value: changeLabel,
                  valueColor: changeValueColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: cartItems.isEmpty ? null : onCheckoutCredit,
                  child: const Text('Record Credit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: cartItems.isEmpty ? null : onCheckoutCash,
                  child: const Text('Pay Cash'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.controller,
    required this.item,
  });

  final TipidPosController controller;
  final CartItemData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 340;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ItemImageThumb(
                imageFuture: controller.imageFileForItem(item.itemId),
                size: 54,
                radius: 10,
                icon: Icons.shopping_basket_rounded,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${toPeso(item.price)} each',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        _QtyButton(
                          icon: Icons.remove_rounded,
                          onTap: () => controller.updateCartQuantity(
                            item.itemId,
                            item.quantity - 1,
                          ),
                        ),
                        Text(
                          '${item.quantity}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        _QtyButton(
                          icon: Icons.add_rounded,
                          onTap: item.quantity >= item.stock
                              ? null
                              : () => controller.updateCartQuantity(
                                    item.itemId,
                                    item.quantity + 1,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    toPeso(item.price * item.quantity),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => controller.removeFromCart(item.itemId),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabledTint = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.nightSurfaceAlt
        : AppPalette.surfaceTint;
    final disabledTint = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.nightLine
        : AppPalette.mist;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: onTap == null ? disabledTint : enabledTint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: onTap == null
              ? AppPalette.slate
              : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.title,
    this.helpMessage,
  });

  final String title;
  final String? helpMessage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (helpMessage != null && helpMessage!.trim().isNotEmpty) ...[
          const SizedBox(width: 8),
          AppHelpButton(message: helpMessage!),
        ],
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasis = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasis;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: emphasis
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: (emphasis
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.titleMedium)
                ?.copyWith(color: valueColor),
          ),
        ),
      ],
    );
  }
}
