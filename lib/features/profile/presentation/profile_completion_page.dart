import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/config/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_banner.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../queue/providers/queue_provider.dart';
import '../providers/profile_provider.dart';

class ProfileCompletionPage extends StatefulWidget {
  const ProfileCompletionPage({super.key, this.isEditing = false});

  final bool isEditing;

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _birthDate;
  String? _gender;
  bool _hasSeededFields = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;
    final email = context.watch<AuthProvider>().user?.email;

    if (!_hasSeededFields && profile != null) {
      _hasSeededFields = true;
      _nameController.text = profile.fullName;
      _phoneController.text = profile.phoneNumber ?? '';
      _birthDate = profile.birthDate;
      _gender = profile.gender;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Akun Saya' : 'Lengkapi Profil'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            _Header(
              isEditing: widget.isEditing,
              profileName: profile?.fullName,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (profileProvider.error != null) ...[
              AppErrorBanner(message: profileProvider.error!),
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
                      'Data pasien',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Data ini membantu klinik mengenali pasien saat nomor antrean dipanggil.',
                      style: TextStyle(color: AppColors.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      enabled: false,
                      initialValue: email ?? '-',
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nama lengkap',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 3
                          ? 'Nama minimal 3 karakter'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nomor HP',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 8
                          ? 'Nomor HP belum valid'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.wc_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'male',
                          child: Text('Laki-laki'),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Perempuan'),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text('Lainnya'),
                        ),
                      ],
                      onChanged: (value) => setState(() => _gender = value),
                      validator: (value) =>
                          value == null ? 'Pilih gender pasien' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: _pickBirthDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal lahir (opsional)',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                        child: Text(
                          _birthDate == null
                              ? 'Belum diisi'
                              : DateFormat('dd MMMM yyyy').format(_birthDate!),
                          style: TextStyle(
                            color: _birthDate == null
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: profileProvider.isSaving ? null : _submit,
                        icon: profileProvider.isSaving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          widget.isEditing
                              ? 'Simpan Perubahan'
                              : 'Simpan & Lanjutkan',
                        ),
                      ),
                    ),
                    if (widget.isEditing) ...[
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: profileProvider.isSaving ? null : _signOut,
                          icon: const Icon(Icons.logout),
                          label: const Text('Keluar'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await context.read<ProfileProvider>().updateProfile(
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      gender: _gender!,
      birthDate: _birthDate,
    );
    if (!mounted || !ok || !widget.isEditing) return;
    Navigator.of(context).pop();
  }

  Future<void> _signOut() async {
    final queueProvider = context.read<QueueProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final authProvider = context.read<AuthProvider>();
    await queueProvider.clearForSignOut();
    notificationProvider.clear();
    profileProvider.clear();
    await authProvider.signOut();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isEditing, required this.profileName});

  final bool isEditing;
  final String? profileName;

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
            Icons.person_outline,
            color: AppColors.primaryDark,
            size: 30,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          isEditing ? 'Kelola akun pasien.' : 'Satu langkah lagi.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isEditing
              ? 'Perbarui data yang digunakan klinik untuk mengenali pasien.'
              : profileName == null || profileName!.isEmpty
              ? 'Lengkapi profil pasien sebelum mengambil nomor antrean.'
              : 'Halo, $profileName. Lengkapi data pasien sebelum mengambil nomor antrean.',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 16,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
