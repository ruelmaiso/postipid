import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_theme.dart';
import '../../core/widgets/app_frame.dart';
import '../app/app_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _index = 0;

  static const List<_OnboardingData> _pages = [
    _OnboardingData(
      title: 'Welcome to TipidPOS',
      description:
          'Practical retail workspace for sari-sari and small-store daily operations.',
      accent: AppPalette.emerald,
      softAccent: AppPalette.emeraldSoft,
      icon: Icons.storefront_rounded,
      bullets: [
        'Use the drawer to move across dashboard, POS, inventory, activity, and settings.',
        'Keep checkout fast: search or scan, confirm cart, then print receipt.',
      ],
    ),
    _OnboardingData(
      title: 'Set Up Your Store First',
      description:
          'Complete store details, receipt text, printer, and paper size before first sale.',
      accent: AppPalette.primary,
      softAccent: AppPalette.lilacSoft,
      icon: Icons.tune_rounded,
      bullets: [
        'Match paper size so preview and actual print output stay aligned.',
        'Set low-stock threshold early to avoid missed refill alerts.',
      ],
    ),
    _OnboardingData(
      title: 'Sell Fast With Search Or Scan',
      description:
          'Maintain product accuracy and run a clean, low-friction checkout flow.',
      accent: AppPalette.amber,
      softAccent: AppPalette.amberSoft,
      icon: Icons.qr_code_scanner_rounded,
      bullets: [
        'Update stock after deliveries so totals and profit stay reliable.',
        'Use Credit only for unpaid balances, then settle in Activity.',
      ],
    ),
    _OnboardingData(
      title: 'Cashier Mode: 3-Step Quick Start',
      description: 'Use this flow for fast peak-hour checkout.',
      accent: AppPalette.ocean,
      softAccent: AppPalette.oceanSoft,
      icon: Icons.point_of_sale_rounded,
      bullets: [
        '1) Search or scan item, then confirm quantity.',
        '2) Enter cash and verify change before payment.',
        '3) Tap Print after checkout when customer asks.',
      ],
    ),
    _OnboardingData(
      title: 'Owner Mode: End-Of-Day Routine',
      description: 'Use this mini-checklist before closing the store.',
      accent: AppPalette.coral,
      softAccent: AppPalette.coralSoft,
      icon: Icons.fact_check_rounded,
      bullets: [
        'Review credits and settle fully paid balances.',
        'Check low-stock and out-of-stock items for restock.',
        'Export backup after major edits or before app updates.',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lastPage = _index == _pages.length - 1;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: Theme.of(context).brightness == Brightness.dark
            ? AppPalette.darkShellGradient
            : AppPalette.shellGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    const AppBrandMark(showLabel: true),
                    const Spacer(),
                    if (!lastPage)
                      TextButton(
                        onPressed: _finish,
                        child: const Text('Skip'),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (context, index) => _OnboardingCard(data: _pages[index]),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == _index ? 34 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _index
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _index > 0
                            ? () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            : null,
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (lastPage) {
                            _finish();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                        child: Text(lastPage ? 'Start Using App' : 'Continue'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _finish() async {
    await context.read<TipidPosController>().completeOnboarding();
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.data});

  final _OnboardingData data;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: dark ? AppPalette.nightSurfaceAlt : data.softAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              data.icon,
              size: 30,
              color: data.accent,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            data.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            data.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          for (final bullet in data.bullets) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: data.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bullet,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            if (bullet != data.bullets.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.description,
    required this.accent,
    required this.softAccent,
    required this.icon,
    required this.bullets,
  });

  final String title;
  final String description;
  final Color accent;
  final Color softAccent;
  final IconData icon;
  final List<String> bullets;
}
