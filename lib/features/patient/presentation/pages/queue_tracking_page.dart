import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/config/app_spacing.dart';
import '../../../../core/utils/queue_status.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_banner.dart';
import '../../../queue/data/models/queue_ticket_detail.dart';
import '../../../queue/data/models/queue_ticket_timeline_item.dart';
import '../../../queue/providers/queue_provider.dart';

class QueueTrackingPage extends StatefulWidget {
  const QueueTrackingPage({super.key, this.ticket});

  final QueueTicketDetail? ticket;

  @override
  State<QueueTrackingPage> createState() => _QueueTrackingPageState();
}

class _QueueTrackingPageState extends State<QueueTrackingPage> {
  QueueTicketDetail? _detail;
  List<QueueTicketTimelineItem>? _timeline;
  QueueProvider? _queueProvider;
  RealtimeChannel? _channel;
  String? _subscribedTicketId;
  bool _isTimelineLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final queue = context.read<QueueProvider>();
    _queueProvider = queue;
    final ticketId = widget.ticket?.ticketId ?? queue.trackingTicket?.ticketId;
    if (ticketId == null || ticketId == _subscribedTicketId) return;

    _subscribe(ticketId);
    _loadTicketData(ticketId);
  }

  Future<void> _subscribe(String ticketId) async {
    final queue = _queueProvider ?? context.read<QueueProvider>();
    final previous = _channel;
    if (previous != null) {
      await queue.unsubscribe(previous);
    }
    _subscribedTicketId = ticketId;
    _channel = queue.subscribeToTicketEvents(
      ticketId: ticketId,
      onChanged: () => _loadTicketData(ticketId),
    );
  }

  Future<void> _loadTicketData(String ticketId) async {
    if (!mounted) return;
    setState(() => _isTimelineLoading = _timeline == null);
    try {
      final queue = context.read<QueueProvider>();
      final results = await Future.wait([
        queue.fetchTicketDetail(ticketId),
        queue.fetchTicketTimeline(ticketId),
      ]);
      if (!mounted) return;
      setState(() {
        _detail = results[0] as QueueTicketDetail;
        _timeline = results[1] as List<QueueTicketTimelineItem>;
        _isTimelineLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isTimelineLoading = false);
    }
  }

  Future<void> _refresh(QueueTicketDetail selectedTicket) async {
    if (widget.ticket == null) {
      await context.read<QueueProvider>().refreshActiveTicket();
    }
    await _loadTicketData(selectedTicket.ticketId);
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) {
      _queueProvider?.unsubscribe(channel);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<QueueProvider>();
    final queueTicketId = queue.trackingTicket?.ticketId;
    if (widget.ticket == null &&
        queueTicketId != null &&
        queueTicketId != _subscribedTicketId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final latestTicketId = context.read<QueueProvider>().trackingTicket?.ticketId;
        if (latestTicketId == null || latestTicketId == _subscribedTicketId) {
          return;
        }
        _subscribe(latestTicketId);
        _loadTicketData(latestTicketId);
      });
    }
    final selectedTicket = _detail ?? widget.ticket ?? queue.trackingTicket;
    final isHistoricalDetail = widget.ticket != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isHistoricalDetail ? 'Detail Antrean' : 'Antrean Saya'),
      ),
      body: selectedTicket == null
          ? const _NoActiveQueueState()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: _TrackingHero(
                    ticket: selectedTicket,
                    queueCode: selectedTicket.queueCode,
                    progress: selectedTicket.progress,
                    status: selectedTicket.status,
                    title:
                        '${selectedTicket.polyclinicName} - ${selectedTicket.doctorName}',
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _refresh(selectedTicket),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        112,
                      ),
                      children: [
                        if (queue.error != null) ...[
                          AppErrorBanner(
                            message: queue.error!,
                            actionLabel: 'Muat ulang',
                            onAction: isHistoricalDetail
                                ? null
                                : queue.refreshActiveTicket,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (!selectedTicket.isActive) ...[
                          const SizedBox(height: AppSpacing.md),
                          _FinalResultPanel(ticket: selectedTicket),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        if (selectedTicket.isActive) ...[
                          _MetricGrid(
                            ticket: selectedTicket,
                            lastNumber: selectedTicket.lastNumber,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Timeline antrean',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _isTimelineLoading
                                  ? const Text(
                                      'Memuat timeline...',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : (_timeline ?? []).isEmpty
                                  ? _FallbackTicketTimeline(
                                      ticket: selectedTicket,
                                    )
                                  : _QueueEventTimeline(events: _timeline!),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detail klinik & jadwal',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const _DetailRow(
                                'Klinik',
                                'Klinik Sehat Sentosa',
                              ),
                              _DetailRow('Cabang', selectedTicket.branchName),
                              if (selectedTicket.branchAddress != null &&
                                  selectedTicket.branchAddress!
                                      .trim()
                                      .isNotEmpty)
                                _DetailRow(
                                  'Alamat',
                                  selectedTicket.branchAddress!,
                                ),
                              _DetailRow('Poli', selectedTicket.polyclinicName),
                              _DetailRow('Dokter', selectedTicket.doctorName),
                              _DetailRow(
                                'Tanggal',
                                DateFormat(
                                  'dd MMMM yyyy',
                                ).format(selectedTicket.scheduleDate),
                              ),
                              _DetailRow(
                                'Jam praktik',
                                '${selectedTicket.startTime}-${selectedTicket.endTime}',
                              ),
                            ],
                          ),
                        ),
                        if (!isHistoricalDetail &&
                            selectedTicket.canCancel) ...[
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: queue.isLoading
                                  ? null
                                  : () => _confirmCancel(context),
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Batalkan Antrean'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Batalkan antrean?'),
          content: const Text(
            'Antrean yang sudah dibatalkan tidak bisa dipakai kembali. Anda masih bisa mengambil nomor baru jika jadwal dan kuota tersedia.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Tidak'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Batalkan Antrean'),
            ),
          ],
        );
      },
    );

    if (ok != true || !context.mounted) return;
    final cancelled = await context.read<QueueProvider>().cancelActiveTicket();
    if (cancelled && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Antrean berhasil dibatalkan.')),
      );
      Navigator.of(context).pop();
    } else if (context.mounted) {
      final message =
          context.read<QueueProvider>().error ?? 'Gagal membatalkan antrean.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _FinalResultPanel extends StatelessWidget {
  const _FinalResultPanel({required this.ticket});

  final QueueTicketDetail ticket;

  @override
  Widget build(BuildContext context) {
    final style = queueStatusStyle(ticket.status);
    final copy = _copyFor(ticket);

    return AppCard(
      backgroundColor: style.backgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(style.icon, color: style.color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.title,
                  style: TextStyle(
                    color: style.color,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  copy.message,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _FinalCopy _copyFor(QueueTicketDetail ticket) {
    final reasonText = ticket.statusReason?.trim() ?? '';
    final reasonLower = reasonText.toLowerCase();
    
    final byPatient = reasonLower.contains('pasien') || reasonLower.contains('oleh anda');
    final byClosedSession =
        reasonLower.contains('sesi ditutup') ||
        reasonLower.contains('sesi layanan telah ditutup');

    String appendReason(String defaultMessage) {
      if (reasonText.isEmpty || byPatient) return defaultMessage;
      return '$defaultMessage Catatan: $reasonText';
    }

    return switch (ticket.status) {
      'completed' => const _FinalCopy(
        title: 'Kunjungan selesai',
        message:
            'Antrean ini sudah selesai dilayani. Detail kunjungan tetap tersimpan di riwayat Anda.',
      ),
      'cancelled' => _FinalCopy(
        title: byPatient
            ? 'Antrean dibatalkan oleh Anda'
            : 'Antrean dibatalkan petugas',
        message: byPatient
            ? 'Anda membatalkan antrean ini saat status masih menunggu.'
            : appendReason('Petugas klinik membatalkan antrean ini.'),
      ),
      'skipped' => _FinalCopy(
        title: 'Nomor antrean dilewati',
        message: appendReason('Nomor Anda dilewati oleh petugas.'),
      ),
      'expired' => _FinalCopy(
        title: byClosedSession ? 'Sesi layanan ditutup' : 'Antrean kedaluwarsa',
        message: byClosedSession
            ? 'Sesi layanan ditutup sebelum nomor Anda dipanggil. Nomor ini tidak lagi aktif dan tersimpan di riwayat.'
            : 'Antrean ini sudah melewati batas operasional dan tidak lagi aktif.',
      ),
      _ => const _FinalCopy(
        title: 'Antrean final',
        message: 'Antrean ini sudah tidak aktif.',
      ),
    };
  }
}

class _FinalCopy {
  const _FinalCopy({required this.title, required this.message});

  final String title;
  final String message;
}

class _NoActiveQueueState extends StatelessWidget {
  const _NoActiveQueueState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tidak ada antrean aktif',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Ambil nomor dari jadwal praktik hari ini untuk mulai memantau posisi antrean.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.event_available_outlined),
                label: const Text('Lihat Jadwal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingHero extends StatelessWidget {
  const _TrackingHero({
    required this.ticket,
    required this.queueCode,
    required this.progress,
    required this.status,
    required this.title,
  });

  final QueueTicketDetail ticket;
  final String queueCode;
  final double progress;
  final String status;
  final String title;

  @override
  Widget build(BuildContext context) {
    final style = queueStatusStyle(status);
    final isActive = [
      'waiting',
      'called',
      'serving',
      'missed',
    ].contains(status);

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE0F7F6), AppColors.surface],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -32,
              top: -36,
              child: Icon(
                Icons.radar_outlined,
                size: 150,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Row(
                    children: [
                      AppBadge(
                        label: style.label,
                        icon: style.icon,
                        color: style.color,
                        backgroundColor: style.backgroundColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CircularPercentIndicator(
                    radius: 92,
                    lineWidth: 14,
                    percent: progress,
                    animation: true,
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: AppColors.primary,
                    backgroundColor: AppColors.border,
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Nomor Anda',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        Text(
                          queueCode,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          isActive ? ticket.remainingBeforeMeLabel : 'Riwayat',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _statusMessage(status),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroMiniStat(
                          label: 'Nomor Saat Ini',
                          value: ticket.currentQueueLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusMessage(String status) {
    return switch (status) {
      'waiting' => 'Pantau nomor berjalan dan bersiap mendekati giliran.',
      'called' => 'Nomor Anda sedang dipanggil. Segera menuju poli.',
      'serving' => 'Anda sedang dilayani oleh petugas klinik.',
      'missed' =>
        'Nomor Anda terlewat. Tunggu petugas memanggil ulang setelah antrean reguler selesai.',
      'completed' => 'Kunjungan selesai. Terima kasih.',
      'skipped' => 'Nomor Anda dilewati oleh petugas klinik.',
      'cancelled' => 'Antrean ini sudah dibatalkan.',
      _ => status,
    };
  }
}

class _HeroMiniStat extends StatelessWidget {
  const _HeroMiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
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
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.ticket, required this.lastNumber});

  final QueueTicketDetail ticket;
  final int lastNumber;

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.35,
      ),
      children: [
        // Card Perkiraan diganti menjadi Sisa Antrean
        _MetricCard(
          icon: Icons.people_outline,
          label: 'Sisa antrean',
          value: '${ticket.remainingBeforeMe} orang',
          color: AppColors.warning,
          backgroundColor: AppColors.warningSoft,
        ),
        _MetricCard(
          icon: Icons.confirmation_number_outlined,
          label: 'Nomor terakhir',
          value: lastNumber.toString(),
          color: AppColors.secondary,
          backgroundColor: AppColors.secondarySoft,
        ),
      ],
    );
  }
}

String _jakartaTimeLabel(DateTime value) {
  final jakartaTime = value.toUtc().add(const Duration(hours: 7));
  return '${DateFormat('HH:mm').format(jakartaTime)} WIB';
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _QueueEventTimeline extends StatelessWidget {
  const _QueueEventTimeline({required this.events});

  final List<QueueTicketTimelineItem> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < events.length; index++)
          _TimelineStep(
            icon: _iconForStatus(events[index].newStatus),
            title: _labelForStatus(events[index].newStatus),
            subtitle: _eventSubtitle(events[index]),
            isActive: true,
            isLast: index == events.length - 1,
          ),
      ],
    );
  }

  String _eventSubtitle(QueueTicketTimelineItem event) {
    final time = _jakartaTimeLabel(event.createdAt);
    final actor = switch (event.actorType) {
      'patient' => 'oleh Anda',
      'staff' => 'oleh petugas',
      _ => 'oleh sistem',
    };
    final message = event.message?.trim();
    if (message == null || message.isEmpty) return '$time - $actor';
    return '$time - $message';
  }
}

class _FallbackTicketTimeline extends StatelessWidget {
  const _FallbackTicketTimeline({required this.ticket});

  final QueueTicketDetail ticket;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _TimelineStep(
          icon: Icons.confirmation_number_outlined,
          title: 'Nomor dibuat',
          isActive: true,
        ),
        _TimelineStep(
          icon: Icons.access_time_outlined,
          title: 'Masuk antrean',
          subtitle: _jakartaTimeLabel(ticket.createdAt),
          isActive: true,
        ),
        _TimelineStep(
          icon: Icons.campaign_outlined,
          title: 'Nomor dipanggil',
          subtitle: _formatNullableTime(ticket.calledAt),
          isActive: [
            'called',
            'serving',
            'completed',
            'missed',
          ].contains(ticket.status),
        ),
        _TimelineStep(
          icon: Icons.medical_services_outlined,
          title: 'Sedang dilayani',
          subtitle: _formatNullableTime(ticket.servingStartedAt),
          isActive: ['serving', 'completed'].contains(ticket.status),
        ),
        _TimelineStep(
          icon: _iconForStatus(ticket.status),
          title: _labelForStatus(ticket.status),
          subtitle: _formatNullableTime(_finalTime(ticket)),
          isActive: !ticket.isActive,
          isLast: true,
        ),
      ],
    );
  }

  String? _formatNullableTime(DateTime? value) {
    if (value == null) return null;
    return _jakartaTimeLabel(value);
  }

  DateTime? _finalTime(QueueTicketDetail ticket) {
    return switch (ticket.status) {
      'completed' => ticket.completedAt,
      'skipped' => ticket.skippedAt,
      'cancelled' => ticket.cancelledAt,
      'expired' => ticket.expiredAt,
      _ => null,
    };
  }
}

IconData _iconForStatus(String status) {
  return switch (status) {
    'waiting' => Icons.hourglass_top_rounded,
    'called' => Icons.campaign_outlined,
    'serving' => Icons.medical_services_outlined,
    'missed' => Icons.replay_outlined,
    'completed' => Icons.check_circle_outline,
    'skipped' => Icons.skip_next_rounded,
    'cancelled' => Icons.cancel_outlined,
    'expired' => Icons.timer_off_outlined,
    _ => Icons.info_outline,
  };
}

String _labelForStatus(String status) {
  return switch (status) {
    'waiting' => 'Menunggu',
    'called' => 'Dipanggil',
    'serving' => 'Dilayani',
    'missed' => 'Terlewat',
    'completed' => 'Selesai',
    'skipped' => 'Dilewati',
    'cancelled' => 'Dibatalkan',
    'expired' => 'Kedaluwarsa',
    _ => status,
  };
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.title,
    required this.isActive,
    this.subtitle,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primarySoft
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 22,
                color: isActive ? AppColors.primarySoft : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
