import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/widgets/app_frame.dart';

class ManualScreen extends StatelessWidget {
  const ManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const sections = [
      _ManualSection(
        title: 'Before You Sell',
        icon: Icons.storefront_rounded,
        points: [
          'Open Settings first and complete the store name, receipt footer, theme, and paper size.',
          'Pair your Bluetooth thermal printer in Android settings before choosing it inside the app.',
          'Check Inventory and make sure item costs, prices, and stocks are correct before opening POS.',
        ],
      ),
      _ManualSection(
        title: 'Daily POS Flow',
        icon: Icons.point_of_sale_rounded,
        points: [
          'Search or scan an item, then review the cart before checkout.',
          'For cash sales, enter the cash amount and confirm the computed change.',
          'For credit, customer name is required so the balance appears correctly under Credits.',
          'Always review the receipt preview before printing, especially after editing receipt lines or paper size.',
        ],
      ),
      _ManualSection(
        title: 'Inventory Management',
        icon: Icons.inventory_2_rounded,
        points: [
          'Use Add Item for new products and Stock In when you only need to replenish quantity.',
          'Attach a photo and barcode when possible so future lookup is faster during selling.',
          'Inactive items stay in records but should no longer appear in regular selling flow.',
        ],
      ),
      _ManualSection(
        title: 'Credits and Reports',
        icon: Icons.insights_rounded,
        points: [
          'Use Credits for unsettled balances and settle only when the customer fully pays.',
          'Use Transactions to review receipt history and confirm printed totals.',
          'Use Reports to monitor weak-moving stock, low stock, and top sellers before reordering.',
        ],
      ),
      _ManualSection(
        title: 'Backup and Safety',
        icon: Icons.backup_rounded,
        points: [
          'Export backup regularly before large changes, data cleanup, or app updates.',
          'Import backup only when you are sure you want to replace the current device data.',
          'Use Clear All Data only for full reset; it removes items, transactions, credits, and logs.',
        ],
      ),
    ];

    final gradient = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.darkShellGradient
        : AppPalette.shellGradient;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Manual')),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            AppResponsiveFrame(
              maxWidth: 1080,
              bottomPadding: 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSurfaceCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppBrandMark(size: 56),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TipidPOS Manual',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Step-by-step operating guide for onboarding, checkout, inventory, activity, and backups.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final section in sections) ...[
                    AppSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppPalette.nightSurfaceAlt
                                      : AppPalette.surfaceTint,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  section.icon,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppSectionHeader(title: section.title),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          for (final point in section.points) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    point,
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                            if (point != section.points.last)
                              const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                    if (section != sections.last) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualSection {
  const _ManualSection({
    required this.title,
    required this.icon,
    required this.points,
  });

  final String title;
  final IconData icon;
  final List<String> points;
}
