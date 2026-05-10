# Setup Guide: Backend PHP MySQL + Flutter Frontend

## 📋 Daftar Isi
1. [Persiapan Backend](#persiapan-backend)
2. [Konfigurasi Database](#konfigurasi-database)
3. [Setup Flutter Frontend](#setup-flutter-frontend)
4. [Testing](#testing)
5. [Troubleshooting](#troubleshooting)

---

## 🔧 Persiapan Backend

### Kebutuhan Sistem
- PHP 7.4+ (direkomendasikan PHP 8.0+)
- MySQL 5.7+ atau MariaDB
- Server Web (Apache, Nginx, atau built-in PHP server)

### Step 1: Setup Folder Backend
Backend sudah dibuat di folder: `backend/`

Struktur folder:
```
backend/
├── config/
│   └── Database.php           # Database connection class
├── api/
│   ├── login.php              # Login endpoint
│   ├── register.php           # Register endpoint
│   └── verify_token.php       # Token verification endpoint
├── includes/
│   └── functions.php          # Helper functions dan JWT
├── database.sql               # Database schema
└── README.md                  # Documentation
```

---

## 🗄️ Konfigurasi Database

### Step 1: Buka MySQL
Buka command prompt/terminal dan akses MySQL:
```bash
mysql -u root -p
```

Jika tidak ada password, cukup tekan Enter.

### Step 2: Import Database Schema
Pilih salah satu cara:

#### Cara 1: Via Command Line
```bash
mysql -u root -p si_manajemen_kampus < backend/database.sql
```

#### Cara 2: Via MySQL Workbench
1. Buka MySQL Workbench
2. Buka connection ke MySQL server
3. Klik `File` → `Open SQL Script`
4. Pilih file `backend/database.sql`
5. Klik Execute (atau tekan Ctrl+Shift+Enter)

#### Cara 3: Via phpMyAdmin
1. Buka phpMyAdmin (biasanya di `http://localhost/phpmyadmin`)
2. Klik Import
3. Pilih file `backend/database.sql`
4. Klik Go

### Step 2: Verifikasi Database
Jalankan perintah:
```sql
USE si_manajemen_kampus;
SHOW TABLES;
SELECT * FROM users;
```

Anda akan melihat 2 user demo:
- Email: `admin@example.com` (Role: admin)
- Email: `user@example.com` (Role: user)

Password: `password123`

---

## 🚀 Setup Flutter Frontend

### Step 1: Install Dependencies
Di root folder Flutter project, jalankan:
```bash
flutter pub get
```

Ini akan menginstall packages:
- `http` - untuk HTTP requests
- `shared_preferences` - untuk menyimpan token

### Step 2: Konfigurasi API URL
Edit file: `lib/services/api_service.dart`

Ubah line 5:
```dart
static const String baseUrl = 'http://localhost/si_manajemen_kampus_backend/api';
```

**Ganti dengan URL backend Anda:**

#### Jika menggunakan Apache/Nginx:
```dart
static const String baseUrl = 'http://your-domain.com/backend/api';
```

#### Jika menggunakan IP Address:
```dart
static const String baseUrl = 'http://192.168.1.100/backend/api';
```

#### Untuk Android Emulator (dari localhost):
```dart
static const String baseUrl = 'http://10.0.2.2/backend/api';
```

#### Untuk Mobile Testing dengan IP:
```dart
// Dapatkan IP lokal komputer (ipconfig di Windows)
static const String baseUrl = 'http://192.168.x.x/backend/api';
```

### Step 3: Update Security Key
Edit file: `backend/includes/functions.php`

Ubah secret key (line ~43 dan ~97):
```php
$secret = 'your_secret_key_here_change_this_in_production';
```

Ganti dengan string random yang kompleks, misalnya:
```php
$secret = 'Kl5x9@mP2#vQ8nR$3tU1%w0yZaB4cD6eF!gH7iJjKlMnOpQ';
```

**PENTING:** Gunakan secret key yang sama di kedua tempat!

---

## 🧪 Testing

### Via Postman (Recommended)

#### 1. Login Test
**POST** `http://localhost/backend/api/login.php`

Headers:
```
Content-Type: application/json
```

Body (raw JSON):
```json
{
    "email": "admin@example.com",
    "password": "password123"
}
```

Expected Response (200 OK):
```json
{
    "success": true,
    "message": "Login berhasil",
    "data": {
        "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
        "user": {
            "id": 1,
            "name": "Admin User",
            "email": "admin@example.com",
            "role": "admin"
        }
    }
}
```

#### 2. Register Test
**POST** `http://localhost/backend/api/register.php`

Headers:
```
Content-Type: application/json
```

Body:
```json
{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "password_confirm": "password123",
    "role": "user"
}
```

#### 3. Verify Token Test
**POST** `http://localhost/backend/api/verify_token.php`

Headers:
```
Content-Type: application/json
Authorization: Bearer <paste-token-dari-login-response>
```

### Via Flutter App

1. Run Flutter app:
```bash
flutter run
```

2. Di login screen:
   - Masukkan email: `admin@example.com`
   - Masukkan password: `password123`
   - Klik "Login"

3. Atau gunakan tombol "Demo" di bawah untuk login cepat

---

## 🔐 Security Notes

### Production Checklist

- [ ] Gunakan HTTPS (SSL/TLS certificate)
- [ ] Ganti secret key dengan yang lebih aman
- [ ] Disable debug mode di Flutter
- [ ] Update CORS policy untuk domain production saja
- [ ] Gunakan environment variables untuk sensitive data
- [ ] Setup rate limiting untuk API endpoints
- [ ] Enable firewall dan security rules

### Mengubah Database Credentials

Edit `backend/config/Database.php`:
```php
private $host = 'localhost';
private $db_name = 'si_manajemen_kampus';
private $username = 'root';        // Ganti dengan username Anda
private $password = '';             // Ganti dengan password Anda
private $port = 3306;
```

### JWT Secret Key

Ganti di `backend/includes/functions.php` (2 tempat):
```php
$secret = 'YOUR_SECURE_SECRET_KEY_HERE';
```

---

## 🐛 Troubleshooting

### Error: "Connection Error"
**Penyebab:** Database connection gagal

**Solusi:**
1. Pastikan MySQL service berjalan
2. Cek konfigurasi di `backend/config/Database.php`
3. Pastikan database sudah dibuat: `CREATE DATABASE si_manajemen_kampus;`

### Error: "Email atau password salah"
**Penyebab:** User tidak ditemukan atau password salah

**Solusi:**
1. Verifikasi user ada di database:
   ```sql
   SELECT * FROM users WHERE email = 'admin@example.com';
   ```
2. Cek apakah user status adalah 'active'
3. Coba register user baru via API

### Error: "Token tidak valid"
**Penyebab:** Token format salah atau secret key tidak match

**Solusi:**
1. Pastikan header Authorization format: `Bearer <token>`
2. Pastikan secret key di `functions.php` sama di semua tempat
3. Pastikan token belum expired (7 hari)

### Flutter: "Koneksi error"
**Penyebab:** URL backend tidak benar atau server tidak berjalan

**Solusi:**
1. Cek URL di `lib/services/api_service.dart`
2. Pastikan backend berjalan:
   ```bash
   # Jika menggunakan PHP built-in server
   php -S localhost:8000
   ```
3. Test API via Postman terlebih dahulu
4. Untuk Android Emulator, gunakan `10.0.2.2` bukan `localhost`

### CORS Error
**Penyebab:** Browser/app tidak bisa akses backend dari origin berbeda

**Solusi:**
CORS sudah di-set di `backend/includes/functions.php`:
```php
header('Access-Control-Allow-Origin: *');
```

Untuk production, ganti dengan domain spesifik:
```php
header('Access-Control-Allow-Origin: https://yourdomain.com');
```

### Password Hash Error
**Penyebab:** Database user hash tidak valid

**Solusi:**
Generate hash baru dengan bcrypt:
```php
<?php
$password = 'password123';
$hash = password_hash($password, PASSWORD_BCRYPT);
echo $hash;
?>
```

Atau gunakan online: https://www.bcrypt-generator.com/

---

## 📱 API Response Format

Semua response dalam format JSON:

### Success Response
```json
{
    "success": true,
    "message": "Operasi berhasil",
    "data": {
        // Data response
    }
}
```

### Error Response
```json
{
    "success": false,
    "message": "Pesan error"
}
```

### Status Codes
- `200` - OK
- `201` - Created (Registrasi berhasil)
- `400` - Bad Request (Validasi gagal)
- `401` - Unauthorized (Auth gagal)
- `405` - Method Not Allowed
- `500` - Server Error

---

## 📚 Referensi

### Files yang Sudah Dibuat:

**Backend:**
- `backend/config/Database.php` - Database connection
- `backend/includes/functions.php` - Helper functions & JWT
- `backend/api/login.php` - Login endpoint
- `backend/api/register.php` - Register endpoint
- `backend/api/verify_token.php` - Token verification
- `backend/database.sql` - Database schema

**Flutter:**
- `lib/services/api_service.dart` - API client
- `lib/services/auth_service.dart` - Local storage untuk auth
- `lib/models/user_model.dart` - User model (updated)
- `lib/screens/login/login_screen.dart` - Login UI (updated)

---

## 💡 Tips & Tricks

### Debugging
Untuk debugging API, tambahkan ini di Flutter:
```dart
print('Request: $email');
print('Response: $result');
```

### Token Management
Token disimpan di local storage:
```dart
// Get token
String? token = await AuthService.getToken();

// Save token
await AuthService.saveToken(token);

// Clear token (logout)
await AuthService.clearToken();
```

### API Error Handling
Semua error di-handle di `api_service.dart`:
```dart
try {
    // API call
} catch (e) {
    print('Error: $e');
}
```

---

## 🎯 Next Steps

1. ✅ Setup backend (sudah dibuat)
2. ✅ Setup Flutter frontend (sudah dibuat)
3. ⏭️ Test login/register
4. ⏭️ Integrate dengan dashboard
5. ⏭️ Setup authentication guard
6. ⏭️ Add more API endpoints (profile, logout, etc)

---

**Pertanyaan atau Issue?**
Cek file `backend/README.md` untuk informasi lebih lanjut.
