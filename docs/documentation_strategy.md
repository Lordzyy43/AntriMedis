# Documentation Strategy - AntriMedis

Dokumen ini menjelaskan cara menjaga dokumentasi AntriMedis agar tetap rapi saat project berubah. Tujuannya supaya PRD, roadmap, dan catatan teknis tidak bercampur menjadi satu dokumen besar yang sulit dilacak.

---

## 1. Prinsip Utama

Dokumentasi production biasanya dibagi menjadi beberapa jenis dokumen, bukan semua ditaruh di satu file.

Pola yang dipakai untuk AntriMedis:

| Jenis dokumen | Fungsi | Cara update |
| --- | --- | --- |
| PRD | Source of truth kebutuhan produk | Diupdate saat scope, requirement, atau keputusan produk berubah |
| Status/Roadmap | Tracking kondisi implementasi | Diupdate setiap selesai phase besar/hardening penting |
| Technical docs | Detail setup, database, env, deployment | Diupdate saat cara menjalankan/struktur teknis berubah |
| Changelog | Riwayat perubahan versi | Diupdate saat release/tag/versi demo |
| ADR | Catatan keputusan arsitektur penting | Dibuat baru saat ada keputusan teknis besar |

---

## 2. Kapan Update Dokumen Existing?

Update dokumen existing kalau perubahan tersebut mengganti atau memperjelas informasi yang sudah menjadi source of truth.

Contoh:

- Scope MVP berubah dari global klinik menjadi satu klinik.
- Role MVP dipersempit menjadi pasien dan admin.
- Backend diputuskan memakai Supabase.
- Requirement antrean berubah dari bebas ambil banyak nomor menjadi satu antrean aktif per hari.
- PRD menyebut estimasi harus realtime, lalu sekarang diperjelas sebagai estimasi perkiraan, bukan presisi mutlak.

Untuk kasus seperti ini, update `docs/prd.md` atau `docs/prd_status_roadmap.md`.

---

## 3. Kapan Buat Dokumen Baru?

Buat dokumen baru kalau kontennya punya tujuan berbeda dari dokumen existing, atau terlalu detail jika dimasukkan ke PRD.

Contoh dokumen baru yang masuk akal:

- `docs/qa_checklist.md` untuk skenario test manual.
- `docs/release_checklist.md` untuk langkah build/upload.
- `docs/database_hardening.md` untuk penjelasan RPC, RLS, dan state machine.
- `docs/adr/0001-use-supabase.md` untuk keputusan memakai Supabase.
- `docs/adr/0002-single-clinic-mvp.md` untuk keputusan fokus satu klinik.

Dokumen baru lebih baik daripada membuat PRD terlalu panjang dan sulit dibaca.

---

## 4. Dokumen yang Ideal Dipakai di Production

Di project production, biasanya minimal ada:

1. **PRD / Product Spec**
   - Menjelaskan masalah, target user, scope, requirement, non-goal, dan success criteria.

2. **Technical Design / Engineering Design**
   - Menjelaskan arsitektur, data model, API/RPC, security, dan trade-off.

3. **ADR**
   - Mencatat keputusan penting dan alasan di baliknya.
   - Formatnya singkat: context, decision, consequences.

4. **Runbook**
   - Cara menjalankan, deploy, rollback, debug, dan cek logs.

5. **QA Checklist**
   - Skenario manual dan automated test yang wajib lolos.

6. **Changelog / Release Notes**
   - Ringkasan perubahan per versi.

Untuk AntriMedis saat ini, yang paling penting adalah:

- `docs/prd.md`
- `docs/prd_status_roadmap.md`
- `docs/documentation_strategy.md`
- nanti tambahkan `docs/qa_checklist.md`
- nanti tambahkan `docs/release_checklist.md`

---

## 5. Rekomendasi Struktur Docs AntriMedis

```txt
docs/
  prd.md
  prd_status_roadmap.md
  documentation_strategy.md
  qa_checklist.md
  release_checklist.md
  user_side_db_fields.md
  adr/
    0001-use-supabase.md
    0002-single-clinic-mvp.md
```

Tidak semua harus dibuat sekarang. Buat ketika mulai dibutuhkan agar dokumentasi tetap bernilai, bukan sekadar banyak file.

---

## 6. Aturan Update Dokumentasi Saat Develop

Gunakan aturan sederhana ini:

1. Kalau mengubah behavior produk, update PRD atau status roadmap.
2. Kalau mengubah flow QA, update QA checklist.
3. Kalau mengubah setup/env/deploy, update README atau release checklist.
4. Kalau mengambil keputusan arsitektur besar, buat ADR.
5. Kalau hanya refactor kecil tanpa perubahan behavior, tidak wajib update docs.

Contoh penerapan:

| Perubahan | Dokumen yang diupdate |
| --- | --- |
| Tambah RPC `cancel_my_ticket` | `prd_status_roadmap.md`, optional `database_hardening.md` |
| Ganti package name Android | `release_checklist.md`, README |
| Tambah FCM | PRD, technical docs, release checklist |
| Tambah global clinic picker | PRD dan roadmap |
| Tambah test E2E | `qa_checklist.md` |

---

## 7. Cara Menjaga Dokumen Tetap Ter-track

Praktik yang rapi:

- Update docs di commit/PR yang sama dengan perubahan fitur jika behavior berubah.
- Tulis tanggal update di dokumen status/roadmap.
- Jangan hapus keputusan lama tanpa alasan; ubah menjadi "deprecated" atau pindahkan ke future scope jika masih relevan.
- Gunakan checklist agar bisa terlihat mana yang selesai dan mana yang pending.
- Hindari PRD menjadi log harian. PRD adalah requirement, bukan diary progress.

---

## 8. Kesimpulan

Untuk AntriMedis:

- `docs/prd.md` tetap menjadi dokumen produk utama.
- `docs/prd_status_roadmap.md` menjadi dokumen kondisi project dan next step.
- Dokumen baru dibuat hanya jika punya fungsi berbeda, seperti QA checklist atau release checklist.

Pola ini paling mendekati praktik production karena memisahkan requirement, implementation status, technical decision, dan release process.
