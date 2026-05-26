import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_spacing.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/providers/auth_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QueueProvider>().loadHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<QueueProvider>();
    final user = context.watch<AuthProvider>().user;
    final activeTicket = queue.activeTicket;
    final polyclinicOptions = _polyclinicOptions(queue.schedules);
    final selectedPolyclinic = polyclinicOptions.contains(_selectedPolyclinic)
        ? _selectedPolyclinic
        : _allPolyclinics;
    final visibleSchedules = _visibleSchedules(
      queue.schedules,
      selectedPolyclinic,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Klinik Sehat Sentosa'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final queueProvider = context.read<QueueProvider>();
              final authProvider = context.read<AuthProvider>();
              await queueProvider.clearForSignOut();
              await authProvider.signOut();
            },
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
            AppSpacing.xxl,
          ),
          children: [
            ClinicHero(email: user?.email),
            const SizedBox(height: AppSpacing.lg),
            TodaySummary(
              scheduleCount: queue.schedules.length,
              activeTicketCode: activeTicket?.queueCode,
              isLoading: queue.isLoading,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (queue.error != null) ...[
              AppErrorBanner(message: queue.error!),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (activeTicket != null) ...[
              ActiveTicketCard(onTap: () => _openTracking(context)),
              const SizedBox(height: AppSpacing.xl),
            ],
            SectionHeader(
              title: 'Jadwal praktik hari ini',
              subtitle: 'Cabang Utama · pilih poli dan dokter tujuan',
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
              const EmptyState(
                icon: Icons.event_busy_outlined,
                title: 'Jadwal belum tersedia',
                message:
                    'Tarik layar ke bawah untuk memuat ulang jadwal klinik.',
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
                      isDisabled: activeTicket != null || queue.isLoading,
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
    final ok = await context.read<QueueProvider>().createTicket(schedule);
    if (!context.mounted || !ok) return;
    _openTracking(context);
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
}
