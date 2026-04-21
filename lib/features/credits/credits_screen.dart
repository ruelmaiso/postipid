import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_frame.dart';
import '../../core/widgets/receipt_preview.dart';
import '../app/app_controller.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedDayMillis = startOfDay(DateTime.now().millisecondsSinceEpoch);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TipidPosController>(
      builder: (context, controller, _) {
        final today = startOfDay(DateTime.now().millisecondsSinceEpoch);
        final oldestDay = controller.pendingCredits.isEmpty
            ? today
            : controller.pendingCredits
                .map((item) => startOfDay(item.createdAt))
                .reduce((value, element) => value < element ? value : element);
        _selectedDayMillis = _selectedDayMillis.clamp(oldestDay, today).toInt();

        final query = _searchController.text.trim().toLowerCase();
        final items = controller.pendingCredits.where((transaction) {
          final sameDay = startOfDay(transaction.createdAt) == _selectedDayMillis;
          final matchesQuery = query.isEmpty ||
              (transaction.customerName ?? '').toLowerCase().contains(query) ||
              transaction.transactionId.toString().contains(query);
          return sameDay && matchesQuery;
        }).toList(growable: false);
        final totalDue = items.fold<double>(0, (sum, item) => sum + item.totalAmount);

        return RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              AppResponsiveFrame(
                maxWidth: 1320,
                topPadding: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppSectionHeader(
                            title: 'Credits',
                            helpMessage:
                                'Track unpaid balances per day here, then open the receipt or settle the account once the customer pays.',
                          ),
                          const SizedBox(height: 14),
                          _CreditsDayNavigator(
                            label: toEnglishDayDateLabel(_selectedDayMillis),
                            canGoBackward: controller.pendingCredits.isNotEmpty &&
                                _selectedDayMillis > oldestDay,
                            canGoForward: _selectedDayMillis < today,
                            onPrevious: () =>
                                setState(() => _selectedDayMillis = plusDays(_selectedDayMillis, -1)),
                            onNext: () =>
                                setState(() => _selectedDayMillis = plusDays(_selectedDayMillis, 1)),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              AppInfoChip(
                                label: '${items.length} pending accounts',
                                icon: Icons.receipt_long_rounded,
                              ),
                              AppInfoChip(
                                label: 'Due ${toPeso(totalDue)}',
                                icon: Icons.account_balance_wallet_rounded,
                                color: AppPalette.amberSoft,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'Search customer or receipt number',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (items.isEmpty)
                      const AppEmptyState(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'No pending credits',
                        message: 'Utang transactions for the selected day will appear here.',
                      )
                    else
                      Column(
                        children: [
                          for (final transaction in items) ...[
                            _CreditCard(
                              transaction: transaction,
                              onPreview: () => _previewReceipt(controller, transaction),
                              onSettle: () => _confirmSettle(controller, transaction),
                            ),
                            if (transaction != items.last) const SizedBox(height: 12),
                          ],
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

  Future<void> _previewReceipt(
    TipidPosController controller,
    TransactionModel transaction,
  ) async {
    final receipt = await controller.buildReceiptForTransaction(transaction);
    if (!mounted) {
      return;
    }
    await showReceiptPreviewSheet(
      context: context,
      receipt: receipt,
      paperSize: controller.settings.receiptPaperSize,
      title: 'Credit Receipt',
      onPrint: () => context.read<TipidPosController>().printReceipt(receipt),
    );
  }

  Future<void> _confirmSettle(
    TipidPosController controller,
    TransactionModel transaction,
  ) async {
    final shouldSettle = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settle this credit?'),
        content: Text(
          'Mark receipt #${transaction.transactionId} for '
          '${transaction.customerName ?? 'Walk-in'} as fully paid?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Settle'),
          ),
        ],
      ),
    );
    if (shouldSettle == true) {
      await controller.settleCredit(transaction.transactionId);
    }
  }
}

class _CreditsDayNavigator extends StatelessWidget {
  const _CreditsDayNavigator({
    required this.label,
    required this.canGoBackward,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final bool canGoBackward;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: canGoBackward ? onPrevious : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: canGoForward ? onNext : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _CreditCard extends StatelessWidget {
  const _CreditCard({
    required this.transaction,
    required this.onPreview,
    required this.onSettle,
  });

  final TransactionModel transaction;
  final Future<void> Function() onPreview;
  final Future<void> Function() onSettle;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.customerName ?? 'Walk-in',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Receipt #${transaction.transactionId}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      toDateTimeLabel(transaction.createdAt),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    toPeso(transaction.totalAmount),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const AppInfoChip(
                    label: 'Credit',
                    color: AppPalette.amberSoft,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onPreview,
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('View Receipt'),
              ),
              ElevatedButton.icon(
                onPressed: onSettle,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Settle Credit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
