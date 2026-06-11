import 'package:flutter/material.dart';
import 'dart:async';

import '../../../core/config/app_colors.dart';
import '../../../core/config/app_spacing.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  // Koreografi Animasi Cinematic
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _glowScale;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _textLetterSpacing;
  late final Animation<double> _indicatorOpacity;
  late final Animation<Offset> _indicatorSlide;

  @override
  void initState() {
    super.initState();
    _setupCinematicAnimations();
    _initializeApp();
  }

  void _setupCinematicAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // 1. Efek Pendaran Cahaya (Ambient Glow) di Belakang Logo
    _glowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _glowScale = Tween<double>(begin: 0.6, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Animasi Logo Transparan
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Efek Teks Cinematic (Renggang -> Merapat Elegan)
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    _textLetterSpacing = Tween<double>(begin: 6.0, end: -0.8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOutCubic),
      ),
    );

    // 4. Indikator Progress Tipis di Bawah
    _indicatorOpacity = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );
    _indicatorSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    await Future.wait([Future.delayed(const Duration(milliseconds: 2400)), _checkUserSession()]);

    if (!mounted) return;

    // Panggil rute halaman utama/login kamu di sini
    // Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _checkUserSession() async {}

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: RepaintBoundary(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [Color(0xFF0F172A), Color(0xFF0B1120)]
                  : [AppColors.surfaceOf(context), AppColors.backgroundOf(context)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),

                // --- AREA LOGO DENGAN AMBIENT GLOW ---
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Lapisan Glow Belakang (Sekarang murni pakai hiasan BoxShadow bulat)
                    FadeTransition(
                      opacity: _glowOpacity,
                      child: ScaleTransition(
                        scale: _glowScale,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.20),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Lapisan Utama Logo Transparan
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: SizedBox(
                          width: 110,
                          height: 110,
                          child: Image.asset(
                            'assets/images/AntriMedis_tr.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),

                // --- NAMA APLIKASI DENGAN ANIMATED LETTER SPACING ---
                FadeTransition(
                  opacity: _textOpacity,
                  child: AnimatedBuilder(
                    animation: _textLetterSpacing,
                    builder: (context, child) {
                      return Text(
                        'AntriMedis',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.textPrimaryOf(context),
                          fontWeight: FontWeight.w900,
                          fontSize: 34,
                          letterSpacing: _textLetterSpacing.value,
                        ),
                      );
                    },
                  ),
                ),

                const Spacer(flex: 4),

                // --- INDIKATOR PROGRESS SLIDE & FADE IN ---
                FadeTransition(
                  opacity: _indicatorOpacity,
                  child: SlideTransition(
                    position: _indicatorSlide,
                    child: const _MinimalIndicator(),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MinimalIndicator extends StatelessWidget {
  const _MinimalIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 40,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.primary,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }
}
