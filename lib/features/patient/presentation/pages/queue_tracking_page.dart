import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_spacing.dart';
import '../../../../core/utils/queue_status.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
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
          ? const Center(child: Text('Tidak ada antrean aktif.'))
          : RefreshIndicator(
              onRefresh: queue.refreshActiveTicket,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                children: [
                  _TrackingHero(
                    queueCode: ticket.queueCode,
                    progress: ticket.progress,
                    status: ticket.status,
                    title: '${ticket.polyclinicName} - ${ticket.doctorName}',
                  ),
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
                          icon: Icons.campaign_outlined,
                          title: 'Nomor dipanggil',
                          isActive: [
                            'called',
                            'serving',
                            'completed',
                          ].contains(ticket.status),
                        ),
                        _TimelineStep(
                          icon: Icons.medical_services_outlined,
                          title: 'Sedang dilayani',
                          isActive: [
                            'serving',
                            'completed',
                          ].contains(ticket.status),
                        ),
                        _TimelineStep(
                          icon: Icons.check_circle_outline,
                          title: 'Selesai',
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
                        _DetailRow('Poli', ticket.polyclinicName),
                        _DetailRow('Dokter', ticket.doctorName),
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
      Navigator.of(context).pop();
    }
  }
}

class _TrackingHero extends StatelessWidget {
  const _TrackingHero({
    required this.queueCode,
    required this.progress,
    required this.status,
    required this.title,
  });

  final String queueCode;
  final double progress;
  final String status;
  final String title;

  @override
  Widget build(BuildContext context) {
    final style = queueStatusStyle(status);

    return AppCard(
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
            radius: 90,
            lineWidth: 13,
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
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
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
        ],
      ),
    );
  }

  String _statusMessage(String status) {
    return switch (status) {
      'waiting' => 'Silakan bersiap, giliran Anda sedang berjalan.',
      'called' => 'Nomor Anda sedang dipanggil.',
      'serving' => 'Anda sedang dilayani.',
      'completed' => 'Kunjungan selesai.',
      'skipped' => 'Nomor Anda dilewati.',
      'cancelled' => 'Antrean dibatalkan.',
      _ => status,
    };
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
          label: 'Estimasi',
          value: '$waitMinutes mnt',
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
    this.isLast = false,
  });

  final IconData icon;
  final String title;
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
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
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
