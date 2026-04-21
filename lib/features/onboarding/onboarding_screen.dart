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
    return AppSurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: dark ? AppPalette.nightSurfaceAlt : data.softAccent,
                borderRadius: BorderRadius.circular(34),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 26,
                    right: 28,
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: data.accent.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    bottom: 26,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: data.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(38),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 26,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Icon(
                        data.icon,
                        size: 60,
                        color: data.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
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
                  width: 10,
                  height: 10,
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
                    style: Theme.of(context).textTheme.bodyMedium,
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
