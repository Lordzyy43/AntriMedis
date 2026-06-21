import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/config/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_banner.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../queue/providers/queue_provider.dart';
import '../../settings/providers/app_settings_provider.dart';
import 'app_settings_pages.dart';
import '../data/models/patient_profile.dart';
import '../providers/profile_provider.dart';

class ProfileCompletionPage extends StatefulWidget {
  const ProfileCompletionPage({
    super.key,
    this.isEditing = false,
    this.closeAfterSave = false,
  });

  final bool isEditing;
  final bool closeAfterSave;

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _imagePicker = ImagePicker();

  DateTime? _birthDate;
  String? _gender;
  bool _hasSeededFields = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  // Helper untuk menghitung progres pengisian field secara realtime di UI
  double _calculateCurrentProgress() {
    var completed = 0;
    if (_nameController.text.trim().length >= 3) completed++;
    if (_phoneController.text.trim().isNotEmpty) completed++;
    if (_gender != null && _gender!.trim().isNotEmpty) completed++;
    if (_birthDate != null) completed++;
    return (completed / 4).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final profile = profileProvider.profile;
    final user = context.watch<AuthProvider>().user;
    final email = user?.userMetadata?['email'] as String? ?? user?.email;
    final googleAvatarUrl =
        user?.userMetadata?['avatar_url'] as String? ??
        user?.userMetadata?['picture'] as String?;

    if (!_hasSeededFields && profile != null) {
      _hasSeededFields = true;
      _nameController.text = profile.fullName;
      _phoneController.text = profile.phoneNumber ?? '';
      _birthDate = profile.birthDate;
      _gender = profile.gender;
    }

    // Mengambil nilai progres dinamis berdasarkan inputan form saat ini
    final currentProgress = _calculateCurrentProgress();

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedProfileHeader(
              child: _CleanProfileHeader(
                title: widget.isEditing ? 'Profil Pasien' : 'Lengkapi Profil',
                statusLabel: currentProgress == 1.0
                    ? 'Profil lengkap'
                    : 'Perlu dilengkapi',
                statusDetail: widget.isEditing
                    ? 'Kelola data dan keamanan akun pasien.'
                    : 'Lengkapi data dasar untuk melanjutkan.',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              112,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  // Header yang menampung info persentase dinamis tunggal
                  _Header(
                    isEditing: widget.isEditing,
                    profile: profile,
                    email: email,
                    googleAvatarUrl: googleAvatarUrl,
                    isAvatarSaving: profileProvider.isAvatarSaving,
                    onChangeAvatar: _showAvatarPicker,
                    currentProgress: currentProgress,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (profileProvider.error != null) ...[
                    AppErrorBanner(message: profileProvider.error!),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // _ProfileCompletionNotice ganda yang sebelumnya di sini telah dihapus total
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _CardTitle(
                            icon: Icons.assignment_ind_outlined,
                            title: 'Data Pribadi',
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
                            onChanged: (_) =>
                                setState(() {}), // Memicu update persentase di header
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
                            onChanged: (_) =>
                                setState(() {}), // Memicu update persentase di header
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
                            ],
                            onChanged: (value) => setState(() => _gender = value),
                            validator: (value) =>
                                value == null ? 'Pilih gender pasien' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _pickBirthDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Tanggal lahir (opsional)',
                                prefixIcon: Icon(Icons.cake_outlined),
                              ),
                              child: Text(
                                _birthDate == null
                                    ? 'Belum diisi'
                                    : DateFormat(
                                        'dd MMMM yyyy',
                                      ).format(_birthDate!),
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
                              onPressed: profileProvider.isSaving
                                  ? null
                                  : _submit,
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
                        ],
                      ),
                    ),
                  ),
                  if (widget.isEditing) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _AccountActionPanel(
                      onChangePassword: _showChangePasswordSheet,
                      onSecurity: _showSecuritySheet,
                      onSupport: _showSupportSheet,
                      onAbout: _showAboutSheet,
                      onSignOut: _confirmSignOut,
                      isLoading: context.watch<AuthProvider>().isLoading,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil pasien berhasil disimpan.')),
    );
    if (widget.closeAfterSave) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showChangePasswordSheet() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChangePasswordPage()));
  }

  Future<void> _showAvatarPicker() async {
    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final hasAvatar =
            context.read<ProfileProvider>().profile?.avatarUrl?.isNotEmpty ??
            false;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ubah avatar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                _AvatarActionTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Pilih dari galeri',
                  subtitle: 'Gunakan foto yang sudah ada di perangkat.',
                  onTap: () => Navigator.of(context).pop(_AvatarAction.gallery),
                ),
                _AvatarActionTile(
                  icon: Icons.photo_camera_outlined,
                  title: 'Ambil foto',
                  subtitle: 'Buka kamera untuk foto pasien terbaru.',
                  onTap: () => Navigator.of(context).pop(_AvatarAction.camera),
                ),
                if (hasAvatar)
                  _AvatarActionTile(
                    icon: Icons.delete_outline,
                    title: 'Hapus avatar',
                    subtitle: 'Kembali gunakan inisial nama pasien.',
                    isDanger: true,
                    onTap: () =>
                        Navigator.of(context).pop(_AvatarAction.remove),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null) return;
    switch (action) {
      case _AvatarAction.gallery:
        await _pickAndUploadAvatar(ImageSource.gallery);
      case _AvatarAction.camera:
        await _pickAndUploadAvatar(ImageSource.camera);
      case _AvatarAction.remove:
        await _confirmRemoveAvatar();
    }
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final XFile? picked;
    try {
      picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 88,
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyPickerError(error))));
      return;
    }
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 2 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ukuran avatar maksimal 2 MB. Pilih foto lain.'),
        ),
      );
      return;
    }

    final ok = await context.read<ProfileProvider>().uploadAvatar(
      bytes: bytes,
      extension: _extensionFromName(picked.name),
    );
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar berhasil diperbarui.')),
    );
  }

  Future<void> _confirmRemoveAvatar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus avatar?'),
          content: const Text(
            'Foto profil akan diganti dengan inisial nama pasien.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (ok != true || !mounted) return;
    final removed = await context.read<ProfileProvider>().removeAvatar();
    if (!mounted || !removed) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Avatar berhasil dihapus.')));
  }

  String _extensionFromName(String name) {
    final parts = name.split('.');
    if (parts.length < 2) return 'jpg';
    return parts.last;
  }

  String _friendlyPickerError(PlatformException error) {
    final code = error.code.toLowerCase();
    if (code.contains('camera_access_denied') ||
        code.contains('photo_access_denied') ||
        code.contains('permission')) {
      return 'Izin kamera atau galeri belum diberikan. Aktifkan izin aplikasi di pengaturan pengaturan perangkat.';
    }
    return 'Avatar belum bisa dipilih. Coba gunakan foto lain atau ulangi beberapa saat lagi.';
  }

  Future<void> _showSecuritySheet() async {
    final settings = context.read<AppSettingsProvider>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardTitle(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Keamanan dan Privasi',
                ),
                const SizedBox(height: AppSpacing.lg),
                Consumer<AppSettingsProvider>(
                  builder: (context, settings, _) {
                    return _AccountActionTile(
                      icon: settings.securityEnabled
                          ? Icons.lock_outline
                          : Icons.lock_open_outlined,
                      title: settings.securityEnabled
                          ? 'PIN keamanan aktif'
                          : 'PIN keamanan belum aktif',
                      subtitle: settings.securityEnabled
                          ? 'Ubah atau matikan PIN keamanan aplikasi.'
                          : 'Atur PIN 4-6 digit untuk melindungi akses beranda.',
                      onTap: () => _showPinSetupSheet(),
                    );
                  },
                ),
                Consumer<AppSettingsProvider>(
                  builder: (context, settings, _) {
                    if (!settings.securityEnabled) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        const Divider(height: 1),
                        _AccountActionTile(
                          icon: Icons.no_encryption_outlined,
                          title: 'Matikan PIN',
                          subtitle: 'Hapus verifikasi sebelum masuk beranda.',
                          isDanger: true,
                          onTap: () async {
                            await context
                                .read<AppSettingsProvider>()
                                .clearSecurityPin();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('PIN keamanan dinonaktifkan.'),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    if (settings.securityEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Keamanan aplikasi aktif.')));
    }
  }

  Future<void> _showPinSetupSheet() async {
    _pinController.clear();
    _confirmPinController.clear();
    final formKey = GlobalKey<FormState>();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
            top: AppSpacing.sm,
          ),
          child: SafeArea(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardTitle(
                    icon: Icons.pin_outlined,
                    title: 'Atur PIN Keamanan',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      counterText: '',
                      labelText: 'PIN baru',
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                    validator: (value) {
                      final pin = value?.trim() ?? '';
                      if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
                        return 'PIN harus 4-6 digit angka';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _confirmPinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      counterText: '',
                      labelText: 'Ulangi PIN',
                      prefixIcon: Icon(Icons.lock_person_outlined),
                    ),
                    validator: (value) => value != _pinController.text
                        ? 'Konfirmasi PIN belum sama'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            Navigator.of(context).pop(true);
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (ok != true || !mounted) return;
    await context.read<AppSettingsProvider>().setSecurityPin(
      _pinController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN keamanan berhasil disimpan.')),
    );
  }

  Future<void> _showSupportSheet() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SupportPage()));
  }

  Future<void> _showAboutSheet() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AboutMenuPage()));
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Keluar dari akun?'),
          content: const Text(
            'Sesi pasien di perangkat ini akan ditutup. Anda bisa masuk kembali kapan saja.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
            ),
          ],
        );
      },
    );
    if (ok == true) await _signOut();
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

class _PinnedProfileHeader extends SliverPersistentHeaderDelegate {
  const _PinnedProfileHeader({required this.child});

  final Widget child;

  static const double _extent = 170;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.backgroundOf(context)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          64,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedProfileHeader oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _CleanProfileHeader extends StatelessWidget {
  const _CleanProfileHeader({
    required this.title,
    required this.statusLabel,
    required this.statusDetail,
  });

  final String title;
  final String statusLabel;
  final String statusDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimaryOf(context),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              statusDetail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textMutedOf(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        const Divider(height: 24, thickness: 0.8),
      ],
    );
  }
}

// Komponen Header tunggal yang menampilkan persentase secara real-time
class _Header extends StatelessWidget {
  const _Header({
    required this.isEditing,
    required this.profile,
    required this.email,
    required this.googleAvatarUrl,
    required this.isAvatarSaving,
    required this.onChangeAvatar,
    required this.currentProgress,
  });

  final bool isEditing;
  final PatientProfile? profile;
  final String? email;
  final String? googleAvatarUrl;
  final bool isAvatarSaving;
  final VoidCallback onChangeAvatar;
  final double currentProgress; // Nilai progres realtime yang dikirim dari form

  @override
  Widget build(BuildContext context) {
    final name = profile?.fullName.trim();
    final displayName = name == null || name.isEmpty
        ? 'Pasien AntriMedis'
        : name;
    final avatarUrl = profile?.avatarUrl ?? googleAvatarUrl;

    final statusLabel = currentProgress == 1.0
        ? 'Profil lengkap'
        : 'Perlu dilengkapi';

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.isDark(context)
                    ? const [Color(0xFF0F766E), Color(0xFF134E4A)]
                    : const [Color(0xFF075E5D), AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _ProfileAvatar(
                  name: displayName,
                  avatarUrl: avatarUrl,
                  isSaving: isAvatarSaving,
                  onTap: onChangeAvatar,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        email ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isEditing ? 'Akun pasien' : 'Verifikasi pasien',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        statusLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${(currentProgress * 100).round()}%',
                      style: TextStyle(
                        color: AppColors.isDark(context)
                            ? AppColors.primary
                            : AppColors.primaryDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: currentProgress,
                    color: currentProgress == 1.0
                        ? AppColors.success
                        : AppColors.primary,
                    backgroundColor: AppColors.borderOf(context),
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

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryDark, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _AccountActionPanel extends StatelessWidget {
  const _AccountActionPanel({
    required this.onChangePassword,
    required this.onSecurity,
    required this.onSupport,
    required this.onAbout,
    required this.onSignOut,
    required this.isLoading,
  });

  final VoidCallback onChangePassword;
  final VoidCallback onSecurity;
  final VoidCallback onSupport;
  final VoidCallback onAbout;
  final VoidCallback onSignOut;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            icon: Icons.settings_outlined,
            title: 'Pengaturan Aplikasi',
          ),
          const SizedBox(height: AppSpacing.lg),
          _AccountActionTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Keamanan dan Privasi',
            subtitle: 'Atur PIN keamanan sebelum masuk beranda.',
            onTap: onSecurity,
          ),
          const Divider(height: 1),
          _AccountActionTile(
            icon: Icons.lock_reset_outlined,
            title: 'Ubah Password',
            subtitle: 'Perbarui password login akun pasien.',
            onTap: isLoading ? null : onChangePassword,
          ),
          const Divider(height: 1),
          Consumer<AppSettingsProvider>(
            builder: (context, settings, _) {
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondarySoftOf(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    settings.isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Tampilan Aplikasi',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  settings.isDarkMode ? 'Mode gelap' : 'Mode terang',
                ),
                value: settings.isDarkMode,
                onChanged: (value) => settings.setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                ),
              );
            },
          ),
          const Divider(height: 1),
          _AccountActionTile(
            icon: Icons.support_agent_outlined,
            title: 'Bantuan dan Dukungan',
            subtitle: 'FAQ, WhatsApp klinik, dan laporan bug.',
            onTap: onSupport,
          ),
          const Divider(height: 1),
          _AccountActionTile(
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            subtitle: 'Tentang aplikasi dan kebijakan privasi.',
            onTap: onAbout,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: IconButton(
              tooltip: 'Keluar',
              onPressed: isLoading ? null : onSignOut,
              icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              'Versi 1.0.0+1',
              style: TextStyle(
                color: AppColors.textMutedOf(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  const _AccountActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger
        ? AppColors.danger
        : AppColors.isDark(context)
        ? AppColors.primary
        : AppColors.primaryDark;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDanger
              ? AppColors.dangerSoft
              : AppColors.primarySoftOf(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? AppColors.danger : AppColors.textPrimaryOf(context),
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right, color: color),
      onTap: onTap,
    );
  }
}

enum _AvatarAction { gallery, camera, remove }

class _AvatarActionTile extends StatelessWidget {
  const _AvatarActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : AppColors.primaryDark;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDanger ? AppColors.dangerSoft : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.name,
    required this.avatarUrl,
    required this.isSaving,
    required this.onTap,
  });

  final String name;
  final String? avatarUrl;
  final bool isSaving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: isSaving ? null : onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 92,
            height: 92,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: hasAvatar
                  ? Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _InitialsAvatar(name: name),
                    )
                  : _InitialsAvatar(name: name),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.primarySoft, width: 2),
              ),
              child: isSaving
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.photo_camera_outlined,
                      color: AppColors.primaryDark,
                      size: 17,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primarySoft,
      child: Center(
        child: Text(
          _initials(name),
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'AM';
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}
