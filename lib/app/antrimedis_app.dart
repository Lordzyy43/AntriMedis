import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_theme.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/reset_password_page.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/clinic/data/clinic_repository.dart';
import '../features/clinic/providers/clinic_provider.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/notifications/providers/notification_provider.dart';
import '../features/patient/presentation/pages/patient_shell_page.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/presentation/profile_completion_page.dart';
import '../features/profile/providers/profile_provider.dart';
import '../features/queue/data/queue_repository.dart';
import '../features/queue/providers/queue_provider.dart';

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
        ChangeNotifierProvider(create: (_) => ClinicProvider(clinicRepository)),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(notificationRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(profileRepository),
        ),
        ChangeNotifierProvider(create: (_) => QueueProvider(queueRepository)),
      ],
      child: MaterialApp(
        title: 'AntriMedis',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isBootstrapping) {
              return const _SplashPage();
            }
            if (auth.isPasswordRecovery) {
              return const ResetPasswordPage();
            }
            return auth.isAuthenticated
                ? const _ProfileGate()
                : const LoginPage();
          },
        ),
      ),
    );
  }
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate();

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  String? _loadedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.watch<AuthProvider>().user?.id;
    if (userId == null || userId == _loadedUserId) return;
    _loadedUserId = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileProvider>().load(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id;
    final profile = context.watch<ProfileProvider>();
    if (userId == null ||
        profile.loadedUserId != userId ||
        !profile.hasLoaded ||
        profile.isLoading) {
      return const _SplashPage();
    }
    return profile.needsCompletion
        ? const ProfileCompletionPage()
        : const PatientShellPage();
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
