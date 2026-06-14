import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/config/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/providers/auth_provider.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(title: const Text('Ubah Password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const _SettingsHeader(
              icon: Icons.lock_reset_outlined,
              title: 'Password Baru',
              subtitle:
                  'Gunakan password kuat agar akun antrean pasien tetap aman.',
            ),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password baru',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Tampilkan password'
                              : 'Sembunyikan password',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 8
                          ? 'Password minimal 8 karakter'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Ulangi password baru',
                        prefixIcon: const Icon(Icons.lock_person_outlined),
                        suffixIcon: IconButton(
                          tooltip: _obscureConfirm
                              ? 'Tampilkan password'
                              : 'Sembunyikan password',
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => value != _passwordController.text
                          ? 'Konfirmasi password belum sama'
                          : null,
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
    final saved = await context.read<AuthProvider>().updatePassword(
      _passwordController.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Password berhasil diperbarui.'
              : context.read<AuthProvider>().error ??
                    'Password belum bisa diperbarui.',
        ),
      ),
    );
    if (saved) Navigator.of(context).pop();
  }
}

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(title: const Text('Bantuan dan Dukungan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const _SettingsHeader(
              icon: Icons.support_agent_outlined,
              title: 'Pusat Bantuan',
              subtitle: 'Temukan jawaban cepat atau kontak klinik saat perlu.',
            ),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.quiz_outlined,
                    title: 'FAQ',
                    subtitle: 'Pertanyaan umum seputar antrean online.',
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const FaqPage())),
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.chat_outlined,
                    title: 'WhatsApp Klinik',
                    subtitle: 'Lihat nomor WhatsApp layanan klinik.',
                    onTap: () => _showInfoDialog(
                      context,
                      title: 'WhatsApp Klinik',
                      message:
                          'Hubungi WhatsApp Klinik Sehat Sentosa di 0812-3456-7890 untuk bantuan antrean.',
                    ),
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.bug_report_outlined,
                    title: 'Laporkan Bug',
                    subtitle:
                        'Kontak yang bisa dihubungi saat aplikasi bermasalah.',
                    onTap: () => _showInfoDialog(
                      context,
                      title: 'Laporkan Bug',
                      message:
                          'Jika mengalami kendala aplikasi, hubungi admin klinik melalui WhatsApp 0812-3456-7890 atau email support@antrimedis.local.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  static const _items = [
    (
      'Apakah nomor antrean berlaku untuk besok?',
      'Tidak. Nomor antrean berlaku untuk jadwal layanan hari yang sama.',
    ),
    (
      'Kapan saya boleh mengambil nomor?',
      'Nomor bisa diambil saat jadwal hari ini tersedia dan kuota masih ada.',
    ),
    (
      'Bagaimana jika antrean saya dipanggil?',
      'Pantau notifikasi dan segera bersiap menuju poli saat giliran mendekat.',
    ),
    (
      'Bisakah antrean dibatalkan?',
      'Bisa, selama tiket masih aktif. Tiket yang dibatalkan tidak dapat dipakai kembali.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(title: const Text('FAQ')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.xl),
          itemCount: _items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final item = _items[index];
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$1,
                    style: TextStyle(
                      color: AppColors.textPrimaryOf(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    item.$2,
                    style: TextStyle(
                      color: AppColors.textMutedOf(context),
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class AboutMenuPage extends StatelessWidget {
  const AboutMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(title: const Text('Tentang')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const _SettingsHeader(
              icon: Icons.info_outline,
              title: 'Tentang AntriMedis',
              subtitle: 'Informasi aplikasi dan kebijakan penggunaan data.',
            ),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.apps_outlined,
                    title: 'Tentang Aplikasi',
                    subtitle: 'Detail fungsi dan tujuan AntriMedis.',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AppDetailPage()),
                    ),
                  ),
                  const Divider(height: 1),
                  _SettingsTile(
                    icon: Icons.policy_outlined,
                    title: 'Kebijakan dan Privasi',
                    subtitle: 'Cara aplikasi menggunakan data pasien.',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppDetailPage extends StatelessWidget {
  const AppDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TextDetailPage(
      title: 'Tentang Aplikasi',
      icon: Icons.apps_outlined,
      heading: 'AntriMedis',
      body:
          'AntriMedis adalah aplikasi pasien untuk mengambil nomor antrean klinik, memantau nomor berjalan secara real-time, melihat jumlah antrean di depan pengguna, dan menerima notifikasi saat giliran mendekat.',
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TextDetailPage(
      title: 'Kebijakan dan Privasi',
      icon: Icons.policy_outlined,
      heading: 'Privasi Pengguna',
      body:
          'Data profil pasien digunakan untuk verifikasi antrean, penyesuaian layanan klinik, dan riwayat kunjungan. Aplikasi hanya menampilkan data sesuai akun yang sedang login. Hindari membagikan password atau PIN keamanan kepada orang lain. Untuk demo MVP, informasi kontak dukungan masih bersifat internal klinik.',
    );
  }
}

class _TextDetailPage extends StatelessWidget {
  const _TextDetailPage({
    required this.title,
    required this.icon,
    required this.heading,
    required this.body,
  });

  final String title;
  final IconData icon;
  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            _SettingsHeader(icon: icon, title: heading, subtitle: title),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              child: Text(
                body,
                style: TextStyle(
                  color: AppColors.textMutedOf(context),
                  height: 1.55,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoftOf(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.primaryDark),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textMutedOf(context),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primarySoftOf(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: AppColors.primaryDark, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimaryOf(context),
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.textMutedOf(context)),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
