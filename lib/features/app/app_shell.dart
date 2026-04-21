import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_theme.dart';
import '../../core/models/app_models.dart';
import '../../core/widgets/app_frame.dart';
import '../credits/credits_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../inventory/inventory_screen.dart';
import '../pos/pos_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/transactions_screen.dart';
import 'app_controller.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int? _lastSnackBarId;

  @override
  Widget build(BuildContext context) {
    return Consumer<TipidPosController>(
      builder: (context, controller, _) {
        final event = controller.snackBarEvent;
        if (event != null && event.id != _lastSnackBarId) {
          _lastSnackBarId = event.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(event.message)));
            controller.consumeSnackBar();
          });
        }

        final gradient = controller.themeMode == ThemeMode.dark
            ? AppPalette.darkShellGradient
            : AppPalette.shellGradient;

        return DecoratedBox(
          decoration: BoxDecoration(gradient: gradient),
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.transparent,
            drawer: _AppDrawer(
              currentSection: controller.section,
              activitySection: controller.activitySection,
              themePreference: controller.settings.themePreference,
              onSelectSection: (section) {
                controller.setSection(section);
                Navigator.of(context).pop();
              },
              onOpenActivity: (section) {
                controller.openActivity(section);
                Navigator.of(context).pop();
              },
              onThemeChanged: controller.updateThemePreference,
              storeName: controller.settings.storeName,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _ShellTopBar(
                      label: _labelForSection(controller.section),
                      onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: controller.section.index,
                      children: const [
                        DashboardScreen(),
                        PosScreen(),
                        InventoryScreen(),
                        _ActivityHub(),
                        SettingsScreen(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: controller.section == AppSection.dashboard
                ? FloatingActionButton.extended(
                    onPressed: controller.openNewTransaction,
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text('New Transaction'),
                  )
                : null,
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          ),
        );
      },
    );
  }

  String _labelForSection(AppSection section) {
    switch (section) {
      case AppSection.dashboard:
        return 'Dashboard';
      case AppSection.pos:
        return 'Point of Sale';
      case AppSection.inventory:
        return 'Inventory';
      case AppSection.activity:
        return 'Activity';
      case AppSection.settings:
        return 'Settings';
    }
  }
}

class _ShellTopBar extends StatelessWidget {
  const _ShellTopBar({
    required this.label,
    required this.onMenuPressed,
  });

  final String label;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onMenuPressed,
          icon: const Icon(Icons.menu_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        const AppBrandMark(size: 44),
      ],
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.currentSection,
    required this.activitySection,
    required this.themePreference,
    required this.onSelectSection,
    required this.onOpenActivity,
    required this.onThemeChanged,
    required this.storeName,
  });

  final AppSection currentSection;
  final ActivitySection activitySection;
  final AppThemePreference themePreference;
  final ValueChanged<AppSection> onSelectSection;
  final ValueChanged<ActivitySection> onOpenActivity;
  final ValueChanged<AppThemePreference> onThemeChanged;
  final String storeName;

  @override
  Widget build(BuildContext context) {
    final label = storeName.trim().isEmpty ? 'TipidPOS' : storeName.trim();

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppBrandMark(showLabel: true),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DrawerTile(
                selected: currentSection == AppSection.dashboard,
                icon: Icons.home_rounded,
                label: 'Home',
                onTap: () => onSelectSection(AppSection.dashboard),
              ),
              const SizedBox(height: 6),
              _DrawerTile(
                selected: currentSection == AppSection.pos,
                icon: Icons.point_of_sale_rounded,
                label: 'New Transaction',
                onTap: () => onSelectSection(AppSection.pos),
              ),
              const SizedBox(height: 6),
              _DrawerTile(
                selected: currentSection == AppSection.inventory,
                icon: Icons.inventory_2_rounded,
                label: 'Products',
                onTap: () => onSelectSection(AppSection.inventory),
              ),
              const SizedBox(height: 6),
              _DrawerTile(
                selected: currentSection == AppSection.activity,
                icon: Icons.insights_rounded,
                label: 'Activity',
                onTap: () => onSelectSection(AppSection.activity),
              ),
              const SizedBox(height: 6),
              _DrawerTile(
                selected: currentSection == AppSection.settings,
                icon: Icons.tune_rounded,
                label: 'Settings',
                onTap: () => onSelectSection(AppSection.settings),
              ),
              const SizedBox(height: 18),
              Text(
                'QUICK ACCESS',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DrawerQuickAction(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Credits',
                      selected: currentSection == AppSection.activity &&
                          activitySection == ActivitySection.credits,
                      onTap: () => onOpenActivity(ActivitySection.credits),
                    ),
                    const SizedBox(height: 8),
                    _DrawerQuickAction(
                      icon: Icons.receipt_long_rounded,
                      label: 'Transactions',
                      selected: currentSection == AppSection.activity &&
                          activitySection == ActivitySection.transactions,
                      onTap: () => onOpenActivity(ActivitySection.transactions),
                    ),
                    const SizedBox(height: 8),
                    _DrawerQuickAction(
                      icon: Icons.bar_chart_rounded,
                      label: 'Reports',
                      selected: currentSection == AppSection.activity &&
                          activitySection == ActivitySection.reports,
                      onTap: () => onOpenActivity(ActivitySection.reports),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AppSurfaceCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Theme',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<AppThemePreference>(
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
                      selected: {themePreference},
                      onSelectionChanged: (selection) =>
                          onThemeChanged(selection.first),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
        : Colors.transparent;
    final foreground = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: foreground, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerQuickAction extends StatelessWidget {
  const _DrawerQuickAction({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: ActionChip(
        avatar: Icon(
          icon,
          size: 18,
          color: selected ? Theme.of(context).colorScheme.primary : null,
        ),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(label),
        ),
        labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: selected ? Theme.of(context).colorScheme.primary : null,
            ),
        backgroundColor: selected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
            : null,
        onPressed: onTap,
      ),
    );
  }
}

class _ActivityHub extends StatelessWidget {
  const _ActivityHub();

  @override
  Widget build(BuildContext context) {
    return Consumer<TipidPosController>(
      builder: (context, controller, _) {
        final activitySection = controller.activitySection;
        return Column(
          children: [
            AppResponsiveFrame(
              maxWidth: 1320,
              bottomPadding: 0,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Review credits, receipts, and performance.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppDropdownChip<ActivitySection>(
                    value: activitySection,
                    items: ActivitySection.values,
                    maxLabelWidth: 116,
                    labelBuilder: (value) {
                      switch (value) {
                        case ActivitySection.credits:
                          return 'Credits';
                        case ActivitySection.transactions:
                          return 'Transactions';
                        case ActivitySection.reports:
                          return 'Reports';
                      }
                    },
                    onSelected: controller.openActivity,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: IndexedStack(
                index: activitySection.index,
                children: const [
                  CreditsScreen(),
                  TransactionsScreen(),
                  ReportsScreen(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
