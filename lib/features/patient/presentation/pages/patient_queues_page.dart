import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_spacing.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../queue/providers/queue_provider.dart';
import 'queue_tracking_page.dart';
import '../widgets/queue_ticket_card.dart';

class PatientQueuesPage extends StatelessWidget {
  const PatientQueuesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<QueueProvider>();
    final activeTicket = queue.activeTicket;
    final historyTickets = queue.historyTickets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrean Saya'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: queue.isLoading
                ? null
                : () => context.read<QueueProvider>().refreshTickets(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: context.read<QueueProvider>().refreshTickets,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            104,
          ),
          children: [
            if (queue.error != null) ...[
              AppErrorBanner(message: queue.error!),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text('Aktif', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            if (activeTicket == null)
              const EmptyState(
                icon: Icons.confirmation_number_outlined,
                title: 'Belum ada antrean aktif',
                message:
                    'Ambil nomor dari jadwal praktik yang tersedia di halaman Home.',
              )
            else
              QueueTicketCard(
                ticket: activeTicket,
                onTap: () => _openTracking(context),
                onCancel: () => _confirmCancel(context),
              ),
            const SizedBox(height: AppSpacing.xl),
            Text('Riwayat', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            if (queue.isLoading && historyTickets.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (historyTickets.isEmpty)
              const EmptyState(
                icon: Icons.history_outlined,
                title: 'Riwayat masih kosong',
                message:
                    'Tiket selesai, dibatalkan, atau dilewati akan tampil di sini.',
              )
            else
              ...historyTickets.map(
                (ticket) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: QueueTicketCard(ticket: ticket),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openTracking(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const QueueTrackingPage()));
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Batalkan antrean?'),
          content: const Text(
            'Nomor antrean yang dibatalkan tidak bisa digunakan kembali.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Tidak'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Batalkan'),
            ),
          ],
        );
      },
    );

    if (ok != true || !context.mounted) return;
    await context.read<QueueProvider>().cancelActiveTicket();
  }
}
