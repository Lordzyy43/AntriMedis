import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_spacing.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/providers/auth_provider.dart';
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
import '../widgets/today_summary.dart';

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
    final user = context.watch<AuthProvider>().user;
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

    return Scaffold(
      appBar: AppBar(title: const Text('Klinik Sehat Sentosa')),
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
              email: user?.email,
              clinicName: 'Klinik Sehat Sentosa',
              branchName: clinic?.name ?? 'Cabang Utama',
              operationalHours: clinic?.operationalHours ?? '08.00-20.00',
              address:
                  clinic?.fullAddress ??
                  'Ambil nomor antrean poli dan pantau estimasi waktu tunggu secara real-time.',
            ),
            const SizedBox(height: AppSpacing.lg),
            TodaySummary(
              scheduleCount: queue.schedules.length,
              activeTicketCode: activeTicket?.queueCode,
              isLoading: queue.isLoading,
            ),
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
            SectionHeader(
              title: 'Jadwal praktik hari ini',
              subtitle:
                  '${clinic?.name ?? 'Cabang Utama'} - pilih poli dan dokter tujuan',
              trailing: IconButton(
                tooltip: 'Muat ulang',
                onPressed: queue.isLoading ? null : queue.loadHome,
                icon: const Icon(Icons.refresh),
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
                    'Admin klinik belum membuka jadwal antrean. Coba muat ulang setelah jadwal dibuat dari admin panel.',
                actionLabel: 'Muat ulang',
                onAction: queue.loadHome,
              )
            else ...[
              PolyclinicFilter(
                options: polyclinicOptions,
                selected: selectedPolyclinic,
                onSelected: (value) {
                  setState(() => _selectedPolyclinic = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              if (visibleSchedules.isEmpty)
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
    final estimatedMinutes =
        schedule.totalTaken * schedule.averageServiceMinutes;

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
                'Perkiraan tunggu sekitar $estimatedMinutes menit dan dapat berubah sesuai kondisi klinik.',
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
    if (selectedPolyclinic == _allPolyclinics) return schedules;
    return schedules
        .where((schedule) => schedule.polyclinicName == selectedPolyclinic)
        .toList();
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
    if (!schedule.canTakeQueue) return schedule.availabilityReason;
    return 'Ambil Nomor';
  }
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
