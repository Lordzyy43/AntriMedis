import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/config/app_spacing.dart';
import '../../settings/providers/app_settings_provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _OnboardingData(
      icon: Icons.confirmation_number_outlined,
      title: 'Ambil Nomor dari Ponsel',
      body:
          'Pilih poli dan dokter, lalu ambil nomor antrean untuk sesi hari ini.',
    ),
    _OnboardingData(
      icon: Icons.monitor_heart_outlined,
      title: 'Pantau Giliran Real-Time',
      body:
          'Lihat nomor berjalan, posisi antrean, dan estimasi tunggu tanpa menebak-nebak.',
    ),
    _OnboardingData(
      icon: Icons.notifications_active_outlined,
      title: 'Notifikasi Saat Mendekat',
      body:
          'Aplikasi membantu mengingatkan saat antrean Anda mulai dekat dipanggil.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Lewati'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF123F44)
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Text(
                  'Antrean real-time klinik',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: AppColors.borderOf(context),
                            ),
                            boxShadow: isDark
                                ? const []
                                : const [
                                    BoxShadow(
                                      color: Color(0x120F172A),
                                      blurRadius: 28,
                                      offset: Offset(0, 14),
                                    ),
                                  ],
                          ),
                          child: Icon(
                            page.icon,
                            color: isDark ? AppColors.primary : AppColors.primaryDark,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMutedOf(context),
                            height: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  final active = index == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: active ? 26 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLast ? _finish : _next,
                  icon: Icon(
                    isLast ? Icons.check_circle_outline : Icons.arrow_forward,
                  ),
                  label: Text(isLast ? 'Mulai' : 'Lanjut'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    await context.read<AppSettingsProvider>().markOnboardingSeen();
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
