# FCM Setup - AntriMedis

Status implementasi:

- Firebase project: `antrimedis-4c0a5`
- Firebase project number: `22480247523`
- Android package name: `com.antrimedis.app`
- iOS bundle id: `com.antrimedis.app`
- Android config: `android/app/google-services.json`
- Flutter config: `lib/firebase_options.dart`
- Edge Function: `send-push`
- Notification channel Android: `queue_updates`

## 1. Apply Database Migrations

Jalankan migration Supabase seperti biasa:

```bash
supabase db push
```

Migration FCM menambahkan:

- `public.user_device_tokens`
- `public.push_delivery_logs`
- RPC `register_fcm_token`
- RPC `deactivate_fcm_token`
- trigger `notifications_dispatch_push`

## 2. Siapkan Firebase Service Account

Di Firebase Console:

1. Buka project `AntriMedis`.
2. Project settings -> Service accounts.
3. Generate private key.
4. Simpan file JSON hanya di mesin lokal/operator, jangan commit ke repo.

Set secret untuk Edge Function:

```powershell
supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON="$(Get-Content .\firebase-service-account.json -Raw)"
```

Jika file belum ada, command di atas akan gagal membaca file. Jangan lanjut sebelum file JSON benar-benar tersedia.

## 3. Siapkan Webhook Secret

Buat string random panjang, lalu set ke Edge Function:

```powershell
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$bytes = New-Object byte[] 48
$rng.GetBytes($bytes)
$pushSecret = [Convert]::ToBase64String($bytes)
supabase secrets set PUSH_WEBHOOK_SECRET="$pushSecret"
Set-Content -Path .\.push-webhook-secret.local -Value $pushSecret -NoNewline
```

Set secret yang sama ke database setting agar trigger `notifications` bisa memanggil Edge Function.

Penting: SQL di bawah dijalankan di Supabase Dashboard -> SQL Editor, bukan di PowerShell terminal.

```sql
alter database postgres set app.fcm_push_function_url = 'https://vicwdxxjaoekppembbvt.supabase.co/functions/v1/send-push';
alter database postgres set app.fcm_push_webhook_secret = '<random-secret-panjang>';
```

Ganti `<random-secret-panjang>` dengan isi file `.push-webhook-secret.local`.

Setelah mengubah database setting, refresh koneksi Postgres. Cara paling aman adalah restart project dari Supabase dashboard atau tunggu koneksi baru dipakai.

## 4. Deploy Edge Function

```bash
supabase functions deploy send-push
```

Function ini memakai `verify_jwt = false`, tetapi akses tetap dijaga di kode dengan:

- header `x-push-webhook-secret`, atau
- JWT service role, atau
- user staff yang lolos RPC `is_staff()`.

## 5. Verifikasi Manual

1. Install app Android fresh.
2. Login sebagai pasien.
3. Allow notification permission.
4. Pastikan row aktif muncul di `public.user_device_tokens`.
5. Ambil nomor antrean.
6. Pastikan row `queue_created` muncul di `public.notifications`.
7. Pastikan `public.push_delivery_logs` mencatat `sent` untuk token device.
8. Background/terminate app.
9. Panggil antrean dari admin.
10. Pastikan push FCM muncul dan inbox Supabase tetap lengkap.

## 6. Catatan iOS

Kode Flutter dan Firebase app iOS sudah disiapkan, tetapi push iOS masih membutuhkan setup Apple:

- APNs key/certificate di Firebase Console.
- Push Notifications capability di Xcode.
- Background Modes -> Remote notifications jika nanti dibutuhkan.
- Uji di device fisik iOS.
