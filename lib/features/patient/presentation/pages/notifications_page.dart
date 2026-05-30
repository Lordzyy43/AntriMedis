import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../notifications/data/models/patient_notification.dart';
import '../../../notifications/providers/notification_provider.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: provider.isLoading
                ? null
                : () => context.read<NotificationProvider>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: context.read<NotificationProvider>().load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            104,
          ),
          children: [
            if (provider.error != null) ...[
              AppErrorBanner(message: provider.error!),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (provider.isLoading && provider.notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.notifications.isEmpty)
              const EmptyState(
                icon: Icons.notifications_none_outlined,
                title: 'Belum ada notifikasi',
                message: 'Pembaruan antrean dan jadwal akan tersimpan di sini.',
              )
            else
              ...provider.notifications.map(
                (notification) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _NotificationCard(notification: notification),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final PatientNotification notification;

  @override
  Widget build(BuildContext context) {
    final icon = _iconForType(notification.type);
    final color = notification.isRead ? AppColors.textMuted : AppColors.primary;

    return AppCard(
      onTap: notification.isRead
          ? null
          : () => context.read<NotificationProvider>().markAsRead(
              notification.id,
            ),
      backgroundColor: notification.isRead
          ? AppColors.surface
          : AppColors.primarySoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: notification.isRead
                  ? AppColors.surfaceMuted
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      const Icon(
                        Icons.circle,
                        size: 10,
                        color: AppColors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  notification.body,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  DateFormat(
                    'dd MMM yyyy, HH:mm',
                  ).format(notification.createdAt),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'queue_created' => Icons.confirmation_number_outlined,
      'queue_called' => Icons.campaign_outlined,
      'queue_near' => Icons.timer_outlined,
      'queue_skipped' => Icons.skip_next_outlined,
      'queue_cancelled' => Icons.cancel_outlined,
      'schedule_changed' => Icons.event_repeat_outlined,
      _ => Icons.notifications_outlined,
    };
  }
}
