import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_spacing.dart';
import '../../../../core/utils/queue_status.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../queue/providers/queue_provider.dart';

class QueueTrackingPage extends StatelessWidget {
  const QueueTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<QueueProvider>();
    final ticket = queue.activeTicket;

    return Scaffold(
      appBar: AppBar(title: const Text('Antrean Saya')),
      body: ticket == null
          ? const _NoActiveQueueState()
          : RefreshIndicator(
              onRefresh: queue.refreshActiveTicket,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  112,
                ),
                children: [
                  if (queue.error != null) ...[
                    AppErrorBanner(
                      message: queue.error!,
                      actionLabel: 'Muat ulang',
                      onAction: queue.refreshActiveTicket,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _TrackingHero(
                    queueCode: ticket.queueCode,
                    progress: ticket.progress,
                    status: ticket.status,
                    title: '${ticket.polyclinicName} - ${ticket.doctorName}',
                    currentNumber: ticket.currentNumber,
                    remaining: ticket.remainingBeforeMe,
                    waitMinutes: ticket.estimatedWaitMinutes,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _LiveEstimateNotice(),
                  const SizedBox(height: AppSpacing.md),
                  _MetricGrid(
                    currentNumber: ticket.currentNumber,
                    remaining: ticket.remainingBeforeMe,
                    waitMinutes: ticket.estimatedWaitMinutes,
                    lastNumber: ticket.lastNumber,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status antrean',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const _TimelineStep(
                          icon: Icons.confirmation_number_outlined,
                          title: 'Nomor dibuat',
                          isActive: true,
                        ),
                        _TimelineStep(
                          icon: Icons.access_time_outlined,
                          title: 'Masuk antrean',
                          subtitle: _formatDateTime(ticket.createdAt),
                          isActive: true,
                        ),
                        _TimelineStep(
                          icon: Icons.campaign_outlined,
                          title: 'Nomor dipanggil',
                          subtitle: _formatNullableTime(ticket.calledAt),
                          isActive: [
                            'called',
                            'serving',
                            'completed',
                          ].contains(ticket.status),
                        ),
                        _TimelineStep(
                          icon: Icons.medical_services_outlined,
                          title: 'Sedang dilayani',
                          subtitle: _formatNullableTime(
                            ticket.servingStartedAt,
                          ),
                          isActive: [
                            'serving',
                            'completed',
                          ].contains(ticket.status),
                        ),
                        _TimelineStep(
                          icon: Icons.check_circle_outline,
                          title: 'Selesai',
                          subtitle: _formatNullableTime(ticket.completedAt),
                          isActive: ticket.status == 'completed',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail klinik & jadwal',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const _DetailRow('Klinik', 'Klinik Sehat Sentosa'),
                        _DetailRow('Cabang', ticket.branchName),
                        if (ticket.branchAddress != null &&
                            ticket.branchAddress!.trim().isNotEmpty)
                          _DetailRow('Alamat', ticket.branchAddress!),
                        _DetailRow('Poli', ticket.polyclinicName),
                        _DetailRow('Dokter', ticket.doctorName),
                        _DetailRow(
                          'Tanggal',
                          DateFormat(
                            'dd MMMM yyyy',
                          ).format(ticket.scheduleDate),
                        ),
                        _DetailRow(
                          'Jam praktik',
                          '${ticket.startTime}-${ticket.endTime}',
                        ),
                      ],
                    ),
                  ),
                  if (ticket.canCancel) ...[
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: queue.isLoading
                            ? null
                            : () => _confirmCancel(context),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Batalkan Antrean'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('dd MMM yyyy, HH:mm').format(value.toLocal());
  }

  String? _formatNullableTime(DateTime? value) {
    if (value == null) return null;
    return DateFormat('HH:mm').format(value.toLocal());
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Batalkan antrean?'),
          content: const Text(
            'Nomor antrean yang dibatalkan tidak bisa digunakan kembali.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Tidak'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Batalkan'),
            ),
          ],
        );
      },
    );

    if (ok != true || !context.mounted) return;
    final cancelled = await context.read<QueueProvider>().cancelActiveTicket();
    if (cancelled && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Antrean berhasil dibatalkan.')),
      );
      Navigator.of(context).pop();
    } else if (context.mounted) {
      final message =
          context.read<QueueProvider>().error ?? 'Gagal membatalkan antrean.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _NoActiveQueueState extends StatelessWidget {
  const _NoActiveQueueState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tidak ada antrean aktif',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Ambil nomor dari jadwal praktik hari ini untuk mulai memantau posisi antrean.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.event_available_outlined),
                label: const Text('Lihat Jadwal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveEstimateNotice extends StatelessWidget {
  const _LiveEstimateNotice();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.primarySoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.sensors_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Text(
              'Posisi antrean diperbarui otomatis saat petugas memanggil atau menyelesaikan pasien. Estimasi bersifat perkiraan dan dapat berubah.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingHero extends StatelessWidget {
  const _TrackingHero({
    required this.queueCode,
    required this.progress,
    required this.status,
    required this.title,
    required this.currentNumber,
    required this.remaining,
    required this.waitMinutes,
  });

  final String queueCode;
  final double progress;
  final String status;
  final String title;
  final int currentNumber;
  final int remaining;
  final int waitMinutes;

  @override
  Widget build(BuildContext context) {
    final style = queueStatusStyle(status);

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE0F7F6), AppColors.surface],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -32,
              top: -36,
              child: Icon(
                Icons.radar_outlined,
                size: 150,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Row(
                    children: [
                      AppBadge(
                        label: style.label,
                        icon: style.icon,
                        color: style.color,
                        backgroundColor: style.backgroundColor,
                      ),
                      const Spacer(),
                      const AppBadge(
                        label: 'Live',
                        icon: Icons.circle,
                        color: AppColors.success,
                        backgroundColor: AppColors.successSoft,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CircularPercentIndicator(
                    radius: 92,
                    lineWidth: 14,
                    percent: progress,
                    animation: true,
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: AppColors.primary,
                    backgroundColor: AppColors.border,
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Nomor Anda',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        Text(
                          queueCode,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '$remaining antrean lagi',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _statusMessage(status),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroMiniStat(
                          label: 'Dipanggil',
                          value: currentNumber.toString(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _HeroMiniStat(
                          label: 'Perkiraan',
                          value: '± $waitMinutes mnt',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusMessage(String status) {
    return switch (status) {
      'waiting' => 'Pantau nomor berjalan dan bersiap mendekati giliran.',
      'called' => 'Nomor Anda sedang dipanggil. Segera menuju poli.',
      'serving' => 'Anda sedang dilayani oleh petugas klinik.',
      'completed' => 'Kunjungan selesai. Terima kasih.',
      'skipped' => 'Nomor Anda dilewati. Hubungi petugas klinik.',
      'cancelled' => 'Antrean dibatalkan.',
      _ => status,
    };
  }
}

class _HeroMiniStat extends StatelessWidget {
  const _HeroMiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.currentNumber,
    required this.remaining,
    required this.waitMinutes,
    required this.lastNumber,
  });

  final int currentNumber;
  final int remaining;
  final int waitMinutes;
  final int lastNumber;

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.35,
      ),
      children: [
        _MetricCard(
          icon: Icons.campaign_outlined,
          label: 'Dipanggil',
          value: currentNumber.toString(),
          color: AppColors.warning,
          backgroundColor: AppColors.warningSoft,
        ),
        _MetricCard(
          icon: Icons.confirmation_number_outlined,
          label: 'Nomor terakhir',
          value: lastNumber.toString(),
          color: AppColors.secondary,
          backgroundColor: AppColors.secondarySoft,
        ),
        _MetricCard(
          icon: Icons.people_alt_outlined,
          label: 'Sisa antrean',
          value: remaining.toString(),
          color: AppColors.primaryDark,
          backgroundColor: AppColors.primarySoft,
        ),
        _MetricCard(
          icon: Icons.timer_outlined,
          label: 'Perkiraan',
          value: '± $waitMinutes mnt',
          color: AppColors.violet,
          backgroundColor: AppColors.violetSoft,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
        mainAxisAlignment: MainAxisAlignment.center,
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
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.title,
    required this.isActive,
    this.subtitle,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primarySoft
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 22,
                color: isActive ? AppColors.primarySoft : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
