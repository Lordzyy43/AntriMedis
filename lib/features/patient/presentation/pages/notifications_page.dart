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
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: RefreshIndicator(
        onRefresh: context.read<NotificationProvider>().load,
        edgeOffset: 110, // Menyesuaikan posisi spinner agar pas di bawah header kontemporer
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(), // Efek scroll membal elastis khas iOS/Premium Android
          ),
          slivers: [
            // --- PREMIUM INTEGRATED HEADER ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  64, // Jarak top lebih tinggi untuk kenyamanan visual tanpa AppBar kaku
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: _CleanEvolvedHeader(
                  total: provider.notifications.length,
                  unread: provider.unreadCount,
                ),
              ),
            ),

            // --- ERROR BANNER STATE ---
            if (provider.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: AppErrorBanner(message: provider.error!),
                ),
              ),

            // --- MAIN CONTENT CONTENT STATES (LOADING / EMPTY / LIST) ---
            if (provider.isLoading && provider.notifications.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
              )
            else if (provider.notifications.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 104),
                  child: EmptyState(
                    icon: Icons.notifications_none_outlined,
                    title: 'Belum ada notifikasi',
                    message: 'Pembaruan antrean dan jadwal akan tersimpan di sini.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  120, // Ruang aman di bawah untuk navigation bar
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final notification = provider.notifications[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      key: ValueKey(notification.id),
                      child: _ElegantNotificationCard(notification: notification),
                    );
                  }, childCount: provider.notifications.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// REFACTORED SUB-COMPONENTS
// ============================================================================

class _CleanEvolvedHeader extends StatelessWidget {
  const _CleanEvolvedHeader({required this.total, required this.unread});

  final int total;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Notifikasi',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimaryOf(context),
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            // Tombol interaktif fungsional nan elegan
            if (unread > 0)
              TextButton(
                onPressed: () {
                  // Tambahkan fungsi mark all as read dari provider kamu jika ada di masa depan
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Baca Semua',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: unread > 0
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.textMutedOf(context).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                unread > 0 ? '$unread Belum Dibaca' : 'Semua Dibaca',
                style: TextStyle(
                  color: unread > 0 ? AppColors.primary : AppColors.textMutedOf(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '•  $total Total riwayat',
              style: TextStyle(
                color: AppColors.textMutedOf(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        const Divider(height: 24, thickness: 0.8),
      ],
    );
  }
}

class _ElegantNotificationCard extends StatelessWidget {
  const _ElegantNotificationCard({required this.notification});

  final PatientNotification notification;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final tone = _toneForType(notification.type);

    // Konfigurasi warna premium adaptive
    final cardBgColor = notification.isRead
        ? AppColors.surfaceOf(context)
        : (isDark
              ? tone.color.withValues(alpha: 0.06)
              : tone.backgroundColor.withValues(alpha: 0.45));

    final iconContainerColor = notification.isRead
        ? AppColors.textMutedOf(context).withValues(alpha: 0.06)
        : tone.color.withValues(alpha: 0.1);

    final iconColor = notification.isRead ? AppColors.textMutedOf(context) : tone.color;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        onTap: notification.isRead
            ? null
            : () => context.read<NotificationProvider>().markAsRead(notification.id),
        backgroundColor: cardBgColor,
        padding: EdgeInsets.zero, // Padding diatur manual di dalam agar border strip presisi
        child: Container(
          // Garis aksen vertikal tipis di sisi kiri kartu untuk tanda visual indikatif
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: notification.isRead ? Colors.transparent : tone.color,
                width: 3.5,
              ),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ICON LAYER ---
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconContainerColor,
                  shape: BoxShape.circle, // Bentuk lingkaran terasa lebih modern di list notifikasi
                ),
                child: Icon(tone.icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),

              // --- TEXT CONTENT LAYER ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: AppColors.textPrimaryOf(context),
                              fontWeight: notification.isRead ? FontWeight.w700 : FontWeight.w900,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: AppSpacing.xs),
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(color: tone.color, shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: notification.isRead
                            ? AppColors.textMutedOf(context)
                            : AppColors.textPrimaryOf(context).withValues(alpha: 0.8),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      DateFormat('dd MMM yyyy • HH:mm').format(notification.createdAt),
                      style: TextStyle(
                        color: AppColors.textMutedOf(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
  const _NotificationTone({required this.icon, required this.color, required this.backgroundColor});

  final IconData icon;
  final Color color;
  final Color backgroundColor;
}
