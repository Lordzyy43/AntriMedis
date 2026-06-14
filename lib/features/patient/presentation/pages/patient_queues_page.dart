import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_spacing.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../queue/data/models/queue_ticket_detail.dart';
import '../../../queue/providers/queue_provider.dart';
import '../widgets/queue_ticket_card.dart';
import 'queue_tracking_page.dart';

class PatientQueuesPage extends StatelessWidget {
  const PatientQueuesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<QueueProvider>();
    final activeTicket = queue.activeTicket;
    final historyTickets = queue.historyTickets;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: RefreshIndicator(
        onRefresh: context.read<QueueProvider>().refreshTickets,
        edgeOffset: 110, // Selaras sempurna di bawah susunan header baru
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // --- PREMIUM INTEGRATED HEADER ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  64, // Ruang atas cinematic tanpa AppBar kaku
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: _CleanEvolvedQueueHeader(
                  activeCode: activeTicket?.queueCode,
                  historyCount: historyTickets.length,
                ),
              ),
            ),

            // --- ERROR BANNER STATE ---
            if (queue.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: AppErrorBanner(message: queue.error!),
                ),
              ),

            // --- SECTION: ACTIVE TICKET ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: _SectionLabel(
                  label: 'Antrean Aktif',
                  isBadgeActive: activeTicket != null,
                  badgeText: activeTicket != null ? 'Berjalan' : 'Kosong',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: activeTicket == null
                    ? const EmptyState(
                        icon: Icons.confirmation_number_outlined,
                        title: 'Belum ada antrean aktif',
                        message: 'Ambil nomor dari jadwal praktik yang tersedia di halaman Home.',
                      )
                    : QueueTicketCard(
                        ticket: activeTicket,
                        onTap: () => _openTracking(context, activeTicket),
                        onCancel: () => _confirmCancel(context),
                      ),
              ),
            ),

            // --- SECTION: HISTORY TICKETS ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: _SectionLabel(
                  label: 'Riwayat Kunjungan',
                  isBadgeActive: false,
                  badgeText: '${historyTickets.length} Tiket',
                ),
              ),
            ),

            if (queue.isLoading && historyTickets.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
              )
            else if (historyTickets.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 64),
                  child: EmptyState(
                    icon: Icons.history_outlined,
                    title: 'Riwayat masih kosong',
                    message: 'Tiket selesai, dibatalkan, atau dilewati akan tampil di sini.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final ticket = historyTickets[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      key: ValueKey(ticket.queueCode),
                      child: QueueTicketCard(
                        ticket: ticket,
                        onTap: () => _openTracking(context, ticket),
                      ),
                    );
                  }, childCount: historyTickets.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openTracking(BuildContext context, QueueTicketDetail ticket) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => QueueTrackingPage(ticket: ticket)));
  }

  // --- PREMIUM HIGH-END CUSTOM CONFIRMATION DIALOG ---
  Future<void> _confirmCancel(BuildContext context) async {

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surfaceOf(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon Glow Visual
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.report_problem_outlined,
                    color: AppColors.danger,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Batalkan Antrean?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimaryOf(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Nomor antrean yang dibatalkan akan hangus permanent dan tidak bisa pulih kembali.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMutedOf(context),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          side: BorderSide(
                            color: AppColors.textMutedOf(context).withValues(alpha: 0.2),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Kembali',
                          style: TextStyle(
                            color: AppColors.textPrimaryOf(context),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Ya, Batalkan',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (ok != true || !context.mounted) return;
    await context.read<QueueProvider>().cancelActiveTicket();
  }
}

// ============================================================================
// CLEAN INLINE COMPONENT REFACTORING
// ============================================================================

class _CleanEvolvedQueueHeader extends StatelessWidget {
  const _CleanEvolvedQueueHeader({required this.activeCode, required this.historyCount});

  final String? activeCode;
  final int historyCount;

  @override
  Widget build(BuildContext context) {
    final hasActive = activeCode != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Antrean Saya',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimaryOf(context),
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasActive
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.textMutedOf(context).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                hasActive ? 'Token: $activeCode' : 'Tidak Ada Tiket Aktif',
                style: TextStyle(
                  color: hasActive ? AppColors.primary : AppColors.textMutedOf(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '•  $historyCount total riwayat klinis',
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.isBadgeActive, required this.badgeText});

  final String label;
  final bool isBadgeActive;
  final String badgeText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimaryOf(context),
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        Text(
          badgeText,
          style: TextStyle(
            color: isBadgeActive ? AppColors.primary : AppColors.textMutedOf(context),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
