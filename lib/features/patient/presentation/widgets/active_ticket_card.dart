import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_spacing.dart';
import '../../../../core/utils/queue_status.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../queue/data/models/queue_ticket_detail.dart';
import '../../../queue/providers/queue_provider.dart';

class ActiveTicketCard extends StatelessWidget {
  const ActiveTicketCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ticket = context.watch<QueueProvider>().activeTicket!;
    final status = queueStatusStyle(ticket.status);
    final remainingQueue = _remainingQueueCount(ticket);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ANTREAN AKTIF',
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    AppBadge(
                      label: status.label,
                      icon: status.icon,
                      color: AppColors.primaryDark,
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NOMOR ANDA',
                            style: TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            ticket.queueCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'SAAT INI',
                          style: TextStyle(
                            color: Color(0xCCFFFFFF),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          ticket.currentNumber == 0
                              ? '-'
                              : ticket.currentQueueLabel,
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(
                      Icons.medical_services_outlined,
                      color: Color(0xCCFFFFFF),
                      size: 17,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '${ticket.polyclinicName} - ${ticket.doctorName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricBox(
                        label: 'Posisi',
                        value: ticket.remainingBeforeMeLabel,
                        icon: Icons.groups_2_outlined,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _MetricBox(
                        label: 'Saat Ini',
                        value: ticket.currentQueueLabel,
                        icon: Icons.campaign_outlined,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _MetricBox(
                        label: 'Sisa',
                        value: remainingQueue.toString(),
                        icon: Icons.format_list_numbered_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.route_outlined),
                    label: const Text('Pantau Antrean'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _ProgressSteps(status: ticket.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryDark),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

int _remainingQueueCount(QueueTicketDetail ticket) {
  final remaining = ticket.lastNumber - ticket.currentNumber;
  if (remaining < 0) return 0;
  return remaining;
}

class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final activeIndex = switch (status) {
      'called' => 1,
      'missed' => 1,
      'serving' => 2,
      _ => 0,
    };
    final steps = [
      (Icons.check_rounded, 'Tiket Dibuat'),
      (Icons.radio_button_checked_rounded, 'Antre'),
      (Icons.notifications_active_outlined, 'Panggil'),
      (Icons.medical_services_outlined, 'Konsul'),
      (Icons.done_all_rounded, 'Selesai'),
    ];

    return Row(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          Expanded(
            child: _StepItem(
              icon: steps[index].$1,
              label: steps[index].$2,
              isActive: index <= activeIndex,
            ),
          ),
          if (index < steps.length - 1)
            Container(
              width: 12,
              height: 2,
              color: index < activeIndex ? AppColors.primary : AppColors.border,
            ),
        ],
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surfaceMuted,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isActive ? Colors.white : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isActive ? AppColors.primaryDark : AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
