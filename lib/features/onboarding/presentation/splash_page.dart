import 'package:flutter/material.dart';
import 'dart:async';

import '../../../core/config/app_colors.dart';
import '../../../core/config/app_spacing.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Definisi Animasi
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _panelOpacity;
  late Animation<Offset> _panelSlide;
  late Animation<double> _loadingOpacity;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800), // Total durasi animasi
    );

    // 1. Animasi Logo (Muncul duluan dengan efek membesar)
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // 2. Animasi Judul & Subjudul (Muncul dari bawah ke atas)
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
          ),
        );

    // 3. Animasi Panel Status
    _panelOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );
    _panelSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    // 4. Animasi Loading
    _loadingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    // Jalankan animasi
    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    // TODO: Ganti dengan logika inisialisasi sungguhan (fetch token, check session, dsb)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // TODO: Navigasi ke Halaman Utama / Login
    // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF07111F) : AppColors.background,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0xFF07111F),
                    Color(0xFF0B1F2A),
                    Color(0xFF0F2F2E),
                  ]
                : const [
                    Color(0xFFF7FCFD),
                    Color(0xFFEAF8F8),
                    Color(0xFFDFF5F3),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // --- BRAND MARK BERANIMASI ---
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: _BrandMark(isDark: isDark),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // --- TEKS BERANIMASI ---
                    FadeTransition(
                      opacity: _textOpacity,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          children: [
                            Text(
                              'AntriMedis',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Layanan antrean klinik yang rapi, cepat, dan mudah dipantau.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFBFEDEA)
                                    : AppColors.textMuted,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // --- STATUS PANEL BERANIMASI ---
                    FadeTransition(
                      opacity: _panelOpacity,
                      child: SlideTransition(
                        position: _panelSlide,
                        child: _StatusPanel(isDark: isDark),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // --- LOADING BERANIMASI ---
                    FadeTransition(
                      opacity: _loadingOpacity,
                      child: _LoadingLine(isDark: isDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Komponen UI di bawah ini tidak berubah secara logika,
// hanya menerima efek animasi dari parent-nya.
// ============================================================================

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.92),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.22)
                : AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE6F4F1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Image.asset(
            'assets/images/antrimedis_logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          _StatusItem(
            logoAsset: 'assets/images/antrimedis_logo.png',
            title: 'Klinik Sehat Sentosa',
            subtitle: 'Sinkronisasi layanan antrean',
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.md),
          _StatusItem(
            icon: Icons.security_outlined,
            title: 'Akses pasien aman',
            subtitle: 'Memeriksa sesi dan preferensi aplikasi',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({
    this.icon,
    this.logoAsset,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final IconData? icon;
  final String? logoAsset;
  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF123F44) : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: logoAsset == null
              ? Icon(
                  icon,
                  color: isDark ? AppColors.primary : AppColors.primaryDark,
                  size: 21,
                )
              : Padding(
                  padding: const EdgeInsets.all(7),
                  child: Image.asset(logoAsset!, fit: BoxFit.contain),
                ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? const Color(0xFFC9DCE0) : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: isDark ? AppColors.primary : AppColors.primaryDark,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : AppColors.primarySoft,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Menyiapkan layanan...',
            style: TextStyle(
              color: isDark ? const Color(0xFFC9DCE0) : AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
