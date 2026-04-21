import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/app_frame.dart';
import '../app/app_controller.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TipidPosController>(
      builder: (context, controller, _) {
        final maxAmount = controller.dailyChart.fold<double>(
          0,
          (current, item) => item.amount > current ? item.amount : current,
        );
        final trendRows = controller.dailyChart;

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
                            title: 'Performance Snapshot',
                            subtitle:
                                'Use these numbers to check revenue, profit, and fast-moving products before closing the day.',
                            helpMessage:
                                'This section summarizes today, week, month, and year movement using the same dataset shown in the dashboard.',
                          ),
                          const SizedBox(height: 16),
                          ResponsiveWrapGrid(
                            maxColumns: 4,
                            children: [
                              _ReportMetric(
                                title: 'Today',
                                value: toPeso(controller.todayIncome.amount),
                                subtitle:
                                    '${controller.todayIncome.count} sales | Profit ${toPeso(controller.todayIncome.profit)}',
                              ),
                              _ReportMetric(
                                title: 'This Week',
                                value: toPeso(controller.weeklyIncome),
                                subtitle: 'Profit ${toPeso(controller.weeklyProfit)}',
                              ),
                              _ReportMetric(
                                title: 'This Month',
                                value: toPeso(controller.monthlyIncome),
                                subtitle: 'Profit ${toPeso(controller.monthlyProfit)}',
                              ),
                              _ReportMetric(
                                title: 'This Year',
                                value: toPeso(controller.yearlyIncome),
                                subtitle: 'Year-to-date revenue',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppSectionHeader(
                            title: '7-Day Trend',
                            helpMessage:
                                'Use this graph-like list to spot strong and weak sales days across the latest seven recorded entries.',
                          ),
                          const SizedBox(height: 14),
                          if (trendRows.isEmpty)
                            const AppEmptyState(
                              icon: Icons.show_chart_rounded,
                              title: 'No trend data yet',
                              message: 'Your weekly movement will appear after real transactions are saved.',
                            )
                          else
                            for (final entry in trendRows) ...[
                              _TrendRow(
                                day: entry.day,
                                amount: entry.amount,
                                progress: maxAmount == 0 ? 0 : entry.amount / maxAmount,
                              ),
                              if (entry != trendRows.last) const SizedBox(height: 12),
                            ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ResponsiveWrapGrid(
                      maxColumns: 3,
                      children: [
                        _SimpleListCard(
                          title: 'Top Sellers',
                          rows: controller.topSellers
                              .map((item) => '${item.item.name} | ${item.totalSold} sold')
                              .toList(growable: false),
                        ),
                        _SimpleListCard(
                          title: 'Low Stock',
                          rows: controller.lowStockItems
                              .map((item) => '${item.name} | ${item.stock} left')
                              .toList(growable: false),
                        ),
                        _SimpleListCard(
                          title: 'Out of Stock',
                          rows: controller.outOfStockItems
                              .map((item) => '${item.name} | Out of stock')
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

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({
    required this.day,
    required this.amount,
    required this.progress,
  });

  final String day;
  final double amount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 42, child: Text(day)),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 96,
          child: Text(
            toPeso(amount),
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _SimpleListCard extends StatelessWidget {
  const _SimpleListCard({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<String> rows;

  @override
  Widget build(BuildContext context) {
    final data = rows.isEmpty ? const ['No items to show'] : rows;
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: title),
          const SizedBox(height: 12),
          for (final row in data) ...[
            Text(row, style: Theme.of(context).textTheme.bodyLarge),
            if (row != data.last) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}
