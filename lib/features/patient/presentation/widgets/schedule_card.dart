import 'package:flutter/material.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_spacing.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../queue/data/models/schedule_availability.dart';

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.isDisabled,
    required this.onTakeQueue,
    this.disabledLabel,
  });

  final ScheduleAvailability schedule;
  final bool isDisabled;
  final VoidCallback onTakeQueue;
  final String? disabledLabel;

  @override
  Widget build(BuildContext context) {
    final status = _statusVisual(schedule);
    final quotaProgress = schedule.quotaUsageRatio;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DoctorAvatar(
                prefix: schedule.queuePrefix,
                color: status.color,
                backgroundColor: status.backgroundColor,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            schedule.doctorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _StatusBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            schedule.polyclinicName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          schedule.operationalPhaseLabel,
                          style: TextStyle(
                            color: status.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _MetaItem(
                            icon: Icons.schedule_outlined,
                            label: '${schedule.startTime}-${schedule.endTime}',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _MetaItem(
                            icon: Icons.timer_outlined,
                            label:
                                '${schedule.averageServiceMinutes} mnt/pasien',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _InsightTile(
                  icon: Icons.timelapse_outlined,
                  label: 'Estimasi awal',
                  value: schedule.estimatedFirstWaitLabel,
                  color: AppColors.secondary,
                  backgroundColor: AppColors.secondarySoft,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _InsightTile(
                  icon: Icons.format_list_numbered_outlined,
                  label: 'Nomor terakhir',
                  value: schedule.lastNumber <= 0
                      ? '-'
                      : '${schedule.queuePrefix}${schedule.lastNumber.toString().padLeft(3, '0')}',
                  color: AppColors.primaryDark,
                  backgroundColor: AppColors.primarySoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sisa ${schedule.remainingQuota}/${schedule.quotaLimit}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${schedule.totalTaken} nomor sudah masuk',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '${(quotaProgress * 100).round()}%',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: quotaProgress,
                    color: schedule.remainingQuota <= 2
                        ? AppColors.warning
                        : AppColors.primary,
                    backgroundColor: AppColors.border,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _GuidancePanel(schedule: schedule, status: status),
                if (schedule.canTakeQueue &&
                    schedule.availabilityReason != 'Siap diambil') ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          schedule.availabilityReason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (!schedule.canTakeQueue) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(status.icon, size: 16, color: status.color),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          schedule.availabilityReason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: status.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: schedule.canTakeQueue
                ? FilledButton.icon(
                    onPressed: isDisabled ? null : onTakeQueue,
                    icon: const Icon(Icons.confirmation_number_outlined),
                    label: Text(disabledLabel ?? 'Ambil Antrean'),
                  )
                : OutlinedButton.icon(
                    onPressed: isDisabled ? null : onTakeQueue,
                    icon: Icon(status.icon),
                    label: Text(
                      disabledLabel ?? status.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  _ScheduleStatusVisual _statusVisual(ScheduleAvailability schedule) {
    if (schedule.canTakeQueue) {
      return const _ScheduleStatusVisual(
        label: 'Siap Diambil',
        icon: Icons.task_alt_outlined,
        color: AppColors.success,
        backgroundColor: AppColors.successSoft,
      );
    }

    final reason = schedule.availabilityReason.toLowerCase();
    if (reason.contains('kuota')) {
      return const _ScheduleStatusVisual(
        label: 'Penuh',
        icon: Icons.groups_2_outlined,
        color: AppColors.textMuted,
        backgroundColor: AppColors.surfaceMuted,
      );
    }
    if (reason.contains('selesai') || reason.contains('lewat')) {
      return const _ScheduleStatusVisual(
        label: 'Selesai',
        icon: Icons.event_busy_outlined,
        color: AppColors.textMuted,
        backgroundColor: AppColors.surfaceMuted,
      );
    }
    return _ScheduleStatusVisual(
      label: schedule.availabilityReason,
      icon: Icons.lock_clock_outlined,
      color: AppColors.warning,
      backgroundColor: AppColors.warningSoft,
    );
  }
}

class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar({
    required this.prefix,
    required this.color,
    required this.backgroundColor,
  });

  final String prefix;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.person_outline, color: AppColors.textMuted),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: Text(
                prefix,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _ScheduleStatusVisual status;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 110),
      child: AppBadge(
        label: status.label,
        icon: status.icon,
        color: status.color,
        backgroundColor: status.backgroundColor,
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
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

class _GuidancePanel extends StatelessWidget {
  const _GuidancePanel({required this.schedule, required this.status});

  final ScheduleAvailability schedule;
  final _ScheduleStatusVisual status;

  @override
  Widget build(BuildContext context) {
    final isReady = schedule.canTakeQueue;
    final color = isReady ? AppColors.primaryDark : status.color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isReady ? Icons.check_circle_outline : status.icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              schedule.patientGuidance,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isReady ? AppColors.textPrimary : color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleStatusVisual {
  const _ScheduleStatusVisual({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
}
