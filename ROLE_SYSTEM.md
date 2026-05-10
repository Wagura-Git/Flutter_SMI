# Sistem 3 Role - SI Manajemen Kampus

## Ringkasan Sistem Role

Aplikasi SI Manajemen Kampus sekarang menggunakan sistem 3 role untuk mengatur akses dan fitur:

### 1. **PIMPINAN** (Role: `pimpinan`)
**Akses & Fitur:**
- ✅ **Membuat Disposisi Surat** - Dapat membuat dan mengelola disposisi surat
- ✅ **Agenda Pribadi** - Hanya dapat membuat agenda pribadi (tidak bisa membuat agenda umum)
- ✅ **Fitur Lainnya** - Akses ke fitur-fitur standar sistem
- 👁️ **Disposisi Surat** - Dapat melihat disposisi surat

**Menu di Sidebar:**
- Beranda
- Notifikasi
- Agenda (pribadi)
- Kelola Surat Saya
- Disposisi Surat (viewer)
- Kepanitiaan
- **Buat Disposisi Surat** ⭐
- Pengaturan Akun

---

### 2. **ADMIN** (Role: `admin`)
**Akses & Fitur:**
- 👁️ **Disposisi Surat** - Hanya dapat melihat (viewer), tidak membuat
- ✅ **Agenda Pribadi & Umum** - Dapat membuat agenda pribadi dan umum untuk dibagikan ke user dan pimpinan
- ✅ **Fitur Lainnya** - Akses ke fitur-fitur standar sistem
- 📊 **Manajemen Pengguna** - Akses pengaturan akun dan manajemen sistem

**Menu di Sidebar:**
- Beranda
- Notifikasi
- Agenda (pribadi & umum)
- Kelola Surat Saya
- Disposisi Surat (viewer)
- Kepanitiaan
- Pengaturan Akun

---

### 3. **USER** (Role: `user`)
**Akses & Fitur:**
- 👁️ **Disposisi Surat** - Hanya dapat melihat (viewer), tidak membuat
- ✅ **Agenda Pribadi** - Hanya dapat membuat agenda pribadi (tidak bisa membuat agenda umum)
- ✅ **Fitur Lainnya** - Akses ke fitur-fitur standar sistem

**Menu di Sidebar:**
- Beranda
- Notifikasi
- Agenda (pribadi)
- Kelola Surat Saya
- Disposisi Surat (viewer)
- Kepanitiaan

---

## Data Demo Login

Gunakan akun demo berikut untuk testing:

| Role | Email | Password |
|------|-------|----------|
| **Pimpinan** | `pimpinan@example.com` | `password123` |
| **Admin** | `admin@example.com` | `password123` |
| **User** | `user@example.com` | `password123` |

---

## Alur Registrasi yang Diperbarui

1. User mengisi form registrasi
2. Setelah klik "Daftar", sistem memvalidasi input
3. **Jika berhasil:**
   - Akun dibuat dengan role default: **USER**
   - Tampil notifikasi sukses: "Registrasi berhasil! Silakan login dengan akun Anda."
   - User **otomatis dikembalikan ke halaman Login** (untuk keamanan)
   - User harus login dengan akun barunya
4. **Jika gagal:**
   - Tampil pesan error dan tetap di form registrasi

> **Catatan Keamanan:** User tidak langsung masuk ke dashboard setelah registrasi untuk menjamin keamanan. User harus melakukan login dengan menggunakan email dan password mereka.

---

## Database Schema

```sql
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('pimpinan', 'admin', 'user') DEFAULT 'user',
    status ENUM('active', 'inactive') DEFAULT 'active',
    phone VARCHAR(20),
    address TEXT,
    profile_photo VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## File yang Dimodifikasi

### Frontend (Flutter/Dart):
1. `lib/models/user_model.dart` - Update UserRole enum
2. `lib/screens/login/login_screen.dart` - Update registration flow & demo buttons
3. `lib/screens/dashboard/dashboard_screen.dart` - Add role display method
4. `lib/screens/dashboard/widgets/sidebar.dart` - Update role-based menu logic

### Backend (PHP):
1. `backend/database.sql` - Update users table role ENUM
2. `backend/api/register.php` - Add documentation comments

---

## Implementasi Fitur Role-Specific di Frontend

### Sidebar Navigation (widgets/sidebar.dart)
```dart
bool isPimpinan = role == 'pimpinan' || role == 'Pimpinan';
bool isAdmin = role == 'admin' || role == 'Admin';
bool isUser = role == 'user' || role == 'User';

// Hanya Pimpinan bisa membuat disposisi surat
if (isPimpinan) _item(Icons.edit, "Buat Disposisi Surat");

// Hanya Admin dan Pimpinan bisa akses pengaturan
if (isAdmin || isPimpinan) _item(Icons.settings, "Pengaturan Akun");
```

---

## Next Steps (Opsional)

1. **Implementasi Agenda Umum untuk Admin** - Buat fitur untuk Admin membuat agenda yang dibagikan
2. **Implementasi Disposisi Surat** - Develop halaman untuk pimpinan membuat disposisi
3. **Role-Based Access Control (RBAC)** - Tambahkan logika backend untuk memvalidasi akses setiap endpoint
4. **Activity Log** - Tracking aksi pimpinan dan admin untuk audit trail
5. **Permission Manager** - Interface untuk admin mengelola role pengguna (upgrade/downgrade)

---

*Last Updated: 2026-04-24*
