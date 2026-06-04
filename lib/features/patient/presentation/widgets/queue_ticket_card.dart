import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_spacing.dart';
import '../../../../core/utils/queue_status.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../queue/data/models/queue_ticket_detail.dart';

class QueueTicketCard extends StatelessWidget {
  const QueueTicketCard({
    super.key,
    required this.ticket,
    this.onTap,
    this.onCancel,
  });

  final QueueTicketDetail ticket;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final status = queueStatusStyle(ticket.status);
    final createdAt = DateFormat('dd MMM yyyy, HH:mm').format(ticket.createdAt);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: status.backgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  ticket.queueCode,
                  style: TextStyle(
                    color: status.color,
                    fontSize: 16,
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
                      ticket.polyclinicName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.doctorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              AppBadge(
                label: status.label,
                icon: status.icon,
                color: status.color,
                backgroundColor: status.backgroundColor,
              ),
              if (onTap != null) ...[
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                _MetaRow(
                  icon: Icons.schedule_outlined,
                  label: 'Jadwal',
                  value:
                      '${DateFormat('dd MMM').format(ticket.scheduleDate)} - ${ticket.startTime}-${ticket.endTime}',
                ),
                const SizedBox(height: AppSpacing.sm),
                _MetaRow(
                  icon: Icons.location_on_outlined,
                  label: 'Cabang',
                  value: ticket.branchName,
                ),
                const SizedBox(height: AppSpacing.sm),
                _MetaRow(
                  icon: Icons.history_outlined,
                  label: 'Dibuat',
                  value: createdAt,
                ),
              ],
            ),
          ),
          if (ticket.isActive) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.status == 'waiting'
                        ? ticket.remainingBeforeMeLabel
                        : ticket.status == 'missed'
                        ? 'Menunggu kesempatan panggil ulang'
                        : 'Ikuti arahan petugas klinik',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (ticket.canCancel && onCancel != null)
                  OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Batalkan Saya'),
                  ),
              ],
            ),
          ] else if (ticket.statusReason?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: status.backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(status.icon, color: status.color, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      ticket.statusReason!,
                      style: TextStyle(
                        color: status.color,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Ketuk untuk melihat detail dan timeline.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
