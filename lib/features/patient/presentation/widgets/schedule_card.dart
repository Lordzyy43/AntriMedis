import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final date = DateFormat('dd MMM yyyy').format(schedule.scheduleDate);
    final serviceColor = _serviceColor(schedule.queuePrefix);
    final quotaProgress = schedule.quotaLimit == 0
        ? 0.0
        : (schedule.totalTaken / schedule.quotaLimit).clamp(0.0, 1.0);
    final isUnavailable = !schedule.canTakeQueue;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: serviceColor.$2,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: serviceColor.$1.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    schedule.queuePrefix,
                    style: TextStyle(
                      color: serviceColor.$1,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.polyclinicName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        schedule.doctorName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (schedule.specialization != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          schedule.specialization!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                isUnavailable
                    ? _AvailabilityBadge(reason: schedule.availabilityReason)
                    : _QuotaBadge(remaining: schedule.remainingQuota),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    schedule.branchName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.schedule_outlined, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text('${schedule.startTime}-${schedule.endTime}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    AppBadge(
                      label: date,
                      icon: Icons.event_available_outlined,
                      color: AppColors.primaryDark,
                      backgroundColor: AppColors.primarySoft,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppBadge(
                        label:
                            '± ${schedule.averageServiceMinutes} mnt / pasien',
                        icon: Icons.timer_outlined,
                        color: AppColors.violet,
                        backgroundColor: AppColors.violetSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: quotaProgress,
                    color: schedule.remainingQuota <= 5
                        ? AppColors.warning
                        : AppColors.primary,
                    backgroundColor: AppColors.border,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (isUnavailable) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningSoft.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            schedule.availabilityReason,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Diambil ${schedule.totalTaken}/${schedule.quotaLimit}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: ElevatedButton.icon(
                        onPressed: isDisabled ? null : onTakeQueue,
                        icon: const Icon(Icons.confirmation_number_outlined),
                        label: Text(
                          disabledLabel ?? 'Ambil Nomor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _serviceColor(String prefix) {
    return switch (prefix) {
      'G' => (AppColors.secondary, AppColors.secondarySoft),
      'A' => (AppColors.warning, AppColors.warningSoft),
      _ => (AppColors.primaryDark, AppColors.primarySoft),
    };
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: AppBadge(
        label: reason,
        icon: Icons.lock_clock_outlined,
        color: AppColors.warning,
        backgroundColor: AppColors.warningSoft,
      ),
    );
  }
}

class _QuotaBadge extends StatelessWidget {
  const _QuotaBadge({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: 'Sisa $remaining',
      icon: Icons.people_alt_outlined,
      color: remaining <= 5 ? AppColors.warning : AppColors.secondary,
      backgroundColor: remaining <= 5
          ? AppColors.warningSoft
          : AppColors.secondarySoft,
    );
  }
}
