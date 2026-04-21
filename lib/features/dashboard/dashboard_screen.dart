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
                item.day.hashCode.isEven ? AppPalette.primary : AppPalette.emerald,
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
                    _DashboardHeader(controller: controller),
                    const SizedBox(height: 12),
                    ResponsiveWrapGrid(
                      minColumns: 2,
                      maxColumns: 2,
                      children: [
                        _CompactMetricCard(
                          title: 'Sales',
                          value: toPeso(controller.dashboardAnalytics.sales),
                          hint: 'Within selected range',
                        ),
                        _CompactMetricCard(
                          title: 'Profit',
                          value: toPeso(controller.dashboardAnalytics.profit),
                          hint: 'Within selected range',
                        ),
                        _CompactMetricCard(
                          title: 'Transactions',
                          value: '${controller.dashboardAnalytics.transactionCount}',
                          hint: 'Completed receipts',
                        ),
                        _CompactMetricCard(
                          title: 'Pending Credits',
                          value: '${controller.pendingCredits.length}',
                          hint: 'Unpaid balances',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _GraphCard(
                      rangeLabel: formatDashboardDateRangeLabel(range),
                      entries: graphEntries,
                      highestValue: highestValue,
                      trailing: AppDateRangeChip(
                        range: range,
                        maxLabelWidth: 112,
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
                    const SizedBox(height: 12),
                    _PopularProductsCard(controller: controller),
                    const SizedBox(height: 12),
                    ResponsiveWrapGrid(
                      maxColumns: 2,
                      children: [
                        _WatchCard(
                          title: 'Low Stock Watch',
                          tone: AppPalette.amber,
                          rows: controller.lowStockItems
                              .map((item) => '${item.name} · ${item.stock} left')
                              .toList(growable: false),
                        ),
                        _WatchCard(
                          title: 'Out Of Stock',
                          tone: AppPalette.coral,
                          rows: controller.outOfStockItems
                              .map((item) => '${item.name} · Refill needed')
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

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.controller});

  final TipidPosController controller;

  @override
  Widget build(BuildContext context) {
    final storeName = controller.settings.storeName.trim().isEmpty
        ? 'TipidPOS'
        : controller.settings.storeName;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(
              title: storeName,
              subtitle: 'Daily store summary',
            ),
            const SizedBox(height: 10),
            AppInfoChip(
              label: 'Today: ${toPeso(controller.todayIncome.amount)}',
              icon: Icons.today_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppPalette.nightSurfaceAlt
                  : AppPalette.surfaceTint,
            ),
          ],
        );
      },
    );
  }
}

class _CompactMetricCard extends StatelessWidget {
  const _CompactMetricCard({
    required this.title,
    required this.value,
    required this.hint,
  });

  final String title;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(hint, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sales Trend',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 4),
          Text(
            rangeLabel,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final ratio = highestValue <= 0 ? 0.08 : (entry.value / highestValue);
                return SizedBox(
                  width: 44,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _shortValue(entry.value),
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 20,
                            height: (ratio * 130).clamp(12, 130),
                            decoration: BoxDecoration(
                              color: entry.color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
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
            subtitle: 'Top movers in selected range',
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            const AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No top sellers yet',
              message: 'Complete transactions first so top products can be ranked.',
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
                  if (row != rows.last) const Divider(height: 18),
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
          size: 46,
          radius: 12,
          icon: Icons.shopping_bag_rounded,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amount, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '$price · $status',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isActive ? AppPalette.emerald : AppPalette.coral,
                  ),
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
    required this.tone,
    required this.rows,
  });

  final String title;
  final Color tone;
  final List<String> rows;

  @override
  Widget build(BuildContext context) {
    final displayRows = rows.isEmpty ? const ['No items to show'] : rows;
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: title),
          const SizedBox(height: 10),
          for (final row in displayRows) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: tone,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    row,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            if (row != displayRows.last) const Divider(height: 16),
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
