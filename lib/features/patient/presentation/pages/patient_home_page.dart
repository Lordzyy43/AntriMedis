import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_spacing.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../clinic/providers/clinic_provider.dart';
import '../../../profile/presentation/profile_completion_page.dart';
import '../../../profile/providers/profile_provider.dart';
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
    final polyclinicOptions = _polyclinicOptions(queue.schedules);
    final selectedPolyclinic = polyclinicOptions.contains(_selectedPolyclinic)
        ? _selectedPolyclinic
        : _allPolyclinics;
    final visibleSchedules = _visibleSchedules(
      queue.schedules,
      selectedPolyclinic,
    );
    final takeableCount = queue.schedules
        .where((schedule) => schedule.canTakeQueue)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Beranda'),
            Text(
              'Antrean pasien',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: queue.isLoading ? null : queue.loadHome,
            icon: queue.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: queue.loadHome,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            104,
          ),
          children: [
            ClinicHero(
              patientName: profile.profile?.fullName,
              clinicName: 'Klinik Sehat Sentosa',
              branchName: clinic?.name ?? 'Cabang Utama',
              operationalHours: clinic?.operationalHours ?? '08.00-20.00',
              address:
                  clinic?.fullAddress ??
                  'Ambil nomor antrean poli dan pantau giliran Anda dari ponsel.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _HomeQuickStats(
              scheduleCount: queue.schedules.length,
              takeableCount: takeableCount,
              activeTicketCode: activeTicket?.queueCode,
            ),
            const SizedBox(height: AppSpacing.lg),
            _QueueReadinessBanner(
              isLoading: queue.isLoading,
              hasActiveTicket: hasActiveTicket,
              needsProfileCompletion: needsProfileCompletion,
              takeableCount: takeableCount,
              scheduleCount: queue.schedules.length,
            ),
            const SizedBox(height: AppSpacing.lg),
            _TodayOperationsOverview(schedules: queue.schedules),
            const SizedBox(height: AppSpacing.lg),
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
            _SectionHeader(
              title: 'Pilih Poliklinik',
              subtitle: 'Filter layanan sesuai tujuan kunjungan Anda',
              actionLabel: selectedPolyclinic == _allPolyclinics
                  ? null
                  : 'Reset',
              onAction: queue.isLoading
                  ? null
                  : () {
                      setState(() => _selectedPolyclinic = _allPolyclinics);
                    },
            ),
            const SizedBox(height: AppSpacing.sm),
            if (queue.schedules.isNotEmpty)
              PolyclinicFilter(
                options: polyclinicOptions,
                selected: selectedPolyclinic,
                onSelected: (value) {
                  setState(() => _selectedPolyclinic = value);
                },
              ),
            if (queue.schedules.isNotEmpty)
              const SizedBox(height: AppSpacing.lg),
            _SectionHeader(
              title: 'Jadwal Dokter Hari Ini',
              subtitle: _scheduleSectionSubtitle(
                context: context,
                visibleCount: visibleSchedules.length,
                isRealtime: queue.isScheduleRealtimeActive,
                lastSyncedAt: queue.lastScheduleSyncedAt,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (queue.isLoading && queue.schedules.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (queue.schedules.isEmpty)
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
                title: 'Jadwal poli tidak ditemukan',
                message: 'Coba pilih filter poli lain atau muat ulang data.',
              )
            else
              ...visibleSchedules.map((schedule) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Jam praktik ${schedule.startTime}-${schedule.endTime}. '
                'Nomor antrean berlaku untuk sesi hari ini dan dipanggil sesuai urutan nomor.',
              ),
              const SizedBox(height: AppSpacing.md),
              _ConfirmQueueFact(
                icon: Icons.groups_2_outlined,
                label: 'Sisa kuota',
                value: '${schedule.remainingQuota}/${schedule.quotaLimit}',
              ),
              const SizedBox(height: AppSpacing.sm),
              _ConfirmQueueFact(
                icon: Icons.timelapse_outlined,
                label: 'Estimasi awal',
                value: schedule.estimatedFirstWaitLabel,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ConfirmQueueFact(
                icon: Icons.info_outline,
                label: 'Catatan',
                value: schedule.patientGuidance,
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

  List<String> _polyclinicOptions(List<ScheduleAvailability> schedules) {
    return [
      _allPolyclinics,
      ...{for (final schedule in schedules) schedule.polyclinicName},
    ];
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
    if (visibleCount == 0) return 'Tidak ada jadwal pada filter ini';

    final realtimeLabel = isRealtime ? 'Diperbarui otomatis' : 'Perlu refresh';
    final syncLabel = lastSyncedAt == null
        ? null
        : TimeOfDay.fromDateTime(lastSyncedAt.toLocal()).format(context);

    if (syncLabel == null) {
      return '$visibleCount jadwal ditampilkan - $realtimeLabel';
    }
    return '$visibleCount jadwal ditampilkan - $realtimeLabel, terakhir $syncLabel';
  }
}

class _TodayOperationsOverview extends StatelessWidget {
  const _TodayOperationsOverview({required this.schedules});

  final List<ScheduleAvailability> schedules;

  @override
  Widget build(BuildContext context) {
    final operating = schedules
        .where((schedule) => schedule.isOperatingNow)
        .length;
    final beforeStart = schedules
        .where((schedule) => schedule.isBeforeStart)
        .length;
    final takeable = schedules
        .where((schedule) => schedule.canTakeQueue)
        .length;
    final remaining = schedules.fold<int>(
      0,
      (total, schedule) => total + schedule.remainingQuota,
    );
    final taken = schedules.fold<int>(
      0,
      (total, schedule) => total + schedule.totalTaken,
    );

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.insights_outlined,
                color: AppColors.primaryDark,
                size: 20,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Ringkasan layanan hari ini',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  label: 'Sedang buka',
                  value: operating.toString(),
                  color: AppColors.success,
                  backgroundColor: AppColors.successSoft,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _OverviewMetric(
                  label: 'Belum mulai',
                  value: beforeStart.toString(),
                  color: AppColors.warning,
                  backgroundColor: AppColors.warningSoft,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _OverviewMetric(
                  label: 'Bisa ambil',
                  value: takeable.toString(),
                  color: AppColors.secondary,
                  backgroundColor: AppColors.secondarySoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            schedules.isEmpty
                ? 'Jadwal akan muncul setelah admin membuka sesi layanan.'
                : '$taken nomor sudah masuk. Total sisa kuota tersedia: $remaining.',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final String value;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
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

class _HomeQuickStats extends StatelessWidget {
  const _HomeQuickStats({
    required this.scheduleCount,
    required this.takeableCount,
    required this.activeTicketCode,
  });

  final int scheduleCount;
  final int takeableCount;
  final String? activeTicketCode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickStatTile(
            icon: Icons.event_available_outlined,
            label: 'Jadwal',
            value: scheduleCount.toString(),
            color: AppColors.secondary,
            backgroundColor: AppColors.secondarySoft,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickStatTile(
            icon: Icons.task_alt_outlined,
            label: 'Bisa diambil',
            value: takeableCount.toString(),
            color: AppColors.success,
            backgroundColor: AppColors.successSoft,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickStatTile(
            icon: Icons.confirmation_number_outlined,
            label: 'Tiket aktif',
            value: activeTicketCode ?? '-',
            color: AppColors.primaryDark,
            backgroundColor: AppColors.primarySoft,
          ),
        ),
      ],
    );
  }
}

class _QuickStatTile extends StatelessWidget {
  const _QuickStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

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
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: AppSpacing.sm),
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );
  }
}

class _QueueReadinessBanner extends StatelessWidget {
  const _QueueReadinessBanner({
    required this.isLoading,
    required this.hasActiveTicket,
    required this.needsProfileCompletion,
    required this.takeableCount,
    required this.scheduleCount,
  });

  final bool isLoading;
  final bool hasActiveTicket;
  final bool needsProfileCompletion;
  final int takeableCount;
  final int scheduleCount;

  @override
  Widget build(BuildContext context) {
    final state = _state();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: state.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: state.color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(state.icon, color: state.color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.message,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _ReadinessState _state() {
    if (isLoading) {
      return const _ReadinessState(
        icon: Icons.sync_outlined,
        color: AppColors.secondary,
        backgroundColor: AppColors.secondarySoft,
        title: 'Sinkronisasi antrean',
        message: 'Data jadwal dan tiket sedang dimuat dari klinik.',
      );
    }
    if (needsProfileCompletion) {
      return const _ReadinessState(
        icon: Icons.verified_user_outlined,
        color: AppColors.warning,
        backgroundColor: AppColors.warningSoft,
        title: 'Profil perlu dilengkapi',
        message: 'Lengkapi data pasien sebelum mengambil nomor antrean.',
      );
    }
    if (hasActiveTicket) {
      return const _ReadinessState(
        icon: Icons.confirmation_number_outlined,
        color: AppColors.primaryDark,
        backgroundColor: AppColors.primarySoft,
        title: 'Anda punya antrean aktif',
        message: 'Pantau nomor Anda dan tetap siap saat giliran mendekat.',
      );
    }
    if (takeableCount > 0) {
      return _ReadinessState(
        icon: Icons.task_alt_outlined,
        color: AppColors.success,
        backgroundColor: AppColors.successSoft,
        title: '$takeableCount jadwal siap diambil',
        message: 'Pilih poli dan dokter tujuan, lalu ambil nomor antrean.',
      );
    }
    if (scheduleCount > 0) {
      return const _ReadinessState(
        icon: Icons.lock_clock_outlined,
        color: AppColors.warning,
        backgroundColor: AppColors.warningSoft,
        title: 'Belum ada jadwal yang bisa diambil',
        message:
            'Jadwal hari ini ada, tetapi sesi belum dibuka klinik, kuota penuh, atau jam layanan sudah selesai.',
      );
    }
    return const _ReadinessState(
      icon: Icons.event_busy_outlined,
      color: AppColors.textMuted,
      backgroundColor: AppColors.surfaceMuted,
      title: 'Jadwal belum tersedia',
      message: 'Muat ulang setelah klinik membuka jadwal antrean hari ini.',
    );
  }
}

class _ReadinessState {
  const _ReadinessState({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String title;
  final String message;
}

class _ProfileGuardNotice extends StatelessWidget {
  const _ProfileGuardNotice({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.warningSoft,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Text(
              'Lengkapi data pasien agar klinik bisa memverifikasi antrean Anda.',
              style: TextStyle(
                color: AppColors.textPrimary,
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
