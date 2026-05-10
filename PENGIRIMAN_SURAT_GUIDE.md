# 📋 Halaman Pengiriman Surat & Pembuatan Dokumen

## Daftar Isi
1. [Halaman Pengiriman Surat Disposisi](#halaman-pengiriman-surat-disposisi)
2. [Halaman Pembuatan Dokumen Baru](#halaman-pembuatan-dokumen-baru)
3. [Cara Menggunakan](#cara-menggunakan)

---

## Halaman Pengiriman Surat Disposisi

**File:** `lib/screens/disposisi/disposisi_send_screen.dart`

### Deskripsi
Halaman untuk admin dan pimpinan mengelola pengiriman surat disposisi. Halaman ini menampilkan:
- Daftar surat yang telah dikirimkan
- Filter berdasarkan kategori surat
- Kolom informasi: No, Nama Dokumen, Tipe Dokumen, Dikirimkan ke, Tanggal Dokumen, Aksi
- Tombol untuk mengedit atau membuat disposisi baru

### Fitur Utama
✅ **Tab Kategori**: Filter surat berdasarkan tipe (Semua, Surat Keputusan, Surat Tugas, Surat Personal, Lain-lain)
✅ **Filter Urutan**: Urutkan berdasarkan Terbaru/Terlama/A-Z
✅ **Tabel Data**: Tampilkan daftar surat dengan informasi lengkap
✅ **Tombol Edit**: Edit surat yang sudah dibuat
✅ **Tombol Tambah**: Buat pengiriman surat baru

### Status Role
- ✓ Admin
- ✓ Pimpinan
- ✗ User (tidak memiliki akses)

### Interface
```
┌─ Pengirimman Surat                      [Tambahkan Dokumen Baru]
│ Admin
├─ Semua | Surat Keputusan | Surat Tugas | Surat Personal | Lain-lain
├─ Urutan ▼
├─ ┌────┬──────────────────────┬────────────┬─────────────┬───────────┬──────┐
│  │ No │ Nama Dokumen         │ Tipe       │ Dikirimkan  │ Tanggal   │ Aksi │
│  ├────┼──────────────────────┼────────────┼─────────────┼───────────┼──────┤
│  │ 1  │ Surat Tugas PkM      │ Surat      │ Dekan, ...  │ 15-10... │ Edit │
│  │ 2  │ Surat Kenaikan       │ Surat      │ KTU         │ 23-04... │ Edit │
│  └────┴──────────────────────┴────────────┴─────────────┴───────────┴──────┘
```

---

## Halaman Pembuatan Dokumen Baru

**File:** `lib/screens/disposisi/disposisi_create_screen.dart`

### Deskripsi
Halaman untuk membuat dan mengirimkan surat disposisi baru. Halaman ini menyediakan form lengkap untuk:
- Input judul dokumen
- Pilih tanggal dan waktu
- Pilih jenis dokumen
- Upload file dokumen
- Pilih penerima (multiple recipients)
- Tambah deskripsi

### Fitur Utama
✅ **Input Judul**: Masukkan judul surat/dokumen
✅ **Date Picker**: Pilih tanggal dokumen dengan date picker
✅ **Time Picker**: Pilih waktu dokumen
✅ **Jenis Dokumen**: Dropdown untuk memilih tipe surat (Surat Keputusan, Surat Tugas, dll)
✅ **Upload File**: Upload file dokumen (PDF, DOC, etc)
✅ **Multiple Recipients**: Pilih penerima dari daftar yang tersedia
✅ **Description**: Tambahkan deskripsi/catatan dokumen
✅ **Validasi Form**: Semua field wajib diisi sebelum simpan

### Jenis Dokumen Tersedia
- Surat Keputusan
- Surat Tugas
- Surat Personal
- Pengumuman
- Lainnya

### Penerima Tersedia
- Dekan
- Wakil Dekan
- Kepala Administrasi
- KTU
- Staff

### Status Role
- ✓ Admin
- ✓ Pimpinan
- ✗ User (tidak memiliki akses)

### Interface
```
┌─ Penambahan Dokumen
├─ Tambahkan Judul Disini
│  └─ [input: Masukkan judul dokumen...]
│
├─ Tanggal Dokumen: 22 Maret 2026  | Waktu: 08:00
│
├─ Detail Dokumen
│  ├─ Jenis Dokumen: [Surat Keputusan ▼]  | [Upload Dokumen]
│
├─ Tujuan Dokumen 👥
│  ├─ [Dekan] [Wakil Dekan] [Kepala Administrasi] [KTU] [Staff]
│  ├─ [Tujuan Dokumen ▼]
│  └─ [Tambahkan Tujuan]
│
├─ Deskripsi Dokumen
│  └─ [text area: Tambahkan Deskripsi...]
│
└─ [Simpan]
```

---

## Cara Menggunakan

### 1. Akses Halaman Pengiriman Surat
1. Login sebagai Admin atau Pimpinan
2. Klik menu "Disposisi Surat" di sidebar
3. Halaman "Pengirimman Surat" akan terbuka

### 2. Filter & Cari Surat
```
- Pilih kategori pada tab (Semua, Surat Keputusan, dll)
- Gunakan dropdown "Urutan" untuk mengurutkan data
- Data akan di-filter sesuai pilihan
```

### 3. Buat Pengiriman Surat Baru
1. Klik tombol "Tambahkan Dokumen Baru"
2. Halaman "Penambahan Dokumen" akan terbuka
3. Isi form dengan lengkap:
   - **Judul Dokumen**: Masukkan judul surat
   - **Tanggal & Waktu**: Pilih tanggal dan waktu dokumen
   - **Jenis Dokumen**: Pilih dari dropdown
   - **Upload File**: Klik tombol upload dan pilih file
   - **Tujuan**: Pilih penerima dari list atau dropdown
   - **Deskripsi**: Tambahkan catatan/deskripsi
4. Klik "Simpan" untuk menyimpan disposisi

### 4. Edit Surat (Future Feature)
- Klik tombol "Edit" pada baris surat yang ingin diubah
- Form akan terisi dengan data surat yang dipilih
- Ubah data sesuai kebutuhan
- Klik "Simpan" untuk mengupdate

---

## Integrasi API

### Endpoint yang Diperlukan (Backend)

#### 1. Dapatkan Daftar Disposisi
```
GET /api/dispositions.php?filter=sent
Response:
{
  "success": true,
  "data": [
    {
      "id": 1,
      "letter_number": "001/2026",
      "letter_subject": "Surat Tugas PkM",
      "letter_date": "2024-10-15",
      "document_type": "Surat Tugas",
      "recipients": ["Dekan", "Wakil Dekan"],
      "status": "completed"
    }
  ]
}
```

#### 2. Buat Disposisi Baru
```
POST /api/dispositions.php
Body:
{
  "letter_number": "001/2026",
  "letter_subject": "Judul Surat",
  "letter_date": "2024-10-15",
  "letter_content": "Isi surat...",
  "document_file": "base64_encoded_file",
  "priority": "normal",
  "recipient_ids": [2, 3, 4],
  "notes": "Deskripsi dokumen"
}
```

#### 3. Update Disposisi
```
PUT /api/dispositions.php?id=1
Body:
{
  "letter_subject": "Judul Baru",
  "letter_date": "2024-10-20",
  "recipient_ids": [2, 3],
  "notes": "Catatan baru"
}
```

---

## TODO (Feature Belum Diimplementasi)

- [ ] Integrasi API untuk fetch data disposisi dari backend
- [ ] Implementasi upload file dengan file_picker package
- [ ] Implementasi simpan disposisi ke backend
- [ ] Implementasi edit disposisi
- [ ] Implementasi search/filter berdasarkan nama dokumen
- [ ] Implementasi pagination untuk tabel
- [ ] Implementasi status tracking (pending/completed/etc)
- [ ] Email notification ke penerima surat
- [ ] Generate report/archive surat

---

## Dependencies yang Digunakan

```yaml
flutter:
  sdk: flutter
shared_preferences: ^2.2.0
http: ^1.1.0
intl: ^0.19.0  # Untuk date formatting
file_picker: ^5.3.0  # Untuk upload file (optional)
pdf: ^3.8.0  # Untuk handle PDF (optional)
```

---

## Notes
- Saat ini halaman menggunakan dummy data
- Untuk production, harus diintegrasikan dengan backend API
- Validasi form sudah tersedia
- UI sudah sesuai dengan design yang diminta
