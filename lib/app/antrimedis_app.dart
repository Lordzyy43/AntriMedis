import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_theme.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/patient/presentation/pages/patient_home_page.dart';
import '../features/queue/data/queue_repository.dart';
import '../features/queue/providers/queue_provider.dart';

class AntriMedisApp extends StatelessWidget {
  const AntriMedisApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository(Supabase.instance.client);
    final queueRepository = QueueRepository(Supabase.instance.client);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository)..bootstrap(),
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
            return auth.isAuthenticated
                ? const PatientHomePage()
                : const LoginPage();
          },
        ),
      ),
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
