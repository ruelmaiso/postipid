import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_theme.dart';
import '../../core/widgets/app_frame.dart';
import '../../core/widgets/item_image_thumb.dart';
import '../../core/utils/formatters.dart';
import '../app/app_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TipidPosController>(
      builder: (context, controller, _) {
        final range = controller.dashboardDateRange;
        final graphEntries = controller.dashboardChart
            .map(
              (item) => _GraphEntry(
                item.day,
                item.amount,
                item.day.hashCode.isEven
                    ? AppPalette.primary
                    : AppPalette.emerald,
              ),
            )
            .toList(growable: false);
        final highestValue = graphEntries.fold<double>(
          0,
          (max, item) => item.value > max ? item.value : max,
        );

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
                    _OverviewPanel(
                      controller: controller,
                      rangeLabel: formatDashboardDateRangeLabel(range),
                    ),
                    const SizedBox(height: 14),
                    _GraphCard(
                      rangeLabel: formatDashboardDateRangeLabel(range),
                      entries: graphEntries,
                      highestValue: highestValue,
                      trailing: AppDateRangeChip(
                        range: range,
                        onTap: () async {
                          final selected = await showDashboardDateRangeSheet(
                            context: context,
                            initialRange: range,
                          );
                          if (selected == null || !context.mounted) {
                            return;
                          }
                          await context
                              .read<TipidPosController>()
                              .updateDashboardDateRange(selected);
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    ResponsiveWrapGrid(
                      maxColumns: 2,
                      children: [
                        _CompactMetricCard(
                          title: 'Sales',
                          value: toPeso(controller.dashboardAnalytics.sales),
                          chip: 'Range sales',
                          tone: AppPalette.lilacSoft,
                        ),
                        _CompactMetricCard(
                          title: 'Profit',
                          value: toPeso(controller.dashboardAnalytics.profit),
                          chip: 'Range profit',
                          tone: AppPalette.emeraldSoft,
                        ),
                        _CompactMetricCard(
                          title: 'Transactions',
                          value:
                              '${controller.dashboardAnalytics.transactionCount}',
                          chip: 'Within range',
                          tone: AppPalette.amberSoft,
                        ),
                        _CompactMetricCard(
                          title: 'Pending Credits',
                          value: '${controller.pendingCredits.length}',
                          chip: 'Monitor',
                          tone: AppPalette.coralSoft,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _PopularProductsCard(controller: controller),
                    const SizedBox(height: 14),
                    ResponsiveWrapGrid(
                      maxColumns: 2,
                      children: [
                        _WatchCard(
                          title: 'Low Stock Watch',
                          helpMessage:
                              'Use this list to refill fast movers before they stop appearing in POS.',
                          tone: AppPalette.amberSoft,
                          rows: controller.lowStockItems
                              .map(
                                  (item) => '${item.name} | ${item.stock} left')
                              .toList(growable: false),
                        ),
                        _WatchCard(
                          title: 'Out Of Stock',
                          helpMessage:
                              'Items shown here are currently unavailable for checkout until restocked.',
                          tone: AppPalette.coralSoft,
                          rows: controller.outOfStockItems
                              .map((item) => '${item.name} | Refill needed')
                              .toList(growable: false),
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
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.controller,
    required this.rangeLabel,
  });

  final TipidPosController controller;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final storeName = controller.settings.storeName.trim().isEmpty
        ? 'TipidPOS'
        : controller.settings.storeName;
    final summary = controller.dashboardAnalytics;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppPalette.heroGradient,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: storeName,
            subtitle: 'Overview for $rangeLabel',
            helpMessage:
                'Tap the sticky New Transaction button anytime to open the checkout screen.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AppInfoChip(
                label: '${summary.transactionCount} transactions in range',
                icon: Icons.receipt_long_rounded,
                color: Colors.white.withValues(alpha: 0.16),
                foreground: Colors.white,
              ),
              AppInfoChip(
                label:
                    '${summary.topQuantity} top sold | ${summary.topItem}',
                icon: Icons.local_fire_department_rounded,
                color: Colors.white.withValues(alpha: 0.16),
                foreground: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: controller.openNewTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppPalette.primaryDeep,
              minimumSize: const Size(0, 50),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Transaction'),
          ),
        ],
      ),
    );
  }
}

class _CompactMetricCard extends StatelessWidget {
  const _CompactMetricCard({
    required this.title,
    required this.value,
    required this.chip,
    required this.tone,
  });

  final String title;
  final String value;
  final String chip;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInfoChip(label: chip, color: tone),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _GraphCard extends StatelessWidget {
  const _GraphCard({
    required this.rangeLabel,
    required this.entries,
    required this.highestValue,
    this.trailing,
  });

  final String rangeLabel;
  final List<_GraphEntry> entries;
  final double highestValue;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Report Graph',
            subtitle: 'Performance trend for $rangeLabel',
            helpMessage:
                'Switch the range dropdown to update the graph using the selected reporting view.',
            trailing: trailing,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 240,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final entry in entries) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _shortValue(entry.value),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 26,
                                height: highestValue <= 0
                                    ? 12
                                    : (entry.value / highestValue) * 160,
                                decoration: BoxDecoration(
                                  color: entry.color,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            entry.label,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }
}

class _PopularProductsCard extends StatelessWidget {
  const _PopularProductsCard({required this.controller});

  final TipidPosController controller;

  @override
  Widget build(BuildContext context) {
    final rows = controller.dashboardTopSellers.take(4).toList(growable: false);

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Popular Products',
            subtitle: 'Best performing items in the selected range',
            helpMessage:
                'These products are ranked using only the paid transactions inside the selected dashboard date range.',
          ),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            const AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No top sellers yet',
              message:
                  'Complete transactions first so the dashboard can rank your products.',
            )
          else
            Column(
              children: [
                for (final row in rows) ...[
                  _ProductRow(
                    controller: controller,
                    itemId: row.item.itemId,
                    name: row.item.name,
                    amount: '${row.totalSold} sold',
                    price: toPeso(row.item.price),
                    status: row.item.isActive ? 'Active' : 'Inactive',
                  ),
                  if (row != rows.last) const Divider(height: 22),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.controller,
    required this.itemId,
    required this.name,
    required this.amount,
    required this.price,
    required this.status,
  });

  final TipidPosController controller;
  final int itemId;
  final String name;
  final String amount;
  final String price;
  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'Active';
    return Row(
      children: [
        ItemImageThumb(
          imageFuture: controller.imageFileForItem(itemId),
          size: 52,
          radius: 18,
          icon: Icons.shopping_bag_rounded,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amount, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                AppInfoChip(
                  label: price,
                  color: AppPalette.lilacSoft,
                ),
                AppInfoChip(
                  label: status,
                  color:
                      isActive ? AppPalette.emeraldSoft : AppPalette.coralSoft,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _WatchCard extends StatelessWidget {
  const _WatchCard({
    required this.title,
    required this.helpMessage,
    required this.tone,
    required this.rows,
  });

  final String title;
  final String helpMessage;
  final Color tone;
  final List<String> rows;

  @override
  Widget build(BuildContext context) {
    final displayRows = rows.isEmpty ? const ['No items to show'] : rows;
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: title,
            helpMessage: helpMessage,
          ),
          const SizedBox(height: 14),
          for (final row in displayRows) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: tone,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    row,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            if (row != displayRows.last) const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}

class _GraphEntry {
  const _GraphEntry(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}
