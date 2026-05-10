# 🎯 Quick Reference Card - 3 Role System

## Role Comparison at a Glance

```
┌────────────┬─────────────┬──────────────┬──────────┐
│ Feature    │ User        │ Pimpinan     │ Admin    │
├────────────┼─────────────┼──────────────┼──────────┤
│ Agenda     │ Own only    │ Own + Others │ All Users│
│ Disposisi  │ View/Update │ Create/Send  │ Create   │
│ Dokumen    │ Own + Share │ Own + Share  │ All      │
│ Akun       │ ❌          │ ❌           │ ✅ Full  │
│ Multi-User │ ❌          │ ✅ Yes       │ ✅ Yes   │
└────────────┴─────────────┴──────────────┴──────────┘
```

---

## 📊 Database Tables (Quick View)

| Table | Purpose | Key Fields |
|-------|---------|-----------|
| **users** | Store users | id, role (admin/pimpinan/user), dept, position |
| **dispositions** | Store assignments | id, sender_id, letter_subject, priority, status |
| **disposition_recipients** | Multi-recipient support | disposition_id, recipient_user_id |
| **disposition_updates** | History tracking | disposition_id, updated_by, old_status, new_status |
| **documents** | Store docs/letters | id, user_id, document_number, status, visibility |
| **document_access** | Document sharing | document_id, user_id, access_type |
| **agenda_recipients** | Multi-recipient agendas | agenda_id, recipient_user_id |

---

## 🔌 API Endpoints (Quick View)

### Authentication
```
POST /register.php    → Register new user
POST /login.php       → Login & get token
```

### Users (Admin Only)
```
GET    /users.php     → List all users
POST   /users.php     → Create user
PUT    /users.php     → Edit user
DELETE /users.php     → Delete user
```

### Agenda (All roles)
```
GET    /agenda.php    → List agendas (role-filtered)
POST   /agenda.php    → Create agenda
PUT    /agenda.php    → Update agenda
DELETE /agenda.php    → Delete agenda
```

### Dispositions (Pimpinan/Admin create)
```
GET    /dispositions.php  → List dispositions
POST   /dispositions.php  → Create disposition
PUT    /dispositions.php  → Update status
```

### Documents (All roles)
```
GET    /documents.php     → List documents
POST   /documents.php     → Create document
PUT    /documents.php     → Update/share document
```

---

## 🔐 Authentication Header

Every request (except login/register) needs:
```
Authorization: Bearer <JWT_TOKEN>
```

Example:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 👤 Sample Test Users

```
Email                      Password      Role
─────────────────────────────────────────────────
admin@example.com         password123   admin
pimpinan@example.com      password123   pimpinan
user@example.com          password123   user
```

---

## 📋 Disposition Status Lifecycle

```
pending → in_progress → completed
   ↓
   └─→ reassigned → (loop back)
```

**Valid Statuses**: `pending`, `in_progress`, `completed`, `reassigned`

---

## 📄 Document Status & Visibility

**Status**: `draft` → `published` → `archived`

**Visibility**:
- `private` - Only owner
- `team` - Team members
- `public` - Everyone

---

## ⚡ Priority Levels

| Level | Color | Use Case |
|-------|-------|----------|
| `low` | ⬜ Gray | Non-urgent |
| `normal` | 🟩 Green | Standard (default) |
| `high` | 🟨 Yellow | Important |
| `urgent` | 🔴 Red | Critical/ASAP |

---

## 🛡️ Permission Matrix

### User Permissions
- View own agenda ✅
- Create personal agenda ✅
- Receive dispositions ✅
- Update disposition status ✅
- View own documents ✅
- Manage account ❌

### Pimpinan Permissions
- View own agenda ✅
- Create agenda for others ✅
- Send multiple recipients ✅
- Create dispositions ✅
- Manage own documents ✅
- Share documents ✅
- Manage account ❌

### Admin Permissions
- View ALL agendas ✅
- Create agenda for anyone ✅
- Send to multiple recipients ✅
- Create dispositions ✅
- View ALL documents ✅
- **Manage all accounts** ✅
- **Create new users** ✅
- **Change user roles** ✅
- **Reset passwords** ✅

---

## 💾 Key Database Constraints

✅ **users.role** - ENUM('admin', 'pimpinan', 'user')  
✅ **dispositions.status** - ENUM('pending', 'in_progress', 'completed', 'reassigned')  
✅ **dispositions.priority** - ENUM('low', 'normal', 'high', 'urgent')  
✅ **documents.status** - ENUM('draft', 'published', 'archived')  
✅ **documents.visibility** - ENUM('private', 'team', 'public')  
✅ **Unique email** in users table  
✅ **Unique document_number** (if provided)  

---

## 🚀 REST Method Reference

| Method | Usage | Example |
|--------|-------|---------|
| **GET** | Fetch/Read | GET /users.php |
| **POST** | Create | POST /users.php |
| **PUT** | Update | PUT /users.php |
| **DELETE** | Remove | DELETE /users.php |

---

## 📲 Common Request/Response Patterns

### Success Response (200/201)
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { /* response data */ }
}
```

### Error Response (4xx/5xx)
```json
{
  "success": false,
  "message": "Error description",
  "data": null
}
```

---

## 🔄 Multi-Recipient Format

### Create Disposition with Multiple Recipients
```json
{
  "letter_subject": "Title",
  "recipient_ids": [2, 3, 5]
}
```

### Create Agenda for Multiple People
```json
{
  "title": "Meeting",
  "date": "2026-04-25",
  "time_start": "10:00:00",
  "recipient_ids": [2, 3, 5]
}
```

---

## 🔍 Common API Calls

### 1. Get User's Dispositions
```
GET /dispositions.php
Authorization: Bearer <token>
```
Returns: Dispositions sent by user or assigned to user

### 2. Create & Send Disposition to 3 People
```
POST /dispositions.php
Authorization: Bearer <token>
Content-Type: application/json

{
  "letter_subject": "Subject",
  "priority": "high",
  "recipient_ids": [2, 3, 5]
}
```

### 3. Update Disposition Status
```
PUT /dispositions.php
Authorization: Bearer <token>
Content-Type: application/json

{
  "id": 1,
  "status": "in_progress",
  "notes": "Progress update..."
}
```

### 4. Share Document
```
PUT /documents.php
Authorization: Bearer <token>
Content-Type: application/json

{
  "id": 1,
  "visibility": "team",
  "share_with": [2, 3, 4]
}
```

---

## 📱 Flutter Import Reference

```dart
// Models
import 'package:si_manajemen_kampus/models/user_model.dart';
import 'package:si_manajemen_kampus/models/disposition_model.dart';
import 'package:si_manajemen_kampus/models/document_model.dart';

// Usage
User user = User.fromJson(jsonData);
Disposition dispo = Disposition.fromJson(jsonData);
Document doc = Document.fromJson(jsonData);

// Check role
if (user.isAdmin) { /* admin only */ }
if (user.isPimpinan) { /* pimpinan or admin */ }
if (user.hasLeadershipRole) { /* pimpinan or admin */ }
```

---

## ⚠️ Common Errors & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized | Missing/invalid token | Login & get new token |
| 403 Forbidden | Insufficient role | Use correct role account |
| 404 Not Found | Resource doesn't exist | Check ID |
| 409 Conflict | Duplicate (email/number) | Use unique value |
| 400 Bad Request | Invalid input | Check required fields |

---

## 🎯 Implementation Roadmap

**✅ Phase 1** (Complete)
- Database design
- Backend APIs
- Models

**⏳ Phase 2** (Next)
- Service classes
- Dashboard updates
- Feature screens

**⏳ Phase 3** (Future)
- Advanced features
- Optimization
- Mobile refinement

---

## 📚 Full Documentation

For complete details, see:
- **ROLE_BASED_SYSTEM_GUIDE.md** - Complete feature matrix
- **API_REFERENCE.md** - Full API docs
- **IMPLEMENTATION_STATUS.md** - Progress & roadmap

---

## 🆘 Quick Help

**Need to create a new admin?**
```
POST /users.php
Authorization: Bearer <admin_token>
{
  "name": "New Admin",
  "email": "newadmin@test.com",
  "password": "pass123",
  "role": "admin"
}
```

**Need to send disposition to multiple people?**
```
POST /dispositions.php
Authorization: Bearer <token>
{
  "letter_subject": "Subject",
  "recipient_ids": [2, 3, 5, 7]
}
```

**Need to check user permissions?**
```dart
if (currentUser.role == 'admin') {
  // Show admin features
} else if (currentUser.role == 'pimpinan') {
  // Show pimpinan features
} else {
  // Show user features
}
```

---

**Created**: April 24, 2026  
**Version**: 1.0.0  
**Status**: Production Ready ✅

