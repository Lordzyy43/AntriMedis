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
            _NotificationSummary(
              total: provider.notifications.length,
              unread: provider.unreadCount,
            ),
            const SizedBox(height: AppSpacing.lg),
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

class _NotificationSummary extends StatelessWidget {
  const _NotificationSummary({required this.total, required this.unread});

  final int total;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: unread > 0 ? AppColors.primarySoft : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              unread > 0
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none_outlined,
              color: unread > 0 ? AppColors.primaryDark : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unread > 0
                      ? '$unread notifikasi belum dibaca'
                      : 'Semua notifikasi sudah dibaca',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$total pembaruan antrean tersimpan',
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
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final PatientNotification notification;

  @override
  Widget build(BuildContext context) {
    final tone = _toneForType(notification.type);
    final color = notification.isRead ? AppColors.textMuted : tone.color;

    return AppCard(
      onTap: notification.isRead
          ? null
          : () => context.read<NotificationProvider>().markAsRead(
              notification.id,
            ),
      backgroundColor: notification.isRead
          ? AppColors.surface
          : tone.backgroundColor,
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
            child: Icon(tone.icon, color: color, size: 20),
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

  _NotificationTone _toneForType(String type) {
    return switch (type) {
      'queue_created' => const _NotificationTone(
        icon: Icons.confirmation_number_outlined,
        color: AppColors.primary,
        backgroundColor: AppColors.primarySoft,
      ),
      'queue_called' => const _NotificationTone(
        icon: Icons.campaign_outlined,
        color: AppColors.warning,
        backgroundColor: AppColors.warningSoft,
      ),
      'queue_near' => const _NotificationTone(
        icon: Icons.timer_outlined,
        color: AppColors.violet,
        backgroundColor: AppColors.violetSoft,
      ),
      'queue_skipped' => const _NotificationTone(
        icon: Icons.skip_next_outlined,
        color: AppColors.warning,
        backgroundColor: AppColors.warningSoft,
      ),
      'queue_missed' => const _NotificationTone(
        icon: Icons.replay_outlined,
        color: AppColors.violet,
        backgroundColor: AppColors.violetSoft,
      ),
      'queue_cancelled' => const _NotificationTone(
        icon: Icons.cancel_outlined,
        color: AppColors.danger,
        backgroundColor: AppColors.dangerSoft,
      ),
      'queue_expired' => const _NotificationTone(
        icon: Icons.timer_off_outlined,
        color: AppColors.danger,
        backgroundColor: AppColors.dangerSoft,
      ),
      'schedule_changed' => const _NotificationTone(
        icon: Icons.event_repeat_outlined,
        color: AppColors.secondary,
        backgroundColor: AppColors.secondarySoft,
      ),
      _ => const _NotificationTone(
        icon: Icons.notifications_outlined,
        color: AppColors.primary,
        backgroundColor: AppColors.primarySoft,
      ),
    };
  }
}

class _NotificationTone {
  const _NotificationTone({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
}
