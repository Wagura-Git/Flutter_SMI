# Sistem Role-Based Access Control (RBAC) - SI Manajemen Kampus

## Ringkasan

Sistem ini mengimplementasikan kontrol akses berbasis role dengan 3 role utama:
1. **Admin** - Administrator sistem dengan akses penuh
2. **Pimpinan** - Pemimpin/Direktur dengan akses terbatas pada kepemimpinan
3. **User** - Pengguna reguler dengan akses dasar

## Fitur & Izin Berdasarkan Role

### A. User (Pengguna Biasa)

#### 1. Agenda
- ✅ **Melihat Agenda Pribadi**: Melihat agenda yang dibuat oleh diri sendiri
- ✅ **Menambahkan Agenda**: Membuat agenda pribadi
- ❌ **Melihat Agenda Semua Orang**: Tidak dapat melihat agenda orang lain
- ❌ **Membuat Agenda untuk Orang Lain**: Tidak bisa membuat agenda untuk user lain

#### 2. Disposisi
- ✅ **Melihat Disposisi Diterima**: Melihat disposisi yang diberikan kepada mereka
- ✅ **Update Disposisi**: Memberikan update status disposisi
- ✅ **Melihat History**: Melihat riwayat update disposisi
- ❌ **Membuat Disposisi**: Tidak dapat membuat disposisi (hanya pimpinan & admin)
- ❌ **Mengirim ke Pimpinan/Admin**: Tidak bisa

#### 3. Dokumen (Kelola Surat Saya)
- ✅ **Melihat Dokumen Pribadi**: Melihat dokumen yang dibuat diri sendiri
- ✅ **Menambahkan Dokumen**: Membuat dokumen/surat baru
- ✅ **Melihat Dokumen Dibagikan**: Melihat dokumen yang di-share dengan mereka
- ✅ **Mengedit Dokumen Pribadi**: Edit dokumen milik sendiri
- ❌ **Mengelola Akun**: Tidak ada akses

#### 4. Pengelolaan Akun
- ❌ **Tidak Memiliki Akses**

---

### B. Pimpinan (Pemimpin/Direktur)

#### 1. Agenda
- ✅ **Melihat Agenda Pribadi**: Melihat agenda pribadi mereka
- ✅ **Menambahkan Agenda Pribadi**: Membuat agenda pribadi
- ✅ **Membuat Agenda untuk Orang Lain**: 
  - Dapat membuat agenda untuk user atau pimpinan lain
  - Dapat mengirim ke MULTIPLE recipients sekaligus
  - Tidak dapat mengirim ke admin
  - Tidak dapat mengirim ke diri sendiri

#### 2. Disposisi
- ✅ **Melihat Disposisi Diterima**: Melihat disposisi yang diberikan ke mereka
- ✅ **Membuat Disposisi**: Dapat membuat dan mengirim disposisi ke:
  - User reguler ✅
  - Pimpinan lain ✅
  - Admin ✅
  - Multiple recipients ✅ (dapat mengirim ke >1 orang)
- ✅ **Update Disposisi**: Update status disposisi
- ✅ **Reassign Disposisi**: Dapat mendisposisikan ulang ke akun lain
- ✅ **Melihat History**: Melihat riwayat disposisi

#### 3. Dokumen (Kelola Surat Saya)
- ✅ **Melihat Dokumen Pribadi**: Melihat dokumen pribadi
- ✅ **Menambahkan Dokumen**: Membuat dokumen/surat
- ✅ **Share Dokumen**: Dapat membagikan dokumen dengan pengguna lain
- ✅ **Mengedit Dokumen**: Edit dokumen milik sendiri
- ✅ **Mengatur Visibility**: Private, Team, atau Public

#### 4. Pengelolaan Akun
- ❌ **Tidak Memiliki Akses**

---

### C. Admin (Administrator)

#### 1. Agenda
- ✅ **Melihat Semua Agenda**: Melihat agenda dari SEMUA user (user, pimpinan, admin)
- ✅ **Menambahkan Agenda Pribadi**: Membuat agenda pribadi
- ✅ **Membuat Agenda untuk Semua Orang**: 
  - Dapat membuat agenda untuk user, pimpinan, atau admin manapun
  - Dapat mengirim ke MULTIPLE recipients sekaligus

#### 2. Disposisi
- ✅ **Melihat Semua Disposisi**: Melihat disposisi dari semua pengguna
- ✅ **Membuat Disposisi**: Dapat membuat disposisi ke:
  - Pimpinan ✅
  - User ✅
  - Multiple recipients ✅
- ✅ **Update Disposisi**: Update status disposisi
- ✅ **Reassign Disposisi**: Dapat mendisposisikan ulang
- ✅ **Melihat History**: Melihat riwayat lengkap

#### 3. Dokumen (Kelola Surat Saya)
- ✅ **Melihat Semua Dokumen**: Akses ke semua dokumen di sistem
- ✅ **Menambahkan Dokumen**: Membuat dokumen
- ✅ **Mengedit Dokumen**: Edit dokumen apapun
- ✅ **Share Dokumen**: Dapat membagikan dokumen

#### 4. Pengelolaan Akun (Fitur Admin Eksklusif)
- ✅ **Membuat Akun Baru**: 
  - Pilih role: User, Pimpinan, atau Admin
  - Set email, password, departemen, posisi, dll
- ✅ **Melihat Semua Akun**: Daftar lengkap semua user
- ✅ **Edit Akun**: 
  - Ubah nama, email, departemen, posisi
  - Ubah role
  - Set status (active/inactive)
- ✅ **Reset Password**: Dapat mereset password user lain
- ✅ **Deaktivasi/Hapus Akun**: Dapat menonaktifkan atau menghapus akun

---

## Prioritas Disposisi

Semua role dapat menggunakan prioritas berikut:
- ⬜ **Low** - Prioritas rendah
- 🟩 **Normal** - Prioritas normal (default)
- 🟨 **High** - Prioritas tinggi
- 🔴 **Urgent** - Sangat mendesak

---

## Visibility Dokumen

- **Private** - Hanya dilihat oleh pemilik
- **Team** - Dapat dilihat oleh tim tertentu
- **Public** - Dapat dilihat semua orang di sistem

---

## Database Schema

### Tables Utama

#### users
```sql
- id (PRIMARY KEY)
- name
- email (UNIQUE)
- password (hashed)
- role (ENUM: 'admin', 'pimpinan', 'user')
- status (ENUM: 'active', 'inactive')
- phone
- address
- profile_photo
- department
- position
- created_at
- updated_at
- last_login
```

#### dispositions
```sql
- id (PRIMARY KEY)
- sender_id (FOREIGN KEY -> users.id)
- letter_number
- letter_date
- letter_subject
- letter_content
- document_file
- priority (ENUM: 'low', 'normal', 'high', 'urgent')
- status (ENUM: 'pending', 'in_progress', 'completed', 'reassigned')
- notes
- created_at
- updated_at
```

#### disposition_recipients
```sql
- id (PRIMARY KEY)
- disposition_id (FOREIGN KEY -> dispositions.id)
- recipient_user_id (FOREIGN KEY -> users.id)
- role_at_assignment (role saat disposisi diberikan)
- assigned_at (TIMESTAMP)
```

#### disposition_updates
```sql
- id (PRIMARY KEY)
- disposition_id (FOREIGN KEY -> dispositions.id)
- updated_by (FOREIGN KEY -> users.id)
- old_status
- new_status
- update_notes
- created_at
```

#### documents
```sql
- id (PRIMARY KEY)
- user_id (FOREIGN KEY -> users.id)
- document_number (UNIQUE)
- title
- description
- document_type
- document_file
- status (ENUM: 'draft', 'published', 'archived')
- visibility (ENUM: 'private', 'team', 'public')
- created_at
- updated_at
```

#### document_access
```sql
- id (PRIMARY KEY)
- document_id (FOREIGN KEY -> documents.id)
- user_id (FOREIGN KEY -> users.id)
- access_type (ENUM: 'view', 'edit', 'manage')
- created_at
```

#### agenda_recipients
```sql
- id (PRIMARY KEY)
- agenda_id (FOREIGN KEY -> agendas.id)
- recipient_user_id (FOREIGN KEY -> users.id)
- created_at
```

---

## Backend API Endpoints

### Authentication & Users

| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| POST | `/api/login.php` | Login user | No |
| POST | `/api/register.php` | Registrasi user | No |
| GET | `/api/users.php` | List semua users | Admin only |
| POST | `/api/users.php` | Buat user baru | Admin only |
| PUT | `/api/users.php` | Update user | Admin only |
| DELETE | `/api/users.php` | Hapus user | Admin only |

### Agenda

| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| GET | `/api/agenda.php` | List agenda (role-based) | Required |
| POST | `/api/agenda.php` | Buat agenda | Required |
| PUT | `/api/agenda.php` | Update agenda | Owner/Admin |
| DELETE | `/api/agenda.php` | Hapus agenda | Owner/Admin |

### Disposisi

| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| GET | `/api/dispositions.php` | List disposisi | Required |
| POST | `/api/dispositions.php` | Buat disposisi | Pimpinan/Admin |
| PUT | `/api/dispositions.php` | Update status disposisi | Recipient/Sender/Admin |

### Dokumen

| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| GET | `/api/documents.php` | List dokumen | Required |
| POST | `/api/documents.php` | Buat dokumen | Required |
| PUT | `/api/documents.php` | Update dokumen | Owner/Admin |

---

## Contoh Request API

### Create User (Admin Only)
```json
POST /api/users.php
Authorization: Bearer <token>

{
  "name": "John Pimpinan",
  "email": "john.pimpinan@example.com",
  "password": "password123",
  "role": "pimpinan",
  "department": "Leadership",
  "position": "Director"
}
```

### Create Disposition (Pimpinan/Admin)
```json
POST /api/dispositions.php
Authorization: Bearer <token>

{
  "letter_number": "SP-001/2026",
  "letter_date": "2026-04-24",
  "letter_subject": "Evaluasi Proyek Q2",
  "letter_content": "Silakan lakukan evaluasi menyeluruh...",
  "priority": "high",
  "notes": "Mohon selesaikan dalam 5 hari kerja",
  "recipient_ids": [3, 5, 7]
}
```

### Update Disposition Status
```json
PUT /api/dispositions.php
Authorization: Bearer <token>

{
  "id": 1,
  "status": "in_progress",
  "notes": "Sedang dikerjakan, progress 50%"
}
```

### Create Document
```json
POST /api/documents.php
Authorization: Bearer <token>

{
  "title": "Laporan Kinerja Q2 2026",
  "description": "Laporan performa tim untuk kuartal kedua",
  "document_type": "laporan",
  "document_number": "LAP-Q2-2026-001",
  "status": "published",
  "visibility": "team"
}
```

---

## Flutter Implementation

### Model Updates
- `User` model updated dengan field: `department`, `position`, dan helper methods
- `Disposition` model baru dengan support multi-recipient
- `Document` model baru untuk manajemen dokumen

### Service Classes Needed
- `UserService` - Authentication & user management
- `DispositionService` - Disposition CRUD operations
- `DocumentService` - Document CRUD operations
- `AgendaService` - Enhanced agenda with role support

### Screen Struktur
```
lib/screens/
├── login/ (sudah ada)
├── dashboard/ (perlu update untuk role-based)
├── agenda/ (perlu update)
├── disposisi/
│   ├── disposisi_list_screen.dart (ada)
│   ├── disposisi_input_screen.dart (ada)
│   ├── disposisi_detail_screen.dart (baru)
│   └── disposisi_history_screen.dart (baru)
├── documents/ (baru)
│   ├── document_list_screen.dart
│   ├── document_create_screen.dart
│   ├── document_detail_screen.dart
│   └── document_share_screen.dart
└── account_management/ (Admin only)
    ├── user_list_screen.dart
    ├── user_create_screen.dart
    ├── user_edit_screen.dart
    └── role_assignment_screen.dart
```

---

## Testing Credentials

```
Admin:
- Email: admin@example.com
- Password: password123
- Role: admin

Pimpinan:
- Email: pimpinan@example.com
- Password: password123
- Role: pimpinan

User:
- Email: user@example.com
- Password: password123
- Role: user
```

---

## Implementasi Checklist

### Backend (PHP)
- ✅ Database schema dengan 3 roles
- ✅ User management API (`/api/users.php`)
- ✅ Dispositions API (`/api/dispositions.php`)
- ✅ Documents API (`/api/documents.php`)
- ✅ Updated agenda API dengan multi-recipient support
- ✅ Updated register API dengan role support
- ⏳ Role-based access control middleware

### Flutter
- ✅ User model updated dengan 3 roles
- ✅ Disposition model created
- ✅ Document model created
- ⏳ UserService implementation
- ⏳ DispositionService implementation
- ⏳ DocumentService implementation
- ⏳ Enhanced dashboard dengan role-based navigation
- ⏳ Document management screens
- ⏳ Admin account management screens
- ⏳ Disposisi history & detail screens

---

## Catatan Penting

1. **Keamanan**: Semua endpoint dilindungi dengan JWT token verification
2. **Multiple Recipients**: Disposisi dan Agenda dapat dikirim ke multiple orang sekaligus
3. **History Tracking**: Setiap perubahan status disposisi dicatat di `disposition_updates`
4. **Visibility Levels**: Dokumen memiliki 3 tingkat visibility
5. **Role Hierarchy**: Admin > Pimpinan > User (dalam hal akses)
6. **Cascade Delete**: Ketika user dihapus, semua data terkait akan dihapus (ON DELETE CASCADE)

---

## Next Steps

1. **Implementasi Service Layer** di Flutter untuk API integration
2. **Update Dashboard** dengan role-based navigation
3. **Buat Screen** untuk setiap fitur (dokumen, account management, dll)
4. **Testing** dengan berbagai role
5. **Optimasi UI/UX** untuk setiap role

