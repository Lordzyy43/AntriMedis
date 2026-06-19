class NotificationCopy {
  const NotificationCopy({
    required this.eventType,
    required this.category,
    required this.defaultRoute,
    required this.pushEnabled,
    required this.title,
    required this.body,
    required this.inboxTitle,
    required this.inboxBody,
    required this.pushTitle,
    required this.pushBody,
    required this.localTitle,
    required this.localBody,
    required this.rule,
  });

  final String eventType;
  final NotificationCopyCategory category;
  final String defaultRoute;
  final bool pushEnabled;
  final String title;
  final String body;
  final String inboxTitle;
  final String inboxBody;
  final String pushTitle;
  final String pushBody;
  final String localTitle;
  final String localBody;
  final String rule;
}

enum NotificationCopyCategory { informative, actionRequired, finalStatus }

const notificationCopyCatalog = <String, NotificationCopy>{
  'queue_created': NotificationCopy(
    eventType: 'queue_created',
    category: NotificationCopyCategory.informative,
    defaultRoute: 'queue_tracking',
    pushEnabled: true,
    title: 'Nomor antrean berhasil dibuat',
    body: 'Nomor antrean Anda adalah {queue_code}.',
    inboxTitle: 'Nomor antrean berhasil dibuat',
    inboxBody: 'Nomor antrean Anda adalah {queue_code}.',
    pushTitle: 'Nomor antrean berhasil dibuat',
    pushBody: 'Nomor antrean Anda adalah {queue_code}.',
    localTitle: 'Nomor antrean berhasil dibuat',
    localBody: 'Nomor antrean Anda adalah {queue_code}.',
    rule: 'Dipakai saat tiket baru berhasil dibuat.',
  ),
  'queue_near': NotificationCopy(
    eventType: 'queue_near',
    category: NotificationCopyCategory.informative,
    defaultRoute: 'queue_tracking',
    pushEnabled: false,
    title: 'Giliran Anda semakin dekat',
    body: 'Nomor {queue_code} tinggal {remaining} antrean lagi. Mohon bersiap.',
    inboxTitle: 'Giliran Anda semakin dekat',
    inboxBody:
        'Nomor {queue_code} tinggal {remaining} antrean lagi. Mohon bersiap.',
    pushTitle: 'Giliran Anda semakin dekat',
    pushBody:
        'Nomor {queue_code} tinggal {remaining} antrean lagi. Mohon bersiap.',
    localTitle: 'Giliran Anda semakin dekat',
    localBody:
        'Nomor {queue_code} tinggal {remaining} antrean lagi. Mohon bersiap.',
    rule: 'Dipakai lokal saja saat antrean di depan pasien tersisa 1-2 nomor.',
  ),
  'queue_called': NotificationCopy(
    eventType: 'queue_called',
    category: NotificationCopyCategory.actionRequired,
    defaultRoute: 'queue_tracking',
    pushEnabled: true,
    title: 'Nomor Anda dipanggil',
    body: 'Nomor {queue_code} sedang dipanggil. Segera menuju poli.',
    inboxTitle: 'Nomor Anda dipanggil',
    inboxBody: 'Nomor {queue_code} sedang dipanggil. Segera menuju poli.',
    pushTitle: 'Nomor Anda dipanggil',
    pushBody: 'Nomor {queue_code} sedang dipanggil. Segera menuju poli.',
    localTitle: 'Nomor Anda dipanggil',
    localBody: 'Nomor {queue_code} sedang dipanggil. Segera menuju poli.',
    rule: 'Dipakai saat petugas memanggil nomor aktif.',
  ),
  'queue_missed': NotificationCopy(
    eventType: 'queue_missed',
    category: NotificationCopyCategory.actionRequired,
    defaultRoute: 'queue_tracking',
    pushEnabled: true,
    title: 'Nomor Anda terlewat',
    body:
        'Nomor {queue_code} terlewat. Tunggu panggilan ulang setelah antrean reguler selesai.',
    inboxTitle: 'Nomor Anda terlewat',
    inboxBody:
        'Nomor {queue_code} terlewat. Tunggu panggilan ulang setelah antrean reguler selesai.',
    pushTitle: 'Nomor Anda terlewat',
    pushBody:
        'Nomor {queue_code} terlewat. Tunggu panggilan ulang setelah antrean reguler selesai.',
    localTitle: 'Nomor Anda terlewat',
    localBody:
        'Nomor {queue_code} terlewat. Tunggu panggilan ulang setelah antrean reguler selesai.',
    rule: 'Dipakai saat status berubah menjadi missed.',
  ),
  'queue_skipped': NotificationCopy(
    eventType: 'queue_skipped',
    category: NotificationCopyCategory.finalStatus,
    defaultRoute: 'notifications',
    pushEnabled: true,
    title: 'Antrean dilewati',
    body: 'Nomor {queue_code} dilewati oleh petugas.',
    inboxTitle: 'Antrean dilewati',
    inboxBody: 'Nomor {queue_code} dilewati oleh petugas.',
    pushTitle: 'Antrean dilewati',
    pushBody: 'Nomor {queue_code} dilewati oleh petugas.',
    localTitle: 'Antrean dilewati',
    localBody: 'Nomor {queue_code} dilewati oleh petugas.',
    rule: 'Dipakai saat nomor di-skip final oleh petugas.',
  ),
  'queue_cancelled': NotificationCopy(
    eventType: 'queue_cancelled',
    category: NotificationCopyCategory.finalStatus,
    defaultRoute: 'notifications',
    pushEnabled: true,
    title: 'Antrean dibatalkan',
    body: 'Nomor {queue_code} dibatalkan.',
    inboxTitle: 'Antrean dibatalkan',
    inboxBody: 'Nomor {queue_code} dibatalkan.',
    pushTitle: 'Antrean dibatalkan',
    pushBody: 'Nomor {queue_code} dibatalkan.',
    localTitle: 'Antrean dibatalkan',
    localBody: 'Nomor {queue_code} dibatalkan.',
    rule: 'Dipakai saat tiket dibatalkan oleh pasien atau petugas.',
  ),
  'queue_expired': NotificationCopy(
    eventType: 'queue_expired',
    category: NotificationCopyCategory.finalStatus,
    defaultRoute: 'notifications',
    pushEnabled: true,
    title: 'Antrean kedaluwarsa',
    body: 'Nomor {queue_code} kedaluwarsa karena sesi layanan telah ditutup.',
    inboxTitle: 'Antrean kedaluwarsa',
    inboxBody:
        'Nomor {queue_code} kedaluwarsa karena sesi layanan telah ditutup.',
    pushTitle: 'Antrean kedaluwarsa',
    pushBody:
        'Nomor {queue_code} kedaluwarsa karena sesi layanan telah ditutup.',
    localTitle: 'Antrean kedaluwarsa',
    localBody:
        'Nomor {queue_code} kedaluwarsa karena sesi layanan telah ditutup.',
    rule: 'Dipakai saat sesi ditutup dan waiting berubah expired.',
  ),
  'schedule_changed': NotificationCopy(
    eventType: 'schedule_changed',
    category: NotificationCopyCategory.informative,
    defaultRoute: 'home',
    pushEnabled: true,
    title: 'Jadwal layanan berubah',
    body: 'Jadwal layanan Anda berubah. Cek detail terbaru di aplikasi.',
    inboxTitle: 'Jadwal layanan berubah',
    inboxBody: 'Jadwal layanan Anda berubah. Cek detail terbaru di aplikasi.',
    pushTitle: 'Jadwal layanan berubah',
    pushBody: 'Jadwal layanan Anda berubah. Cek detail terbaru di aplikasi.',
    localTitle: 'Jadwal layanan berubah',
    localBody: 'Jadwal layanan Anda berubah. Cek detail terbaru di aplikasi.',
    rule: 'Dipakai hanya jika perubahan jadwal benar-benar signifikan.',
  ),
};

NotificationCopy? notificationCopyForType(String? eventType) {
  if (eventType == null) return null;
  return notificationCopyCatalog[eventType];
}

bool shouldPushNotificationType(String? eventType) {
  return notificationCopyForType(eventType)?.pushEnabled ?? true;
}

String notificationRouteForType(String? eventType) {
  return notificationCopyForType(eventType)?.defaultRoute ?? 'notifications';
}

String renderNotificationCopy(
  String template, {
  required Map<String, Object?> values,
}) {
  var rendered = template;
  for (final entry in values.entries) {
    rendered = rendered.replaceAll('{${entry.key}}', '${entry.value ?? ''}');
  }
  return rendered;
}

String renderNotificationTitle(
  String? eventType, {
  required Map<String, Object?> values,
  String? fallbackTitle,
}) {
  final copy = notificationCopyForType(eventType);
  final template = copy?.title ?? fallbackTitle ?? 'Pembaruan notifikasi';
  return renderNotificationCopy(template, values: values);
}

String renderNotificationBody(
  String? eventType, {
  required Map<String, Object?> values,
  String? fallbackBody,
}) {
  final copy = notificationCopyForType(eventType);
  final template = copy?.body ?? fallbackBody ?? 'Ada pembaruan terbaru.';
  return renderNotificationCopy(template, values: values);
}

String renderLocalNotificationTitle(
  String? eventType, {
  required Map<String, Object?> values,
  String? fallbackTitle,
}) {
  final copy = notificationCopyForType(eventType);
  final template = copy?.localTitle ?? copy?.title ?? fallbackTitle;
  return renderNotificationCopy(
    template ?? 'Pembaruan notifikasi',
    values: values,
  );
}

String renderLocalNotificationBody(
  String? eventType, {
  required Map<String, Object?> values,
  String? fallbackBody,
}) {
  final copy = notificationCopyForType(eventType);
  final template = copy?.localBody ?? copy?.body ?? fallbackBody;
  return renderNotificationCopy(
    template ?? 'Ada pembaruan terbaru.',
    values: values,
  );
}
