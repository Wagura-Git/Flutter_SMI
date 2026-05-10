# Backend SI Manajemen Kampus - PHP MySQL

## Setup Instructions

### 1. Database Setup
- Import `database.sql` ke MySQL database Anda
- Atau jalankan perintah SQL secara manual

### 2. Konfigurasi Database
Edit file `config/Database.php` dan sesuaikan:
```php
private $host = 'localhost';        // Host MySQL
private $db_name = 'si_manajemen_kampus'; // Nama database
private $username = 'root';          // Username MySQL
private $password = '';              // Password MySQL
private $port = 3306;                // Port MySQL
```

### 3. Security Key
Edit file `includes/functions.php` dan ganti secret key:
```php
$secret = 'your_secret_key_here_change_this_in_production';
```
Gunakan string yang kompleks dan aman di production.

## API Endpoints

### 1. Login
**POST** `/api/login.php`

**Request:**
```json
{
    "email": "admin@example.com",
    "password": "password123"
}
```

**Response (Success):**
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

**Response (Error):**
```json
{
    "success": false,
    "message": "Email atau password salah"
}
```

### 2. Register
**POST** `/api/register.php`

**Request:**
```json
{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "password_confirm": "password123",
    "role": "user"
}
```

**Response (Success):**
```json
{
    "success": true,
    "message": "Registrasi berhasil",
    "data": {
        "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
        "user": {
            "id": 3,
            "name": "John Doe",
            "email": "john@example.com",
            "role": "user"
        }
    }
}
```

### 3. Verify Token
**POST** `/api/verify_token.php`

**Headers:**
```
Authorization: Bearer <token>
```

**Response (Valid):**
```json
{
    "success": true,
    "message": "Token valid",
    "data": {
        "userId": 1,
        "email": "admin@example.com",
        "role": "admin",
        "exp": 1234567890
    }
}
```

**Response (Invalid):**
```json
{
    "success": false,
    "message": "Token tidak valid atau sudah kadaluarsa"
}
```

## Default Test Accounts

Email: `admin@example.com`
Password: `password123`
Role: `admin`

Email: `user@example.com`
Password: `password123`
Role: `user`

## File Structure

```
backend/
├── config/
│   └── Database.php           # Database connection class
├── api/
│   ├── login.php              # Login endpoint
│   ├── register.php           # Register endpoint
│   └── verify_token.php       # Token verification endpoint
├── includes/
│   └── functions.php          # Helper functions and JWT implementation
├── database.sql               # Database schema
└── README.md                  # This file
```

## Security Notes

1. **HTTPS Only**: Selalu gunakan HTTPS di production
2. **Secret Key**: Ganti secret key dengan yang lebih aman
3. **CORS**: Sesuaikan CORS policy untuk production
4. **Input Validation**: Semua input sudah divalidasi
5. **Password Hashing**: Menggunakan bcrypt (PHP 5.5+)
6. **Token Expiry**: Token berlaku 7 hari

## Troubleshooting

### Database connection error
- Pastikan MySQL service berjalan
- Cek konfigurasi di `config/Database.php`
- Pastikan database sudah dibuat

### CORS Error
- Pastikan header CORS sudah di-set di `includes/functions.php`
- Cek browser console untuk detail error

### Token Invalid
- Token mungkin sudah expired (7 hari)
- Pastikan format Authorization header benar: `Bearer <token>`
- Cek secret key di `includes/functions.php`
