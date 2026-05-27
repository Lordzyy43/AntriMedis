import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/config/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_banner.dart';
import '../providers/auth_provider.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Password Baru')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const _ResetHeader(),
            const SizedBox(height: AppSpacing.xl),
            if (auth.error != null) ...[
              AppErrorBanner(message: auth.error!),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (auth.notice != null) ...[
              _ResetNotice(message: auth.notice!),
              const SizedBox(height: AppSpacing.lg),
            ],
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atur ulang password',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Gunakan password baru yang aman untuk akun pasien Anda.',
                      style: TextStyle(color: AppColors.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration:
                          const InputDecoration(
                            labelText: 'Password baru',
                            prefixIcon: Icon(Icons.lock_outline),
                          ).copyWith(
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Tampilkan password'
                                  : 'Sembunyikan password',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration:
                          const InputDecoration(
                            labelText: 'Konfirmasi password',
                            prefixIcon: Icon(Icons.lock_reset_outlined),
                          ).copyWith(
                            suffixIcon: IconButton(
                              tooltip: _obscureConfirmPassword
                                  ? 'Tampilkan password'
                                  : 'Sembunyikan password',
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: auth.isLoading ? null : _submit,
                        icon: auth.isLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: const Text('Simpan Password'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthProvider>().updatePassword(_passwordController.text);
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) return 'Password minimal 8 karakter';
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'Gunakan kombinasi huruf dan angka';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Konfirmasi password belum sama';
    }
    return null;
  }
}

class _ResetHeader extends StatelessWidget {
  const _ResetHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: const Icon(
            Icons.lock_reset_outlined,
            color: AppColors.primaryDark,
            size: 30,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Pulihkan akses akun.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Masukkan password baru setelah membuka link reset dari email.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 16,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _ResetNotice extends StatelessWidget {
  const _ResetNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.successSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.success),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
