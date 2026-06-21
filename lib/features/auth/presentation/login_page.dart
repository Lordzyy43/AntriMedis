import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/config/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_banner.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isRegister = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    context.read<AuthProvider>().clearMessages();
    setState(() {
      _isRegister = !_isRegister;
      _nameController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      // Reset form validation saat berpindah mode
      _formKey.currentState?.reset();
      _obscurePassword = true;
      _obscureConfirmPassword = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (AppSpacing.lg * 2),
                ),
                child: Center(
                  child: Container(
                    // Membatasi lebar maksimal card agar tetap proporsional di tablet/layar lebar
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (auth.error != null) ...[
                          AppErrorBanner(message: auth.error!),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (auth.notice != null) ...[
                          _AuthNotice(message: auth.notice!),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        
                        // Card Utama dengan Animasi Ukuran saat Form Berubah
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: AppCard(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const _LoginHeader(),
                                  const SizedBox(height: AppSpacing.xl),
                                  
                                  // Judul Keterangan Mode Form
                                  Text(
                                    _isRegister ? 'Daftar Akun Pasien' : 'Masuk Akun Pasien',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    _isRegister
                                        ? 'Buat akun baru untuk mengambil nomor antrean online.'
                                        : 'Silakan masuk dengan akun yang sudah terdaftar.',
                                    style: const TextStyle(
                                      color: AppColors.textMuted, 
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                  
                                  // Field: Nama Lengkap (Hanya muncul saat Register dengan Animasi)
                                  AnimatedCrossFade(
                                    firstChild: const SizedBox.shrink(),
                                    secondChild: Padding(
                                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                      child: TextFormField(
                                        controller: _nameController,
                                        textInputAction: TextInputAction.next,
                                        keyboardType: TextInputType.name,
                                        autofillHints: const [AutofillHints.name],
                                        decoration: const InputDecoration(
                                          labelText: 'Nama Lengkap',
                                          prefixIcon: Icon(Icons.badge_outlined, size: 22),
                                        ),
                                        validator: (value) {
                                          if (!_isRegister) return null;
                                          return value == null || value.trim().length < 3
                                              ? 'Nama minimal 3 karakter'
                                              : null;
                                        },
                                      ),
                                    ),
                                    crossFadeState: _isRegister
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                    duration: const Duration(milliseconds: 200),
                                  ),
                                  
                                  // Field: Email
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.mail_outline, size: 22),
                                    ),
                                    validator: _validateEmail,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  
                                  // Field: Password
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: _isRegister
                                        ? TextInputAction.next
                                        : TextInputAction.done,
                                    autofillHints: [
                                      _isRegister
                                          ? AutofillHints.newPassword
                                          : AutofillHints.password,
                                    ],
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(Icons.lock_outline, size: 22),
                                      suffixIcon: IconButton(
                                        tooltip: _obscurePassword
                                            ? 'Tampilkan password'
                                            : 'Sembunyikan password',
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 22,
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                    validator: _validatePassword,
                                    onFieldSubmitted: (_) {
                                      if (!_isRegister) _submit();
                                    },
                                  ),
                                  
                                  // Field: Konfirmasi Password (Hanya muncul saat Register dengan Animasi)
                                  AnimatedCrossFade(
                                    firstChild: const SizedBox.shrink(),
                                    secondChild: Padding(
                                      padding: const EdgeInsets.only(top: AppSpacing.md),
                                      child: TextFormField(
                                        controller: _confirmPasswordController,
                                        obscureText: _obscureConfirmPassword,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [AutofillHints.newPassword],
                                        decoration: InputDecoration(
                                          labelText: 'Konfirmasi Password',
                                          prefixIcon: const Icon(Icons.lock_reset_outlined, size: 22),
                                          suffixIcon: IconButton(
                                            tooltip: _obscureConfirmPassword
                                                ? 'Tampilkan password'
                                                : 'Sembunyikan password',
                                            icon: Icon(
                                              _obscureConfirmPassword
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              size: 22,
                                            ),
                                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (!_isRegister) return null;
                                          return _validateConfirmPassword(value);
                                        },
                                        onFieldSubmitted: (_) => _submit(),
                                      ),
                                    ),
                                    crossFadeState: _isRegister
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                    duration: const Duration(milliseconds: 200),
                                  ),
                                  
                                  // Tombol Lupa Password
                                  if (!_isRegister) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(50, 30),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: auth.isLoading ? null : _forgotPassword,
                                        child: const Text(
                                          'Lupa password?',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.xl),

                                  if (_isRegister) ...[
                                    _VerificationHint(
                                      email: _emailController.text.trim(),
                                      onResend:
                                          auth.isLoading || !_canResendVerification
                                          ? null
                                          : () => _resendVerification(),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                  
                                  // Tombol Submit Utama
                                  ElevatedButton.icon(
                                    onPressed: auth.isLoading ? null : _submit,
                                    icon: auth.isLoading
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(_isRegister ? Icons.person_add_alt_1 : Icons.login),
                                    label: Text(_isRegister ? 'Daftar Sekarang' : 'Masuk'),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  const _AuthDivider(),
                                  const SizedBox(height: AppSpacing.lg),
                                  
                                  // Tombol Google OAuth
                                  OutlinedButton.icon(
                                    onPressed: auth.isLoading ? null : _signInWithGoogle,
                                    icon: const Icon(Icons.g_mobiledata, size: 28),
                                    label: const Text('Lanjutkan dengan Google'),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  
                                  // Pindah Mode (Login / Register)
                                  TextButton(
                                    onPressed: auth.isLoading ? null : _toggleAuthMode,
                                    child: Text(
                                      _isRegister
                                          ? 'Sudah punya akun? Masuk di sini'
                                          : 'Belum punya akun? Daftar Pasien Baru',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (_isRegister) {
      await auth.signUp(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      await auth.signIn(_emailController.text.trim(), _passwordController.text);
    }
  }

  Future<void> _forgotPassword() async {
    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      _showSnack(emailError);
      return;
    }
    await context.read<AuthProvider>().sendPasswordReset(
      _emailController.text.trim(),
    );
  }

  Future<void> _signInWithGoogle() async {
    await context.read<AuthProvider>().signInWithGoogle();
  }

  Future<void> _resendVerification() async {
    final email = _emailController.text.trim();
    final emailError = _validateEmail(email);
    if (emailError != null) {
      _showSnack(emailError);
      return;
    }

    await context.read<AuthProvider>().resendSignupConfirmation(email);
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(email)) return 'Email belum valid';
    return null;
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

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _canResendVerification {
    final emailError = _validateEmail(_emailController.text);
    return emailError == null && _emailController.text.trim().isNotEmpty;
  }
}

// Header Logo & Brand Terpusat di Dalam Card
class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderOf(context)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A0EA5A4),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/AntriMedis_tr.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'AntriMedis',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }
}

class _AuthNotice extends StatelessWidget {
  const _AuthNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.successSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success),
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

class _VerificationHint extends StatelessWidget {
  const _VerificationHint({
    required this.email,
    required this.onResend,
  });

  final String email;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.primarySoftOf(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perlu verifikasi email',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            email.isEmpty
                ? 'Isi email dulu agar kami bisa kirim link verifikasi.'
                : 'Link verifikasi akan dikirim ke $email. Setelah dibuka, akun siap dipakai dan Anda bisa kembali ke aplikasi untuk masuk.',
            style: const TextStyle(
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onResend,
              icon: const Icon(Icons.mark_email_unread_outlined, size: 18),
              label: const Text('Kirim ulang email verifikasi'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthDivider extends StatelessWidget {
  const _AuthDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'atau',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}
