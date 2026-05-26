import 'package:flutter/material.dart';

import '../config/app_colors.dart';

class QueueStatusStyle {
  const QueueStatusStyle({
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData icon;
}

QueueStatusStyle queueStatusStyle(String status) {
  return switch (status) {
    'waiting' => const QueueStatusStyle(
      label: 'Menunggu',
      color: AppColors.secondary,
      backgroundColor: AppColors.secondarySoft,
      icon: Icons.hourglass_top_rounded,
    ),
    'called' => const QueueStatusStyle(
      label: 'Dipanggil',
      color: AppColors.warning,
      backgroundColor: AppColors.warningSoft,
      icon: Icons.campaign_rounded,
    ),
    'serving' => const QueueStatusStyle(
      label: 'Dilayani',
      color: AppColors.primaryDark,
      backgroundColor: AppColors.primarySoft,
      icon: Icons.medical_services_outlined,
    ),
    'completed' => const QueueStatusStyle(
      label: 'Selesai',
      color: AppColors.success,
      backgroundColor: AppColors.successSoft,
      icon: Icons.check_circle_outline,
    ),
    'skipped' => const QueueStatusStyle(
      label: 'Dilewati',
      color: AppColors.danger,
      backgroundColor: AppColors.dangerSoft,
      icon: Icons.skip_next_rounded,
    ),
    'cancelled' => const QueueStatusStyle(
      label: 'Dibatalkan',
      color: AppColors.danger,
      backgroundColor: AppColors.dangerSoft,
      icon: Icons.cancel_outlined,
    ),
    _ => QueueStatusStyle(
      label: status,
      color: AppColors.textMuted,
      backgroundColor: AppColors.surfaceMuted,
      icon: Icons.info_outline,
    ),
  };
}
