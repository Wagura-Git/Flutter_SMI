# Panduan Publish Sementara dengan Ngrok

Panduan ini cocok untuk proyek ini karena frontend Flutter Web dan backend PHP sama-sama ada di dalam folder XAMPP.

## Kenapa pakai satu tunnel

Cara paling sederhana adalah:

1. Jalankan Apache dan MySQL di XAMPP.
2. Build Flutter Web ke folder `build/web`.
3. Buka `ngrok` ke port `80` saja.

Dengan cara ini:

- frontend dan backend memakai domain `ngrok` yang sama
- Anda tidak perlu membuat 2 tunnel
- CORS lebih mudah ditangani

## Jangan kirim authtoken di chat

Authtoken `ngrok` adalah secret. Lebih aman jalankan sendiri di terminal lokal Anda:

```powershell
ngrok config add-authtoken TOKEN_ANDA
```

Kalau `ngrok` belum dikenali, berarti aplikasinya belum ada di `PATH`. Anda bisa jalankan dari folder instalasi `ngrok.exe`, atau tambahkan foldernya ke `PATH` Windows.

## Langkah 1: Pastikan backend lokal jalan

Tes URL lokal ini di browser:

```text
http://localhost/1_Project_Thesis/SI-manajemen-kampus/backend/api/login.php
```

Jika endpoint merespons, berarti Apache sudah membaca folder proyek dengan benar.

## Langkah 2: Jalankan tunnel ngrok ke Apache

```powershell
ngrok http 80
```

Contoh public URL yang nanti muncul:

```text
https://abc123.ngrok-free.app
```

Simpan URL itu. Anda akan memakainya saat build Flutter Web.

## Langkah 3: Build Flutter Web dengan URL API ngrok

Dari folder root proyek ini, jalankan:

```powershell
powershell -ExecutionPolicy Bypass -File .\si_manajemen_kampus\tools\build_web_for_ngrok.ps1 -PublicBaseUrl https://abc123.ngrok-free.app
```

Script ini akan:

- build Flutter Web mode release
- mengisi `API_BASE_URL` ke backend `ngrok`
- mengatur `base-href` agar web bisa dibuka dari subfolder XAMPP ini

## Langkah 4: Buka website publik

Setelah build selesai, buka URL ini:

```text
https://abc123.ngrok-free.app/1_Project_Thesis/SI-manajemen-kampus/si_manajemen_kampus/build/web/
```

## Catatan penting

- URL `ngrok` gratis biasanya berubah setiap kali tunnel dibuat ulang.
- Jika URL berubah, build ulang Flutter Web dengan script yang sama dan ganti `-PublicBaseUrl`.
- Database tetap berjalan di komputer Anda sendiri. Jadi komputer dan XAMPP harus tetap aktif selama website ingin diakses dari internet.
- Ini cocok untuk demo, testing, atau bimbingan. Ini belum setara hosting production.

## Checklist cepat

- XAMPP Apache aktif
- XAMPP MySQL aktif
- Database `si_manajemen_kampus` tersedia
- `ngrok` sudah login dengan authtoken
- `ngrok http 80` sudah jalan
- Flutter Web sudah dibuild dengan URL `ngrok` terbaru
