# Launcher dan Notification Icon Preparation - AntriMedis

Status: persiapan sebelum implementasi.

Dokumen ini menjelaskan apa saja yang perlu disiapkan sebelum mengganti launcher icon aplikasi dan icon notifikasi Android. Tujuannya supaya perubahan nanti tidak setengah jadi, tidak bentrok dengan FCM, dan tidak membuat icon tampil default lagi di device user.

## Ringkasan Singkat

- `launcher icon` adalah icon aplikasi yang terlihat di home screen, app drawer, dan recent apps.
- `notification small icon` adalah icon kecil yang muncul di status bar dan di push notification Android.
- Keduanya berbeda kebutuhan desainnya.
- Satu icon full-color yang bagus untuk launcher belum tentu cocok untuk notification.

## Kondisi Saat Ini

- Android app masih memakai `@mipmap/ic_launcher` sebagai launcher icon.
- Local notification di Flutter masih memakai `@mipmap/ic_launcher`.
- FCM Android belum menetapkan `default_notification_icon`, jadi kalau belum diubah akan fallback ke icon default/launcher.
- Aset gambar yang sudah ada di repo berada di `assets/images`.

## Aset Yang Sudah Ada

| File | Ukuran | Kegunaan yang paling cocok |
| --- | --- | --- |
| `assets/images/antrimedis_logo.png` | `512x512` | Cocok sebagai sumber launcher icon utama. |
| `assets/images/AntriMedis_tr.png` | `1024x1024` | Cocok untuk branding, splash, atau referensi visual. |

## Yang Perlu Disiapkan

### 1. Launcher Icon Source

Siapkan 1 gambar master untuk launcher icon dengan syarat berikut:

- Format PNG.
- Bentuk persegi.
- Resolusi minimal disarankan `1024x1024`.
- Latar boleh transparan atau solid, tetapi harus terlihat rapi ketika dipotong ke berbagai ukuran.
- Elemen utama harus berada di tengah dan punya ruang aman di tepi.

Rekomendasi untuk AntriMedis:

- Gunakan `assets/images/antrimedis_logo.png` sebagai sumber utama.
- Jangan pakai `AntriMedis_tr.png` sebagai launcher langsung kalau terlalu ramai detailnya.

### 2. Notification Small Icon

Siapkan icon khusus notification dengan syarat berikut:

- Format PNG atau vector yang nanti diekspor ke resource Android.
- Monochrome, idealnya putih solid.
- Background transparan.
- Tidak ada teks kecil.
- Tidak ada gradasi rumit.
- Siluet harus jelas saat diperkecil.

Rekomendasi untuk AntriMedis:

- Buat icon khusus yang sederhana, misalnya bentuk rumah/antrean/kesehatan versi putih.
- Jangan pakai full-color logo sebagai small icon, karena Android sering menampilkan hasil yang tidak konsisten.

### 3. Varian Android Adaptive Icon

Kalau launcher icon mau dibuat production-grade, siapkan komponen ini:

- Foreground layer.
- Background layer.
- Safe area agar elemen tidak terpotong.

Ini penting kalau nanti kita generate adaptive icon melalui tool seperti `flutter_launcher_icons`.

### 4. Ikon Alternatif Untuk iOS

Jika nanti iOS juga ingin dirapikan:

- Siapkan source yang konsisten dengan branding Android.
- Jangan terlalu detail di icon kecil.
- Tetap prioritaskan bentuk yang mudah dikenali.

## File Yang Nanti Biasanya Diubah

Berikut file yang umumnya disentuh saat implementasi:

- `pubspec.yaml` jika memakai tool generator icon.
- `android/app/src/main/AndroidManifest.xml` untuk default notification icon.
- `android/app/src/main/res/mipmap-*` untuk launcher icon.
- `android/app/src/main/res/drawable-*` atau `drawable-anydpi-v24` untuk notification small icon.
- `lib/core/services/notification_service.dart` kalau local notification ingin pakai icon selain launcher.
- `android/app/src/main/AndroidManifest.xml` jika perlu metadata FCM icon default.

## Rekomendasi Implementasi

### Launcher Icon

1. Ambil `assets/images/antrimedis_logo.png` sebagai sumber utama.
2. Generate launcher icon Android dan iOS dari asset yang sama.
3. Pastikan semua ukuran mipmap terisi.
4. Verifikasi icon tampil konsisten di home screen dan app drawer.

### Notification Icon

1. Buat asset khusus notification icon versi putih/monochrome.
2. Export ke resource Android.
3. Set icon itu sebagai default notification icon FCM.
4. Set icon yang sama untuk local notification Android supaya tampil seragam.

## Kenapa Tidak Cukup Pakai Launcher Icon Saja

- Launcher icon full-color biasanya terlalu detail untuk status bar.
- Android notification kecil sering menampilkan icon sebagai silhouette putih.
- Jika desain terlalu ramai, icon bisa terlihat buram, kotak, atau tidak terbaca.
- Karena itu launcher dan notification icon sebaiknya dipisah.

## Checklist Persiapan

- [ ] Putuskan asset source untuk launcher icon.
- [ ] Putuskan icon khusus untuk notification small icon.
- [ ] Pastikan ukuran asset master cukup besar.
- [ ] Pastikan tidak ada teks kecil di icon notification.
- [ ] Pastikan background notification icon transparan atau aman untuk mask Android.
- [ ] Pastikan file sumber disimpan di folder aset yang jelas.
- [ ] Pastikan tim paham bahwa launcher icon dan notification icon adalah dua resource berbeda.

## QA Setelah Implementasi

- Cek icon aplikasi di home screen Android.
- Cek icon di app drawer.
- Cek icon muncul di status bar saat push masuk.
- Cek notifikasi saat app foreground, background, dan terminated.
- Cek tampilan di layar kecil Android.
- Cek apakah icon tetap jelas di dark status bar dan light status bar.

## Catatan Praktis

- Jika prioritas cepat, gunakan `antrimedis_logo.png` untuk launcher dulu.
- Untuk notification small icon, lebih aman buat asset baru daripada memaksa logo full-color yang sudah ada.
- Jika nanti ada redesign branding, notification icon perlu ikut disederhanakan lagi.

