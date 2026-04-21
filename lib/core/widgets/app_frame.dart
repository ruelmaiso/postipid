import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../models/app_models.dart';
import '../utils/formatters.dart';

class AppResponsiveFrame extends StatelessWidget {
  const AppResponsiveFrame({
    super.key,
    required this.child,
    this.maxWidth = 1240,
    this.bottomPadding = 88,
    this.topPadding = 8,
  });

  final Widget child;
  final double maxWidth;
  final double bottomPadding;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = pageHorizontalPadding(width);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            bottomPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}

double pageHorizontalPadding(double width) {
  if (width >= 1280) {
    return 32;
  }
  if (width >= 900) {
    return 24;
  }
  return 16;
}

bool isWideLayout(double width) => width >= 1024;

bool isMediumLayout(double width) => width >= 720;

int responsiveColumns(double width, {int min = 1, int max = 4}) {
  if (width >= 1180) {
    return max.clamp(min, max);
  }
  if (width >= 900) {
    return (max - 1).clamp(min, max);
  }
  if (width >= 640) {
    return 2.clamp(min, max);
  }
  return min;
}

class AppBrandMark extends StatelessWidget {
  const AppBrandMark({
    super.key,
    this.size = 54,
    this.showLabel = false,
  });

  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppPalette.heroGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.45,
          height: size * 0.45,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: size * 0.12,
                  height: size * 0.32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: size * 0.12,
                  height: size * 0.42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: size * 0.12,
                  height: size * 0.24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!showLabel) {
      return chip;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip,
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('TipidPOS', style: Theme.of(context).textTheme.titleLarge),
            Text(
              'Fast retail flow',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}

class AppHelpButton extends StatelessWidget {
  const AppHelpButton({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      message: message,
      preferBelow: false,
      child: Icon(
        Icons.info_outline_rounded,
        size: 18,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.92),
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.helpMessage,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? helpMessage;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackTrailing = trailing != null && constraints.maxWidth < 560;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (helpMessage != null && helpMessage!.trim().isNotEmpty) ...[
                  const SizedBox(width: 6),
                  AppHelpButton(message: helpMessage!),
                ],
              ],
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        );

        if (stackTrailing) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              if (trailing != null) ...[
                const SizedBox(height: 12),
                trailing!,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              Flexible(child: trailing!),
            ],
          ],
        );
      },
    );
  }
}

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tint = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.nightSurfaceAlt
        : AppPalette.lilacSoft;

    return AppSurfaceCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

class AppInfoChip extends StatelessWidget {
  const AppInfoChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.foreground,
    this.maxWidth,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? foreground;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final background = color ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppPalette.nightSurfaceAlt
            : AppPalette.lilacSoft);
    final textColor = foreground ?? Theme.of(context).colorScheme.onSurface;

    return Container(
      constraints: maxWidth == null ? null : BoxConstraints(maxWidth: maxWidth!),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class AppDropdownChip<T> extends StatelessWidget {
  const AppDropdownChip({
    super.key,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onSelected,
    this.maxLabelWidth = 148,
  });

  final T value;
  final List<T> items;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;
  final double maxLabelWidth;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.nightSurfaceAlt
        : Colors.white;

    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem<T>(
            value: item,
            child: Text(labelBuilder(item)),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxLabelWidth),
              child: Text(
                labelBuilder(value),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class ResponsiveWrapGrid extends StatelessWidget {
  const ResponsiveWrapGrid({
    super.key,
    required this.children,
    this.minColumns = 1,
    this.maxColumns = 3,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  final List<Widget> children;
  final int minColumns;
  final int maxColumns;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (children.isEmpty) {
          return const SizedBox.shrink();
        }

        final columns = responsiveColumns(
          constraints.maxWidth,
          min: minColumns,
          max: maxColumns,
        );
        final totalSpacing = spacing * (columns - 1);
        final itemWidth = columns <= 1
            ? constraints.maxWidth
            : (constraints.maxWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(
                width: itemWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class AppDateRangeChip extends StatelessWidget {
  const AppDateRangeChip({
    super.key,
    required this.range,
    required this.onTap,
    this.maxLabelWidth = 140,
  });

  final DashboardDateRange range;
  final VoidCallback onTap;
  final double maxLabelWidth;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.nightSurfaceAlt
        : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxLabelWidth),
              child: Text(
                formatDashboardDateRangeLabel(range),
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

String formatDashboardDateRangeLabel(DashboardDateRange range) {
  final start = DateTime.fromMillisecondsSinceEpoch(range.start);
  final end = DateTime.fromMillisecondsSinceEpoch(range.end);
  if (_isSameDay(start, end)) {
    return toMonthDayLabel(range.start);
  }
  final startLabel = '${_monthShort(start.month)} ${start.day}';
  final endLabel = '${_monthShort(end.month)} ${end.day}';
  if (start.year != end.year) {
    return '$startLabel, ${start.year} - $endLabel, ${end.year}';
  }
  return '$startLabel - $endLabel';
}

Future<DashboardDateRange?> showDashboardDateRangeSheet({
  required BuildContext context,
  required DashboardDateRange initialRange,
}) {
  return showModalBottomSheet<DashboardDateRange>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _DashboardDateRangeSheet(initialRange: initialRange),
  );
}

class _DashboardDateRangeSheet extends StatefulWidget {
  const _DashboardDateRangeSheet({
    required this.initialRange,
  });

  final DashboardDateRange initialRange;

  @override
  State<_DashboardDateRangeSheet> createState() =>
      _DashboardDateRangeSheetState();
}

class _DashboardDateRangeSheetState extends State<_DashboardDateRangeSheet> {
  late DashboardDateRange _draft = _normalizeRange(widget.initialRange);

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final months = _monthsForCalendar(today, count: 60);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final surface = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.nightSurface
        : const Color(0xFFF8F9FD);
    final handle = Theme.of(context).brightness == Brightness.dark
        ? AppPalette.nightLine
        : AppPalette.mist;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 720),
            child: Material(
              color: surface,
              borderRadius: BorderRadius.circular(32),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: handle,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        Expanded(
                          child: Text(
                            formatDashboardDateRangeLabel(_draft),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pop(_normalizeRange(_draft)),
                          child: const Text('Update'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 56,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final preset in DashboardDateRangePreset.values
                            .where((value) => value != DashboardDateRangePreset.custom))
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _PresetChip(
                              label: _presetLabel(preset),
                              selected: _draft.preset == preset,
                              onTap: () => setState(
                                () => _draft = _presetRange(preset),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Choose any past date range. Future dates are disabled.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                      itemCount: months.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: _CalendarMonth(
                          month: months[index],
                          today: today,
                          range: _draft,
                          onDateTap: (date) => setState(
                            () => _draft = _selectDate(_draft, date),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  DashboardDateRange _selectDate(DashboardDateRange current, DateTime date) {
    final tappedValue = DateTime(date.year, date.month, date.day)
        .millisecondsSinceEpoch;
    final normalizedTap = startOfDay(tappedValue);
    final currentStart = current.start;
    final currentEnd = current.end;

    if (currentStart == currentEnd) {
      if (normalizedTap < currentStart) {
        return DashboardDateRange(
          start: normalizedTap,
          end: currentStart,
          preset: DashboardDateRangePreset.custom,
        );
      }
      if (normalizedTap == currentStart) {
        return DashboardDateRange(
          start: normalizedTap,
          end: normalizedTap,
          preset: DashboardDateRangePreset.custom,
        );
      }
      return DashboardDateRange(
        start: currentStart,
        end: normalizedTap,
        preset: DashboardDateRangePreset.custom,
      );
    }

    return DashboardDateRange(
      start: normalizedTap,
      end: normalizedTap,
      preset: DashboardDateRangePreset.custom,
    );
  }

  DashboardDateRange _normalizeRange(DashboardDateRange range) {
    final today = startOfDay(DateTime.now().millisecondsSinceEpoch);
    var start = startOfDay(range.start);
    var end = startOfDay(range.end);
    if (start > today) {
      start = today;
    }
    if (end > today) {
      end = today;
    }
    if (start > end) {
      final previousStart = start;
      start = end;
      end = previousStart;
    }
    return DashboardDateRange(
      start: start,
      end: end,
      preset: range.preset,
    );
  }

  DashboardDateRange _presetRange(DashboardDateRangePreset preset) {
    final today = startOfDay(DateTime.now().millisecondsSinceEpoch);
    final days = switch (preset) {
      DashboardDateRangePreset.custom => 1,
      DashboardDateRangePreset.last7Days => 7,
      DashboardDateRangePreset.last14Days => 14,
      DashboardDateRangePreset.last30Days => 30,
      DashboardDateRangePreset.last90Days => 90,
    };
    return DashboardDateRange(
      start: plusDays(today, -(days - 1)),
      end: today,
      preset: preset,
    );
  }

  String _presetLabel(DashboardDateRangePreset preset) {
    switch (preset) {
      case DashboardDateRangePreset.last7Days:
        return 'Last 7 days';
      case DashboardDateRangePreset.last14Days:
        return 'Last 14 days';
      case DashboardDateRangePreset.last30Days:
        return 'Last 30 days';
      case DashboardDateRangePreset.last90Days:
        return 'Last 90 days';
      case DashboardDateRangePreset.custom:
        return 'Custom';
    }
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.16)
        : (Theme.of(context).brightness == Brightness.dark
            ? AppPalette.nightSurfaceAlt
            : Colors.white);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}

class _CalendarMonth extends StatelessWidget {
  const _CalendarMonth({
    required this.month,
    required this.today,
    required this.range,
    required this.onDateTap,
  });

  final DateTime month;
  final DateTime today;
  final DashboardDateRange range;
  final ValueChanged<DateTime> onDateTap;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final offset = firstDay.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final cells = <DateTime?>[];
    for (var i = 0; i < offset; i++) {
      cells.add(null);
    }
    for (var day = 1; day <= daysInMonth; day++) {
      cells.add(DateTime(month.year, month.month, day));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            toMonthYearLabel(firstDay.millisecondsSinceEpoch),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 18),
        const Row(
          children: [
            _WeekdayHeader('Sun'),
            _WeekdayHeader('Mon'),
            _WeekdayHeader('Tue'),
            _WeekdayHeader('Wed'),
            _WeekdayHeader('Thu'),
            _WeekdayHeader('Fri'),
            _WeekdayHeader('Sat'),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 4,
            childAspectRatio: 0.94,
          ),
          itemBuilder: (context, index) {
            final date = cells[index];
            if (date == null) {
              return const SizedBox.shrink();
            }
            final dayValue = startOfDay(date.millisecondsSinceEpoch);
            final todayValue = startOfDay(today.millisecondsSinceEpoch);
            final disabled = dayValue > todayValue;
            final isStart = dayValue == range.start;
            final isEnd = dayValue == range.end;
            final inRange = dayValue >= range.start && dayValue <= range.end;

            return _CalendarDayCell(
              date: date,
              disabled: disabled,
              isStart: isStart,
              isEnd: isEnd,
              inRange: inRange,
              onTap: disabled ? null : () => onDateTap(date),
            );
          },
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.disabled,
    required this.isStart,
    required this.isEnd,
    required this.inRange,
    this.onTap,
  });

  final DateTime date;
  final bool disabled;
  final bool isStart;
  final bool isEnd;
  final bool inRange;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final highlight = Theme.of(context).colorScheme.primary;
    final inRangeColor = highlight.withValues(alpha: 0.14);
    final textColor = disabled
        ? Theme.of(context).disabledColor
        : (isStart || isEnd
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        decoration: BoxDecoration(
          color: isStart || isEnd
              ? highlight
              : inRange
                  ? inRangeColor
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight:
                      isStart || isEnd ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}

List<DateTime> _monthsForCalendar(DateTime anchor, {required int count}) {
  final months = <DateTime>[];
  final normalized = DateTime(anchor.year, anchor.month, 1);
  for (var i = 0; i < count; i++) {
    months.add(DateTime(normalized.year, normalized.month - i, 1));
  }
  return months;
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _monthShort(int month) {
  const labels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return labels[month - 1];
}
