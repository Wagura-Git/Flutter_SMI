# Dokumentasi Fitur Disposisi Surat - Update April 2026

## Overview
Sistem disposisi surat telah diperbarui dengan fitur tabel dinamis yang dapat menampilkan dan mengelola disposisi berdasarkan role pengguna (Admin, Pimpinan, User).

## Fitur Utama

### 1. Disposisi List Screen (disposisi_list_screen.dart)
Screen yang menampilkan tabel disposisi dengan fitur-fitur berikut:

#### Kolom Tabel:
- **No**: Nomor urut disposisi
- **Dokumen**: Nama/subjek dokumen disposisi
- **Dari**: Nama pengguna yang mengirim disposisi
- **Untuk**: Nama penerima disposisi (recipient)
- **Tanggal**: Tanggal pembuatan disposisi
- **Status**: Badge status dengan warna berbeda
  - Menunggu (Orange) - pending
  - Diproses (Royal Blue) - processed
  - Selesai (Green) - completed
  - Dialihkan (Gray) - reassigned
- **Aksi**: Menu aksi untuk update status dan delete (admin only)

#### Fitur Filtering:
- Dropdown urutan: Terbaru/Terlama
- Data secara otomatis diurutkan berdasarkan pilihan

#### Aksi Disponibel:
**Untuk Admin:**
- Update status: Menunggu, Diproses, Selesai
- Hapus disposisi

**Untuk Pimpinan:**
- Update status: Menunggu, Diproses, Selesai

**Untuk User:**
- Hanya dapat melihat status (no actions)

### 2. Integrasi API

#### Endpoint yang Digunakan:
- **GET** `/api/dispositions.php` - Mengambil daftar disposisi
- **PUT** `/api/dispositions.php` - Update status disposisi
- **DELETE** `/api/dispositions.php?id={id}` - Hapus disposisi
- **POST** `/api/dispositions.php` - Membuat disposisi baru

#### Logika Filtering:
- **Admin**: Melihat SEMUA disposisi di sistem
- **Pimpinan**: Melihat disposisi yang dibuat oleh atau dikirimkan kepada mereka
- **User**: Melihat disposisi yang dikirimkan kepada mereka

### 3. Disposition Service (disposition_service.dart)
Service baru untuk menangani komunikasi dengan API:

```dart
// Dapatkan semua disposisi (sesuai role)
DispositionService.getDispositions(token)

// Buat disposisi baru
DispositionService.createDisposition(
  token, documentId, recipientIds, instruction
)

// Update status disposisi
DispositionService.updateDisposition(
  token, dispositionId, status
)

// Hapus disposisi
DispositionService.deleteDisposition(token, dispositionId)
```

### 4. Model Disposition
Model yang sudah ada mendukung:
- Multiple recipients (untuk future scalability)
- Disposition updates tracking
- Status dan priority management

## Role-Based Access Control

| Feature | Admin | Pimpinan | User |
|---------|-------|----------|------|
| Lihat semua disposisi | ✅ | ❌ | ❌ |
| Lihat disposisi yang dibuat | ✅ | ✅ | ❌ |
| Lihat disposisi yang dikirim ke | ✅ | ✅ | ✅ |
| Buat disposisi baru | ✅ | ✅ | ❌ |
| Update status disposisi | ✅ | ✅ | ❌ |
| Hapus disposisi | ✅ | ❌ | ❌ |

## Data Structure

### Disposition Object
```json
{
  "id": 1,
  "sender_id": 2,
  "letter_subject": "Surat Tugas PkM Desa Tonja",
  "letter_content": "Instruksi disposisi",
  "document_file": "path/to/file.pdf",
  "priority": "normal",
  "status": "pending",
  "created_at": "2026-04-26T10:30:00",
  "sender_name": "Dr. Pimpinan",
  "recipients": [
    {
      "id": 3,
      "recipient_user_id": 3,
      "recipient_name": "Staff User",
      "role_at_assignment": "user",
      "assigned_at": "2026-04-26T10:30:00"
    }
  ],
  "updates": []
}
```

## UI/UX Improvements

### Loading State
- Circular progress indicator ketika loading data
- "Tidak ada disposisi" message ketika data kosong

### Error Handling
- SnackBar notifications untuk error messages
- Try-catch blocks untuk API calls
- Validation untuk semua aksi

### Status Badge
- Warna-coded status untuk visibility yang lebih baik
- Responsive design untuk semua ukuran layar

### Action Menu
- PopupMenuButton untuk context-based actions
- Confirmation dialog untuk delete action

## Perubahan File

### File Baru:
1. `lib/services/disposition_service.dart` - Service untuk API calls

### File Dimodifikasi:
1. `lib/screens/surat/disposisi_list_screen.dart` - Complete redesign ke StatefulWidget dengan API integration
2. `lib/screens/surat/disposisi_input_screen.dart` - Added role parameter
3. `lib/screens/dashboard/widgets/sidebar.dart` - Updated untuk menggunakan DisposisiListScreen
4. `pubspec.yaml` - Added intl package untuk date formatting

## Testing Checklist

- [ ] Test sebagai Admin - dapat melihat semua disposisi
- [ ] Test sebagai Pimpinan - dapat melihat disposisi yang dibuat dan diterima
- [ ] Test sebagai User - hanya dapat melihat disposisi yang diterima
- [ ] Test sorting terbaru/terlama
- [ ] Test update status untuk semua roles
- [ ] Test delete action (admin only)
- [ ] Test error handling untuk failed API calls
- [ ] Test loading state
- [ ] Test empty state

## Future Enhancements

1. **Multi-recipient support** - Backend sudah support, tinggal display multiple recipients
2. **Disposition history** - Menampilkan riwayat update disposisi
3. **Search/Filter** - Filter berdasarkan dokumen, penerima, status
4. **Export functionality** - Export disposisi ke PDF/Excel
5. **Notifications** - Real-time notifications untuk new dispositions
6. **Comment/Notes** - Penambahan catatan pada disposisi
7. **Reassignment** - Mengalihkan disposisi ke penerima lain

## Deployment Notes

1. Pastikan intl package sudah diinstall: `flutter pub get`
2. Pastikan API endpoints di backend sudah berfungsi dengan baik
3. Token authentication harus sudah tersimpan di SharedPreferences
4. Test dengan data yang sudah ada di database terlebih dahulu

## Troubleshooting

### Issue: Disposisi tidak muncul
- Cek token di SharedPreferences
- Cek API response di debug console
- Pastikan user memiliki permissions yang tepat

### Issue: Loading stuck
- Cek network connectivity
- Cek API server status
- Cek timeout duration di DispositionService

### Issue: Status tidak berubah
- Cek apakah user memiliki permission untuk update status
- Cek API response untuk error message
- Pastikan status yang dikirim valid (pending/processed/completed)
