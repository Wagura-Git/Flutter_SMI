# API Reference Guide - SI Manajemen Kampus

## Base URL
```
http://localhost/1_Project_Thesis/SI-manajemen-kampus/backend/api/
```

## Authentication

All endpoints except `/login.php` and `/register.php` require authentication via Bearer Token in the Authorization header.

```
Authorization: Bearer <JWT_TOKEN>
```

---

## 👤 User Management Endpoints

### 1. Register User
**Endpoint**: `POST /register.php`  
**Auth Required**: ❌ No  
**Role**: Anyone

**Request Body**:
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirm": "password123",
  "role": "user|pimpinan|admin",
  "phone": "08123456789",
  "address": "Jl. Merdeka No. 1",
  "department": "Operations",
  "position": "Staff"
}
```

**Response (201 Created)**:
```json
{
  "success": true,
  "message": "Registrasi berhasil",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user"
    }
  }
}
```

---

### 2. Login
**Endpoint**: `POST /login.php`  
**Auth Required**: ❌ No  
**Role**: Anyone

**Request Body**:
```json
{
  "email": "admin@example.com",
  "password": "password123"
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "message": "Login berhasil",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": 1,
      "name": "Admin User",
      "email": "admin@example.com",
      "role": "admin",
      "department": "Administration",
      "position": "Administrator"
    }
  }
}
```

---

### 3. Get All Users
**Endpoint**: `GET /users.php`  
**Auth Required**: ✅ Yes  
**Role**: 🔒 Admin Only

**Response (200 OK)**:
```json
{
  "success": true,
  "message": "Berhasil mengambil data users",
  "data": [
    {
      "id": 1,
      "name": "Admin User",
      "email": "admin@example.com",
      "role": "admin",
      "status": "active",
      "phone": "08123456789",
      "address": "Jl. Admin",
      "profile_photo": null,
      "department": "Administration",
      "position": "Administrator",
      "created_at": "2026-04-24 08:00:00"
    },
    {
      "id": 2,
      "name": "Pimpinan User",
      "email": "pimpinan@example.com",
      "role": "pimpinan",
      "status": "active",
      "phone": "08187654321",
      "address": "Jl. Pimpinan",
      "profile_photo": null,
      "department": "Leadership",
      "position": "Director",
      "created_at": "2026-04-24 08:00:00"
    }
  ]
}
```

---

### 4. Create User
**Endpoint**: `POST /users.php`  
**Auth Required**: ✅ Yes  
**Role**: 🔒 Admin Only

**Request Body**:
```json
{
  "name": "New Pimpinan",
  "email": "new.pimpinan@example.com",
  "password": "password123",
  "role": "pimpinan",
  "phone": "08111111111",
  "address": "Jl. Baru",
  "department": "Operations",
  "position": "Manager"
}
```

**Response (201 Created)**:
```json
{
  "success": true,
  "message": "User berhasil dibuat",
  "data": {
    "id": 4,
    "name": "New Pimpinan",
    "email": "new.pimpinan@example.com",
    "role": "pimpinan",
    "phone": "08111111111",
    "address": "Jl. Baru",
    "department": "Operations",
    "position": "Manager",
    "status": "active"
  }
}
```

---

### 5. Update User
**Endpoint**: `PUT /users.php`  
**Auth Required**: ✅ Yes  
**Role**: 🔒 Admin Only

**Request Body** (send only fields to update):
```json
{
  "id": 4,
  "name": "Updated Name",
  "email": "updated.email@example.com",
  "role": "admin",
  "status": "inactive",
  "position": "Senior Manager",
  "password": "newpassword123"
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "message": "User berhasil diubah"
}
```

---

### 6. Delete User
**Endpoint**: `DELETE /users.php`  
**Auth Required**: ✅ Yes  
**Role**: 🔒 Admin Only

**Request Body**:
```json
{
  "id": 4
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "message": "User berhasil dihapus"
}
```

---

## 📅 Agenda Endpoints

### 1. Get Agendas
**Endpoint**: `GET /agenda.php`  
**Auth Required**: ✅ Yes  
**Role**: All (results filtered by role)

**Response (200 OK)**:
```json
{
  "success": true,
  "message": "Agendas fetched successfully",
  "data": [
    {
      "id": 1,
      "user_id": 1,
      "user_name": "Admin User",
      "title": "Rapat Rutin",
      "description": "Rapat koordinasi mingguan",
      "date": "2026-04-25",
      "time_start": "09:00:00",
      "time_end": "10:30:00",
      "location": "Ruang Meeting",
      "category": "meeting",
      "status": "scheduled",
      "created_at": "2026-04-24 08:00:00",
      "updated_at": "2026-04-24 08:00:00"
    }
  ]
}
```

---

### 2. Create Agenda
**Endpoint**: `POST /agenda.php`  
**Auth Required**: ✅ Yes  
**Role**: All (pimpinan/admin can create for others)

**Request Body**:
```json
{
  "title": "Meeting Penting",
  "description": "Diskusi strategi bisnis",
  "date": "2026-04-25",
  "time_start": "10:00:00",
  "time_end": "11:00:00",
  "location": "Ruang 101",
  "category": "meeting",
  "recipient_ids": [2, 3]
}
```

**Response (201 Created)**:
```json
{
  "success": true,
  "message": "Agenda berhasil dibuat",
  "data": {
    "id": 5
  }
}
```

---

### 3. Update Agenda
**Endpoint**: `PUT /agenda.php`  
**Auth Required**: ✅ Yes  
**Role**: Owner / Admin

**Request Body**:
```json
{
  "id": 5,
  "title": "Updated Meeting",
  "date": "2026-04-26",
  "status": "completed"
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "message": "Agenda berhasil diperbarui"
}
```

---

### 4. Delete Agenda
**Endpoint**: `DELETE /agenda.php`  
**Auth Required**: ✅ Yes  
**Role**: Owner / Admin

**Request Body**:
```json
{
  "id": 5
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "message": "Agenda berhasil dihapus"
}
```

---

## 📝 Dispositions Endpoints

### 1. Get Dispositions
**Endpoint**: `GET /dispositions.php`  
**Auth Required**: ✅ Yes  
**Role**: All (filtered by role)

**Response (200 OK)**:
```json
{
  "success": true,
  "message": "Berhasil mengambil data disposisi",
  "data": [
    {
      "id": 1,
      "sender_id": 2,
      "sender_name": "Pimpinan User",
      "letter_number": "SP-001/2026",
      "letter_date": "2026-04-24",
      "letter_subject": "Evaluasi Proyek Q2",
      "letter_content": "Silakan lakukan evaluasi...",
      "document_file": null,
      "priority": "high",
      "status": "pending",
      "notes": "Selesaikan dalam 5 hari kerja",
      "created_at": "2026-04-24 10:00:00",
      "updated_at": "2026-04-24 10:00:00",
      "recipients": [
        {
          "id": 1,
          "recipient_user_id": 3,
          "recipient_name": "John Doe",
          "role_at_assignment": "user",
          "assigned_at": "2026-04-24 10:00:00"
        }
      ],
      "updates": [
        {
          "id": 1,
          "disposition_id": 1,
          "updated_by": 3,
          "updated_by_name": "John Doe",
          "old_status": "pending",
          "new_status": "in_progress",
          "update_notes": "Mulai dikerjakan",
          "created_at": "2026-04-24 14:00:00"
        }
      ]
    }
  ]
}
```

---

### 2. Create Disposition
**Endpoint**: `POST /dispositions.php`  
**Auth Required**: ✅ Yes  
**Role**: 🔒 Pimpinan / Admin Only

**Request Body**:
```json
{
  "letter_number": "SP-002/2026",
  "letter_date": "2026-04-24",
  "letter_subject": "Revisi Dokumen",
  "letter_content": "Silakan lakukan revisi dokumen...",
  "priority": "high",
  "notes": "Urgent - mohon segera diselesaikan",
  "recipient_ids": [2, 3, 5]
}
```

**Response (201 Created)**:
```json
{
  "success": true,
  "message": "Disposisi berhasil dibuat",
  "data": {
    "id": 2,
    "sender_id": 1,
    "letter_number": "SP-002/2026",
    "letter_subject": "Revisi Dokumen",
    "priority": "high",
    "status": "pending"
  }
}
```

---

### 3. Update Disposition Status
**Endpoint**: `PUT /dispositions.php`  
**Auth Required**: ✅ Yes  
**Role**: Recipient / Sender / Admin

**Request Body**:
```json
{
  "id": 2,
  "status": "in_progress",
  "notes": "Sedang dikerjakan, 60% selesai"
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "message": "Disposisi berhasil diubah"
}
```

---

## 📄 Documents Endpoints

### 1. Get Documents
**Endpoint**: `GET /documents.php`  
**Auth Required**: ✅ Yes  
**Role**: All (filtered by access)

**Response (200 OK)**:
```json
{
  "success": true,
  "message": "Berhasil mengambil data dokumen",
  "data": [
    {
      "id": 1,
      "user_id": 1,
      "user_name": "Admin User",
      "document_number": "LAP-Q2-2026-001",
      "title": "Laporan Kinerja Q2 2026",
      "description": "Laporan performa tim kuartal kedua",
      "document_type": "laporan",
      "document_file": null,
      "status": "published",
      "visibility": "team",
      "created_at": "2026-04-24 09:00:00",
      "updated_at": "2026-04-24 09:00:00",
      "access_list": [
        {
          "id": 1,
          "user_id": 2,
          "user_name": "Pimpinan User",
          "access_type": "view",
          "created_at": "2026-04-24 09:30:00"
        }
      ]
    }
  ]
}
```

---

### 2. Create Document
**Endpoint**: `POST /documents.php`  
**Auth Required**: ✅ Yes  
**Role**: All

**Request Body**:
```json
{
  "title": "Proposal Proyek Baru",
  "description": "Proposal untuk inisiatif transformasi digital",
  "document_type": "proposal",
  "document_number": "PROP-2026-001",
  "status": "draft",
  "visibility": "private"
}
```

**Response (201 Created)**:
```json
{
  "success": true,
  "message": "Dokumen berhasil dibuat",
  "data": {
    "id": 3,
    "user_id": 1,
    "document_number": "PROP-2026-001",
    "title": "Proposal Proyek Baru",
    "status": "draft",
    "visibility": "private"
  }
}
```

---

### 3. Update Document
**Endpoint**: `PUT /documents.php`  
**Auth Required**: ✅ Yes  
**Role**: Owner / Admin

**Request Body**:
```json
{
  "id": 3,
  "title": "Updated Proposal",
  "status": "published",
  "visibility": "team",
  "share_with": [2, 4, 5]
}
```

**Response (200 OK)**:
```json
{
  "success": true,
  "message": "Dokumen berhasil diubah"
}
```

---

## Error Responses

All endpoints follow this error response format:

```json
{
  "success": false,
  "message": "Deskripsi error",
  "data": null,
  "statusCode": 400
}
```

### Common Error Codes

| Code | Message | Reason |
|------|---------|--------|
| 400 | Bad Request | Invalid input data |
| 401 | Unauthorized | Missing or invalid token |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 409 | Conflict | Resource already exists (e.g., duplicate email) |
| 500 | Server Error | Internal server error |

---

## Status Values

### Disposition Status
- `pending` - Menunggu ditangani
- `in_progress` - Sedang dikerjakan
- `completed` - Selesai
- `reassigned` - Didelegasikan ke orang lain

### Document Status
- `draft` - Draft
- `published` - Published
- `archived` - Archived

### Agenda Status
- `scheduled` - Dijadwalkan
- `completed` - Selesai
- `cancelled` - Dibatalkan

### Priority Levels
- `low` - Rendah
- `normal` - Normal
- `high` - Tinggi
- `urgent` - Mendesak

### Document Visibility
- `private` - Hanya untuk diri sendiri
- `team` - Dapat dilihat oleh tim
- `public` - Dapat dilihat semua orang

### User Status
- `active` - Aktif
- `inactive` - Tidak aktif

---

## Rate Limiting

Currently no rate limiting is implemented. Future versions may include:
- 100 requests per minute per user
- 1000 requests per hour per IP

---

## Pagination

Future versions may include pagination support:
```
GET /users.php?page=1&limit=10&sort=created_at&order=DESC
```

---

## Versioning

Current API Version: `1.0.0`

Future versions:
- v1.1.0 - Add pagination
- v2.0.0 - Major feature additions

---

## Last Updated
April 24, 2026

