# Database Management Guide

## ⚠️ PENTING: Jangan gunakan `database.sql` langsung!

Database sekarang terbagi menjadi 3 file untuk mencegah data hilang:

## 📁 File-file Database

### 1. **schema.sql** - Struktur Tabel (Aman untuk Update)
- Hanya CREATE TABLE IF NOT EXISTS statements
- **Tidak ada DROP DATABASE** - data yang ada tetap aman
- Gunakan ini untuk **update schema tanpa kehilangan data**
- Gunakan ke: `safe_migration.php`

### 2. **seeds.sql** - Data Awal Testing
- Data sample untuk testing (users, documents, agendas)
- Menggunakan `INSERT ... WHERE NOT EXISTS` (tidak duplikasi)
- Hanya jalankan sekali saat setup pertama
- Gunakan ke: `run_initial_setup.php`

### 3. **database.sql** - Legacy (JANGAN GUNAKAN SENDIRI!)
- File lama, hanya untuk dokumentasi
- **MENGHAPUS SEMUA DATABASE JIKA DIJALANKAN**
- Hanya gunakan jika ingin fresh start (data akan hilang!)

---

## 🚀 Cara Setup Database

### Setup Pertama Kali (Fresh Install)
Jalankan file ini satu kali untuk membuat database + schema + data sample:

```bash
php backend/run_initial_setup.php
```

Ini akan:
- ✅ Membuat database `si_manajemen_kampus`
- ✅ Membuat semua tabel
- ✅ Insert data sample

### Update Schema (Tanpa Kehilangan Data)
Setelah setup pertama, gunakan ini untuk update schema:

```bash
php backend/safe_migration.php
```

Ini akan:
- ✅ Membuat tabel yang belum ada
- ✅ Menambah kolom yang baru
- ❌ TIDAK menghapus data existing

---

## 📊 Workflow yang Benar

| Situasi | Script | Efek |
|---------|--------|------|
| Instalasi pertama | `run_initial_setup.php` | ✅ Fresh database + data |
| Update schema | `safe_migration.php` | ✅ Kolom baru, data aman |
| Backup/debugging | `schema.sql` | 📖 Hanya baca structure |
| **RESET SEMUA (HATI-HATI!)** | `database.sql` | ⚠️ Hapus + recreate |

---

## ⚡ Perintah CLI (PhpMyAdmin Alternative)

### Via MySQL CLI

**Setup pertama:**
```sql
mysql -u root -p < backend/database.sql
```

**Update schema saja:**
```sql
mysql -u root -p si_manajemen_kampus < backend/schema.sql
```

**Insert sample data:**
```sql
mysql -u root -p si_manajemen_kampus < backend/seeds.sql
```

---

## 🔍 Troubleshooting

### Masalah: Data akun hilang setelah update
**Solusi:** Gunakan `safe_migration.php` bukan `database.sql`

### Masalah: Table sudah ada error
**Solusi:** Schema menggunakan `IF NOT EXISTS`, aman untuk dijalankan berkali-kali

### Masalah: Ingin reset total (menghapus semua data)
**Solusi:** Jalankan `run_initial_setup.php` yang akan DROP dan recreate database

---

## 📝 Summary

```
✅ Gunakan: safe_migration.php untuk update schema
❌ Jangan gunakan: database.sql untuk update rutin
✅ Gunakan: run_initial_setup.php untuk setup pertama
✅ Gunakan: seeds.sql jika mau insert data sample lagi
```

**Sekarang akun Anda akan AMAN tidak akan hilang!** 🎉
