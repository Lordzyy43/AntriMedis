import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/config/app_spacing.dart';
import '../../settings/providers/app_settings_provider.dart';

class SecurityGatePage extends StatefulWidget {
  const SecurityGatePage({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<SecurityGatePage> createState() => _SecurityGatePageState();
}

class _SecurityGatePageState extends State<SecurityGatePage> {
  final _pinController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/antrimedis_logo.png',
                    width: 104,
                    height: 104,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Masukkan PIN',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Keamanan aplikasi aktif untuk akun ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: 'PIN keamanan',
                      errorText: _error,
                      prefixIcon: const Icon(Icons.pin_outlined),
                    ),
                    onSubmitted: (_) => _unlock(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _unlock,
                      icon: const Icon(Icons.lock_open_outlined),
                      label: const Text('Buka Beranda'),
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

  void _unlock() {
    final pin = _pinController.text.trim();
    final settings = context.read<AppSettingsProvider>();
    if (settings.verifyPin(pin)) {
      widget.onUnlocked();
      return;
    }
    setState(() => _error = 'PIN belum sesuai');
  }
}
