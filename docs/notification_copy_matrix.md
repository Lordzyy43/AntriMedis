# Notification Copy Matrix - AntriMedis

Status: draft final untuk production copy.

Prinsip:

- `inbox` adalah teks yang tersimpan di tabel `notifications`.
- `push` adalah teks yang dikirim FCM saat app background/terminated.
- `local` adalah teks fallback saat app foreground atau saat push belum tersedia.
- Untuk production, isi pesan harus konsisten secara makna di semua jalur.
- Local notification boleh lebih instruktif, tetapi tidak boleh mengubah arti pesan inbox/push.

## Matrix

| Event | Title | Body | Versi Inbox | Versi Push | Versi Local | Aturan Kapan Dipakai |
| --- | --- | --- | --- | --- | --- | --- |
| `queue_created` | Nomor antrean berhasil dibuat | Nomor antrean Anda adalah `{queue_code}`. | Sama seperti body utama. | Sama seperti inbox, ringkas dan pasti. | Sama seperti push. | Dipakai saat pasien berhasil mengambil nomor. |
| `queue_near` | Giliran Anda semakin dekat | Nomor `{queue_code}` tinggal `{remaining}` antrean lagi. Mohon bersiap. | Tidak dibuat saat ini. | Tidak dikirim saat ini. | Dipakai sebagai local-only signal. | Dipakai saat sisa antrean di depan tinggal 1-2 nomor agar tidak spam. |
| `queue_called` | Nomor Anda dipanggil | Nomor `{queue_code}` sedang dipanggil. Segera menuju poli. | Sama seperti body utama. | Sama seperti inbox. | Sama seperti inbox, paling tegas karena butuh aksi langsung. | Dipakai saat petugas memanggil nomor aktif. |
| `queue_missed` | Nomor Anda terlewat | Nomor `{queue_code}` terlewat. Tunggu panggilan ulang setelah antrean reguler selesai. | Sama seperti body utama. | Sama seperti inbox. | Sama seperti inbox, jangan menyalahkan user. | Dipakai saat status berubah jadi missed. |
| `queue_skipped` | Antrean dilewati | Nomor `{queue_code}` dilewati oleh petugas. | Sama seperti body utama. | Sama seperti inbox. | Sama seperti inbox. | Dipakai saat nomor di-skip final oleh petugas. |
| `queue_cancelled` | Antrean dibatalkan | Nomor `{queue_code}` dibatalkan. | Sama seperti body utama. | Sama seperti inbox. | Sama seperti inbox. | Dipakai saat tiket dibatalkan oleh pasien atau petugas. |
| `queue_expired` | Antrean kedaluwarsa | Nomor `{queue_code}` kedaluwarsa karena sesi layanan telah ditutup. | Sama seperti body utama. | Sama seperti inbox. | Sama seperti inbox. | Dipakai saat sesi ditutup dan waiting berubah expired. |
| `schedule_changed` | Jadwal layanan berubah | Jadwal layanan Anda berubah. Cek detail jadwal terbaru di aplikasi. | Sama seperti body utama. | Sama seperti inbox. | Sama seperti inbox. | Dipakai hanya jika perubahan jadwal memang signifikan untuk pasien. |

## Rincian Aturan

1. `queue_created` hanya dipakai ketika tiket baru berhasil dibuat dan nomor sudah pasti.
2. `queue_near` dipakai local-only dengan guard agar tidak spam, saat sisa antrean tinggal 1-2 nomor.
3. `queue_called` harus terasa tegas dan operasional, karena pasien perlu bergerak.
4. `queue_missed`, `queue_skipped`, `queue_cancelled`, dan `queue_expired` harus netral dan tidak menghakimi.
5. `schedule_changed` jangan dipakai untuk perubahan kecil yang tidak mengganggu pasien.
6. Jika push gagal, inbox tetap menjadi source of truth.
7. Jika app foreground, local notification boleh dipakai sebagai fallback tetapi tidak boleh mengulang event yang sama dua kali.

## Copy Style Guide

- Pakai bahasa Indonesia yang singkat dan stabil.
- Hindari kata-kata yang terlalu emosional.
- Jangan menambah instruksi panjang di body notifikasi.
- Nomor antrean selalu disebut dengan placeholder `{queue_code}`.
- Untuk `queue_near`, placeholder `{remaining}` harus berupa angka yang sederhana.

## Implementation Target

Urutan implementasi berikutnya:

1. Jadikan tabel ini sebagai sumber copy utama di app.
2. Ubah local notification agar membaca copy yang sama.
3. Ubah push payload supaya title/body yang dipakai tetap sinkron. Selesai.
4. Rapikan pesan inbox database agar sama makna dengan push/local. Selesai.
5. Jalankan QA copy di foreground, background, dan terminated.
