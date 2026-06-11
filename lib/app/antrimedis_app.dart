import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_colors.dart';
import '../core/config/app_spacing.dart';
import '../core/config/app_theme.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/reset_password_page.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/clinic/data/clinic_repository.dart';
import '../features/clinic/providers/clinic_provider.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/notifications/providers/notification_provider.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/onboarding/presentation/security_gate_page.dart';
import '../features/onboarding/presentation/splash_page.dart';
import '../features/patient/presentation/pages/patient_shell_page.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/presentation/profile_completion_page.dart';
import '../features/profile/providers/profile_provider.dart';
import '../features/queue/data/queue_repository.dart';
import '../features/queue/providers/queue_provider.dart';
import '../features/settings/providers/app_settings_provider.dart';

class AntriMedisApp extends StatelessWidget {
  const AntriMedisApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository(Supabase.instance.client);
    final clinicRepository = ClinicRepository(Supabase.instance.client);
    final notificationRepository = NotificationRepository(
      Supabase.instance.client,
    );
    final profileRepository = ProfileRepository(Supabase.instance.client);
    final queueRepository = QueueRepository(Supabase.instance.client);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository)..bootstrap(),
        ),
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => ClinicProvider(clinicRepository)),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(notificationRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(profileRepository),
        ),
        ChangeNotifierProvider(create: (_) => QueueProvider(queueRepository)),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'AntriMedis',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            home: const _StartupGate(),
          );
        },
      ),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _startupSplashDone = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 5000), () {
      if (!mounted) return;
      setState(() => _startupSplashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final auth = context.watch<AuthProvider>();

    if (!_startupSplashDone || settings.isLoading || auth.isBootstrapping) {
      return const SplashPage();
    }
    if (auth.isPasswordRecovery) {
      return const ResetPasswordPage();
    }
    if (auth.isAuthenticated) {
      return const _ProfileGate();
    }
    if (!settings.hasSeenOnboarding) {
      return const OnboardingPage();
    }
    return const LoginPage();
  }
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate();

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  String? _loadedUserId;
  String? _unlockedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.watch<AuthProvider>().user?.id;
    if (userId == null || userId == _loadedUserId) return;
    _loadedUserId = userId;
    _unlockedUserId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileProvider>().load(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id;
    final profile = context.watch<ProfileProvider>();
    final settings = context.watch<AppSettingsProvider>();

    if (userId == null ||
        profile.loadedUserId != userId ||
        !profile.hasLoaded ||
        profile.isLoading) {
      return const _AccountLoadingPage();
    }
    if (settings.securityEnabled && _unlockedUserId != userId) {
      return SecurityGatePage(
        onUnlocked: () => setState(() => _unlockedUserId = userId),
      );
    }
    return profile.needsCompletion
        ? const ProfileCompletionPage()
        : const PatientShellPage();
  }
}

class _AccountLoadingPage extends StatelessWidget {
  const _AccountLoadingPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoftOf(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderOf(context)),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.primaryDark,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Menyiapkan akun pasien',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Memuat profil dan layanan antrean Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMutedOf(context),
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
