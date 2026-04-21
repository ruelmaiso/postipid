import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_frame.dart';
import '../../core/widgets/receipt_preview.dart';
import '../app/app_controller.dart';

enum TransactionFilter {
  all,
  cash,
  credit,
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedDayMillis = startOfDay(DateTime.now().millisecondsSinceEpoch);
  TransactionFilter _filter = TransactionFilter.all;

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
        final oldestDay = controller.allTransactions.isEmpty
            ? today
            : controller.allTransactions
                .map((item) => startOfDay(item.createdAt))
                .reduce((value, element) => value < element ? value : element);
        _selectedDayMillis = _selectedDayMillis.clamp(oldestDay, today).toInt();

        final query = _searchController.text.trim().toLowerCase();
        final items = controller.allTransactions.where((transaction) {
          final sameDay = startOfDay(transaction.createdAt) == _selectedDayMillis;
          final matchesQuery = query.isEmpty ||
              (transaction.customerName ?? '').toLowerCase().contains(query) ||
              transaction.transactionId.toString().contains(query) ||
              transaction.paymentType.toLowerCase().contains(query);
          final matchesFilter = switch (_filter) {
            TransactionFilter.all => true,
            TransactionFilter.cash => transaction.paymentType.toLowerCase() == 'cash',
            TransactionFilter.credit => transaction.paymentType.toLowerCase() == 'credit',
          };
          return sameDay && matchesQuery && matchesFilter;
        }).toList(growable: false);

        final totalRevenue = items.fold<double>(0, (sum, item) => sum + item.totalAmount);
        final totalProfit = items.fold<double>(0, (sum, item) => sum + item.totalProfit);

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
                          Row(
                            children: [
                              Expanded(
                                child: AppSectionHeader(
                                  title: 'Transactions',
                                  helpMessage:
                                      'Use the day switcher to move across dates, then filter by payment type to isolate cash or credit receipts.',
                                ),
                              ),
                              const SizedBox(width: 10),
                              AppDropdownChip<TransactionFilter>(
                                value: _filter,
                                items: TransactionFilter.values,
                                maxLabelWidth: 88,
                                labelBuilder: _filterLabel,
                                onSelected: (value) => setState(() => _filter = value),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _TransactionDayNavigator(
                            label: toEnglishDayDateLabel(_selectedDayMillis),
                            canGoBackward: controller.allTransactions.isNotEmpty &&
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
                                label: '${items.length} transactions',
                                icon: Icons.receipt_long_rounded,
                              ),
                              AppInfoChip(
                                label: 'Sales ${toPeso(totalRevenue)}',
                                icon: Icons.point_of_sale_rounded,
                                color: AppPalette.emeraldSoft,
                              ),
                              AppInfoChip(
                                label: 'Profit ${toPeso(totalProfit)}',
                                icon: Icons.trending_up_rounded,
                                color: AppPalette.oceanSoft,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'Search receipt number, customer, or payment type',
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
                        icon: Icons.inbox_rounded,
                        title: 'No transactions found',
                        message: 'Completed sales for the selected day will appear here.',
                      )
                    else
                      Column(
                        children: [
                          for (final transaction in items) ...[
                            _TransactionCard(
                              transaction: transaction,
                              onPreview: () => _previewReceipt(controller, transaction),
                              onPrint: () => _printReceipt(controller, transaction),
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
      title: 'Receipt #${transaction.transactionId}',
      onPrint: () => context.read<TipidPosController>().printReceipt(receipt),
    );
  }

  Future<void> _printReceipt(
    TipidPosController controller,
    TransactionModel transaction,
  ) async {
    final receipt = await controller.buildReceiptForTransaction(transaction);
    await controller.printReceipt(receipt);
  }

  String _filterLabel(TransactionFilter value) {
    switch (value) {
      case TransactionFilter.all:
        return 'All';
      case TransactionFilter.cash:
        return 'Cash';
      case TransactionFilter.credit:
        return 'Credit';
    }
  }
}

class _TransactionDayNavigator extends StatelessWidget {
  const _TransactionDayNavigator({
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

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transaction,
    required this.onPreview,
    required this.onPrint,
  });

  final TransactionModel transaction;
  final Future<void> Function() onPreview;
  final Future<void> Function() onPrint;

  @override
  Widget build(BuildContext context) {
    final statusLabel = transaction.status.replaceAll('_', ' ');
    final paymentColor = transaction.paymentType.toLowerCase() == 'cash'
        ? AppPalette.emeraldSoft
        : AppPalette.amberSoft;

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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      AppInfoChip(label: transaction.paymentType, color: paymentColor),
                      AppInfoChip(
                        label: statusLabel,
                        color: transaction.status == 'PAID'
                            ? AppPalette.oceanSoft
                            : AppPalette.coralSoft,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('Preview'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onPrint,
                  icon: const Icon(Icons.print_rounded),
                  label: const Text('Print'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
