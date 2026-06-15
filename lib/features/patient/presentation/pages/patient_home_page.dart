import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_spacing.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../clinic/providers/clinic_provider.dart';
import '../../../profile/presentation/profile_completion_page.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../queue/data/models/polyclinic_option.dart';
import '../../../queue/data/models/schedule_availability.dart';
import '../../../queue/providers/queue_provider.dart';
import 'queue_tracking_page.dart';
import '../widgets/active_ticket_card.dart';
import '../widgets/clinic_hero.dart';
import '../widgets/polyclinic_filter.dart';
import '../widgets/schedule_card.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  static const _allPolyclinics = 'Semua';

  String _selectedPolyclinic = _allPolyclinics;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<QueueProvider>();
    final clinic = context.watch<ClinicProvider>().branch;
    final profile = context.watch<ProfileProvider>();
    final activeTicket = queue.activeTicket;
    final hasActiveTicket = activeTicket != null;
    final needsProfileCompletion = profile.needsCompletion;
    final polyclinicOptions = _polyclinicOptions(queue.polyclinics);
    final selectedPolyclinic = polyclinicOptions.contains(_selectedPolyclinic)
        ? _selectedPolyclinic
        : _allPolyclinics;
    final visibleSchedules = _visibleSchedules(
      queue.schedules,
      selectedPolyclinic,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: RefreshIndicator(
        onRefresh: queue.loadHome,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyClinicHeroHeader(
                child: ClinicHero(
                  patientName: profile.profile?.fullName,
                  clinicName: 'Klinik Sehat Sentosa',
                  branchName: clinic?.name ?? 'Cabang Utama',
                  operationalHours: '24 Jam',
                  address:
                      clinic?.fullAddress ??
                      'Ambil nomor antrean poli dan pantau giliran Anda dari ponsel.',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                104,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (queue.error != null) ...[
                    AppErrorBanner(
                      message: queue.error!,
                      actionLabel: 'Muat ulang',
                      onAction: queue.loadHome,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (needsProfileCompletion) ...[
                    _ProfileGuardNotice(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const ProfileCompletionPage(closeAfterSave: true),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (activeTicket != null) ...[
                    ActiveTicketCard(onTap: () => _openTracking(context)),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  const _SectionHeader(
                    title: 'Pilih Poliklinik',
                    subtitle: 'Filter layanan sesuai tujuan kunjungan Anda',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (queue.polyclinics.isNotEmpty)
                    PolyclinicFilter(
                      options: polyclinicOptions,
                      selected: selectedPolyclinic,
                      onSelected: (value) {
                        setState(() => _selectedPolyclinic = value);
                      },
                    ),
                  if (queue.polyclinics.isNotEmpty)
                    const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(
                    title: 'Poli Aktif Hari Ini',
                    subtitle: _scheduleSectionSubtitle(
                      context: context,
                      visibleCount: visibleSchedules.length,
                      isRealtime: queue.isScheduleRealtimeActive,
                      lastSyncedAt: queue.lastScheduleSyncedAt,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (queue.isLoading && queue.polyclinics.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (queue.polyclinics.isEmpty)
                    EmptyState(
                      icon: Icons.event_busy_outlined,
                      title: 'Jadwal belum tersedia',
                      message:
                          'Jadwal antrean hari ini belum dibuka. Coba muat ulang beberapa saat lagi.',
                      actionLabel: 'Muat ulang',
                      onAction: queue.loadHome,
                    )
                  else if (visibleSchedules.isEmpty)
                    const EmptyState(
                      icon: Icons.manage_search_outlined,
                      title: 'Poli tidak ditemukan',
                      message:
                          'Coba pilih filter poli lain atau muat ulang data.',
                    )
                  else ...[
                    _PolyclinicStatusList(
                      polyclinics: _visiblePolyclinics(
                        queue.polyclinics,
                        selectedPolyclinic,
                      ),
                      schedules: queue.schedules,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ...visibleSchedules.map((schedule) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: ScheduleCard(
                          schedule: schedule,
                          isDisabled:
                              hasActiveTicket ||
                              queue.isLoading ||
                              needsProfileCompletion ||
                              !schedule.canTakeQueue,
                          disabledLabel: _scheduleButtonLabel(
                            schedule: schedule,
                            hasActiveTicket: hasActiveTicket,
                            isLoading: queue.isLoading,
                            needsProfileCompletion: needsProfileCompletion,
                          ),
                          onTakeQueue: () => _takeQueue(context, schedule),
                        ),
                      );
                    }),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takeQueue(
    BuildContext context,
    ScheduleAvailability schedule,
  ) async {
    final profile = context.read<ProfileProvider>();
    final queue = context.read<QueueProvider>();
    if (profile.needsCompletion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi profil pasien sebelum mengambil antrean.'),
        ),
      );
      return;
    }
    if (queue.activeTicket != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selesaikan atau batalkan antrean aktif terlebih dulu.',
          ),
        ),
      );
      return;
    }
    if (!schedule.canTakeQueue) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(schedule.availabilityReason)));
      return;
    }

    final confirmed = await _confirmTakeQueue(context, schedule);
    if (confirmed != true || !context.mounted) return;

    final ok = await context.read<QueueProvider>().createTicket(schedule);
    if (!context.mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nomor antrean berhasil dibuat.')),
    );
    _openTracking(context);
  }

  Future<bool?> _confirmTakeQueue(
    BuildContext context,
    ScheduleAvailability schedule,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ambil nomor antrean?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${schedule.polyclinicName} - ${schedule.doctorName}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.md),
              _ConfirmQueueFact(
                icon: Icons.groups_2_outlined,
                label: 'Sisa kuota',
                value: '${schedule.remainingQuota}/${schedule.quotaLimit}',
              ),
              const SizedBox(height: AppSpacing.sm),
              _ConfirmQueueFact(
                icon: Icons.campaign_outlined,
                label: 'Nomor saat ini',
                value: schedule.currentQueueLabel,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Nanti dulu'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.confirmation_number_outlined),
              label: const Text('Ambil Nomor'),
            ),
          ],
        );
      },
    );
  }

  void _openTracking(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const QueueTrackingPage()));
  }

  List<String> _polyclinicOptions(List<PolyclinicOption> polyclinics) {
    return [
      _allPolyclinics,
      ...polyclinics.map((polyclinic) => polyclinic.name),
    ];
  }

  List<PolyclinicOption> _visiblePolyclinics(
    List<PolyclinicOption> polyclinics,
    String selectedPolyclinic,
  ) {
    if (selectedPolyclinic == _allPolyclinics) return polyclinics;
    return polyclinics
        .where((polyclinic) => polyclinic.name == selectedPolyclinic)
        .toList();
  }

  List<ScheduleAvailability> _visibleSchedules(
    List<ScheduleAvailability> schedules,
    String selectedPolyclinic,
  ) {
    final filtered = selectedPolyclinic == _allPolyclinics
        ? [...schedules]
        : schedules
              .where(
                (schedule) => schedule.polyclinicName == selectedPolyclinic,
              )
              .toList();

    filtered.sort((first, second) {
      final firstRank = _scheduleRank(first);
      final secondRank = _scheduleRank(second);
      if (firstRank != secondRank) return firstRank - secondRank;
      return first.startTime.compareTo(second.startTime);
    });

    return filtered;
  }

  int _scheduleRank(ScheduleAvailability schedule) {
    if (schedule.canTakeQueue && schedule.isOperatingNow) return 0;
    if (schedule.canTakeQueue && schedule.isBeforeStart) return 1;
    if (!schedule.canTakeQueue && !schedule.hasEnded) return 2;
    return 3;
  }

  String _scheduleButtonLabel({
    required ScheduleAvailability schedule,
    required bool hasActiveTicket,
    required bool isLoading,
    required bool needsProfileCompletion,
  }) {
    if (isLoading) return 'Memuat';
    if (hasActiveTicket) return 'Sudah Aktif';
    if (needsProfileCompletion) return 'Lengkapi';
    if (!schedule.canTakeQueue) return 'Tidak Tersedia';
    return 'Ambil Nomor';
  }

  String _scheduleSectionSubtitle({
    required BuildContext context,
    required int visibleCount,
    required bool isRealtime,
    required DateTime? lastSyncedAt,
  }) {
    if (visibleCount == 0) return 'Tidak ada poli pada filter ini';

    final realtimeLabel = isRealtime ? 'Diperbarui otomatis' : 'Perlu refresh';
    final syncLabel = lastSyncedAt == null
        ? null
        : DateFormat('HH:mm').format(lastSyncedAt.toLocal());

    if (syncLabel == null) {
      return '$visibleCount sesi poli ditampilkan - $realtimeLabel';
    }
    return '$visibleCount sesi poli ditampilkan - $realtimeLabel, terakhir $syncLabel';
  }
}

class _StickyClinicHeroHeader extends SliverPersistentHeaderDelegate {
  const _StickyClinicHeroHeader({required this.child});

  final Widget child;

  static const double _extent = 262;

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
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyClinicHeroHeader oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _PolyclinicStatusList extends StatelessWidget {
  const _PolyclinicStatusList({
    required this.polyclinics,
    required this.schedules,
  });

  final List<PolyclinicOption> polyclinics;
  final List<ScheduleAvailability> schedules;

  @override
  Widget build(BuildContext context) {
    final statuses = _statuses();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          for (var index = 0; index < statuses.length; index++) ...[
            _PolyclinicStatusRow(status: statuses[index]),
            if (index < statuses.length - 1)
              const Divider(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }

  List<_PolyclinicStatus> _statuses() {
    final byName = <String, List<ScheduleAvailability>>{};
    for (final schedule in schedules) {
      byName.putIfAbsent(schedule.polyclinicName, () => []).add(schedule);
    }

    return polyclinics.map((polyclinic) {
      final sessions = byName[polyclinic.name] ?? [];
      final active =
          polyclinic.isActive &&
          sessions.any((schedule) => schedule.canTakeQueue);
      return _PolyclinicStatus(
        name: polyclinic.name,
        active: active,
        sessionCount: sessions.length,
      );
    }).toList()..sort((first, second) {
      if (first.active != second.active) return first.active ? -1 : 1;
      return first.name.compareTo(second.name);
    });
  }
}

class _PolyclinicStatusRow extends StatelessWidget {
  const _PolyclinicStatusRow({required this.status});

  final _PolyclinicStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.active ? AppColors.success : AppColors.textMuted;
    final background = status.active
        ? AppColors.successSoftOf(context)
        : AppColors.surfaceMutedOf(context);

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            status.active ? Icons.task_alt_outlined : Icons.block_outlined,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimaryOf(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${status.sessionCount} sesi hari ini',
                style: TextStyle(
                  color: AppColors.textMutedOf(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          status.active ? 'Aktif' : 'Tidak Aktif',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PolyclinicStatus {
  const _PolyclinicStatus({
    required this.name,
    required this.active,
    required this.sessionCount,
  });

  final String name;
  final bool active;
  final int sessionCount;
}

class _ConfirmQueueFact extends StatelessWidget {
  const _ConfirmQueueFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryDark, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimaryOf(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textMutedOf(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileGuardNotice extends StatelessWidget {
  const _ProfileGuardNotice({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.warningSoftOf(context),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Lengkapi data pasien agar klinik bisa memverifikasi antrean Anda.',
              style: TextStyle(
                color: AppColors.textPrimaryOf(context),
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(onPressed: onTap, child: const Text('Lengkapi')),
        ],
      ),
    );
  }
}
