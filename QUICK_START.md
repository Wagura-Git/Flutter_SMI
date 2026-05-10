## 🚀 Quick Start Backend PHP MySQL

### ⚡ Langkah Cepat (5 Menit)

#### 1. Import Database
```bash
# Buka MySQL console
mysql -u root -p

# Jalankan SQL
source backend/database.sql
```

#### 2. Update URL Backend di Flutter
Edit: `lib/services/api_service.dart` line 5
```dart
static const String baseUrl = 'http://localhost/backend/api';
```

#### 3. Install Dependencies Flutter
```bash
flutter pub get
```

#### 4. Run Flutter App
```bash
flutter run
```

#### 5. Test Login
- Email: `admin@example.com`
- Password: `password123`

---

### 📁 File-File yang Dibuat

**Backend (PHP):**
```
backend/
├── api/
│   ├── login.php          ← Login endpoint
│   ├── register.php       ← Register endpoint
│   └── verify_token.php   ← Verify JWT token
├── config/
│   └── Database.php       ← Database connection
├── includes/
│   └── functions.php      ← JWT & helper functions
└── database.sql           ← Database schema
```

**Frontend (Flutter):**
```
lib/
├── services/
│   ├── api_service.dart       ← HTTP API client
│   └── auth_service.dart      ← Token management
├── models/
│   └── user_model.dart        ← Updated user model
└── screens/
    └── login/
        └── login_screen.dart  ← Updated login UI
```

---

### 🔑 Test Accounts

| Email | Password | Role |
|-------|----------|------|
| admin@example.com | password123 | admin |
| user@example.com | password123 | user |

---

### ⚙️ Konfigurasi Penting

1. **Database Config** → `backend/config/Database.php`
   - Host: localhost
   - User: root
   - Password: (kosong atau sesuai setup Anda)
   - Database: si_manajemen_kampus

2. **API Base URL** → `lib/services/api_service.dart`
   - Ubah sesuai URL backend Anda

3. **JWT Secret** → `backend/includes/functions.php`
   - Ganti dengan secret yang aman di production

---

### 🧪 Testing dengan Postman

**POST Login:**
```
URL: http://localhost/backend/api/login.php
Body: 
{
    "email": "admin@example.com",
    "password": "password123"
}
```

---

### 🐛 Common Issues

| Error | Solusi |
|-------|--------|
| Connection Error | Pastikan MySQL berjalan & URL benar |
| Email atau password salah | Pastikan user ada di database |
| CORS Error | Refresh atau clear browser cache |
| Token tidak valid | Pastikan token belum expired (7 hari) |

---

### 📚 Full Documentation
Baca: `SETUP_GUIDE.md` untuk detail lengkap

---

### 💾 Database Tables

**Users Table:**
```sql
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'user') DEFAULT 'user',
    status ENUM('active', 'inactive') DEFAULT 'active',
    phone VARCHAR(20),
    address TEXT,
    profile_photo VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL
);
```

---

### 🎯 Next Steps

1. ✅ Setup Database
2. ✅ Update URL & Config
3. ✅ Run Flutter app
4. ⏭️ Test login/register
5. ⏭️ Integrate dengan dashboard
6. ⏭️ Add more features

**Ready to go! Start with Step 1 above! 🚀**
