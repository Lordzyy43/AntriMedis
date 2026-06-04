import 'package:flutter/material.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';

class TodaySummary extends StatelessWidget {
  const TodaySummary({
    super.key,
    required this.scheduleCount,
    required this.takeableCount,
    required this.unavailableCount,
    required this.activeTicketCode,
    required this.isLoading,
  });

  final int scheduleCount;
  final int takeableCount;
  final int unavailableCount;
  final String? activeTicketCode;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        final tileWidth = isWide
            ? (constraints.maxWidth - AppSpacing.md * 3) / 4
            : (constraints.maxWidth - AppSpacing.md) / 2;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _SummaryTile(
              width: tileWidth,
              icon: Icons.event_available_outlined,
              label: 'Jadwal',
              value: isLoading ? '-' : scheduleCount.toString(),
              color: AppColors.secondary,
              backgroundColor: AppColors.secondarySoft,
            ),
            _SummaryTile(
              width: tileWidth,
              icon: Icons.task_alt_outlined,
              label: 'Bisa Diambil',
              value: isLoading ? '-' : takeableCount.toString(),
              color: AppColors.success,
              backgroundColor: AppColors.successSoft,
            ),
            _SummaryTile(
              width: tileWidth,
              icon: Icons.lock_clock_outlined,
              label: 'Belum Siap',
              value: isLoading ? '-' : unavailableCount.toString(),
              color: AppColors.warning,
              backgroundColor: AppColors.warningSoft,
            ),
            _SummaryTile(
              width: tileWidth,
              icon: Icons.confirmation_number_outlined,
              label: 'Tiket Aktif',
              value: activeTicketCode ?? '-',
              color: AppColors.primaryDark,
              backgroundColor: AppColors.primarySoft,
            ),
          ],
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
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
          ],
        ),
      ),
    );
  }
}
