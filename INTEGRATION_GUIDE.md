# Dokumentasi Integrasi Agenda & Notifikasi

## Setup yang Sudah Dilakukan

### Database (Backend)
✅ Tabel `agendas` - untuk menyimpan data agenda
✅ Tabel `notifications` - untuk menyimpan data notifikasi

### API Endpoints (Backend)
✅ `POST /api/agenda.php` - Buat agenda baru
✅ `GET /api/agenda.php` - Fetch semua agenda user
✅ `PUT /api/agenda.php` - Update agenda
✅ `DELETE /api/agenda.php` - Hapus agenda

✅ `GET /api/notifications.php` - Fetch semua notifikasi user
✅ `POST /api/notifications.php` - Mark notifikasi sebagai dibaca
✅ `PUT /api/notifications.php` - Mark semua notifikasi sebagai dibaca

### Models (Frontend)
✅ `lib/models/agenda_model.dart` - Model untuk Agenda
✅ `lib/models/notification_model.dart` - Model untuk Notification

### Services (Frontend)
✅ `lib/services/api_service.dart` - Sudah ditambah methods untuk agenda dan notifikasi

---

## Cara Menggunakan

### 1. Fetch Agenda di Agenda Screen

```dart
import '../services/api_service.dart';
import '../models/agenda_model.dart';

class AgendaScreen extends StatefulWidget {
  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  List<Agenda> agendas = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAgendas();
  }

  void _loadAgendas() async {
    setState(() => isLoading = true);
    
    // Ambil token dari storage (sudah disimpan saat login)
    final token = 'YOUR_TOKEN_HERE'; // Ambil dari secure storage
    
    final result = await ApiService.getAgendas(token);
    
    if (result['success']) {
      setState(() {
        agendas = result['data'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
    
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // ... rest of your UI
  }
}
```

### 2. Create Agenda dari Agenda Add Screen

```dart
void _submitAgenda() async {
  final token = 'YOUR_TOKEN_HERE';
  
  final result = await ApiService.createAgenda(
    token: token,
    title: titleController.text,
    date: selectedDate.toString().split(' ')[0],
    timeStart: selectedTime.format(context),
    description: descriptionController.text,
    location: locationController.text,
    category: selectedCategory,
  );

  if (result['success']) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Agenda berhasil dibuat')),
    );
    Navigator.pop(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );
  }
}
```

### 3. Fetch Notifikasi di Notifikasi Screen

```dart
import '../services/api_service.dart';
import '../models/notification_model.dart';

class NotifikasiScreen extends StatefulWidget {
  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  List<Notification> notifications = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() async {
    setState(() => isLoading = true);
    
    final token = 'YOUR_TOKEN_HERE';
    final result = await ApiService.getNotifications(token: token);
    
    if (result['success']) {
      setState(() {
        notifications = result['data'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
    
    setState(() => isLoading = false);
  }

  void _markAsRead(int notificationId) async {
    final token = 'YOUR_TOKEN_HERE';
    final result = await ApiService.markNotificationAsRead(
      token: token,
      notificationId: notificationId,
    );
    
    if (result['success']) {
      _loadNotifications(); // Refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... rest of your UI
  }
}
```

---

## Token Management

⚠️ **PENTING**: Saat ini token hardcoded. Anda perlu:

1. **Simpan token setelah login** menggunakan `flutter_secure_storage`:
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = const FlutterSecureStorage();

// Setelah login berhasil:
await storage.write(key: 'auth_token', value: token);

// Saat menggunakan API:
final token = await storage.read(key: 'auth_token');
```

2. **Update pubspec.yaml** untuk tambah dependency:
```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
```

---

## Testing dengan Postman

### Get Agendas
```
GET http://localhost/SI%20manajemen%20kampus/backend/api/agenda.php
Headers:
  Authorization: Bearer <TOKEN_HERE>
  Content-Type: application/json
```

### Create Agenda
```
POST http://localhost/SI%20manajemen%20kampus/backend/api/agenda.php
Headers:
  Authorization: Bearer <TOKEN_HERE>
  Content-Type: application/json

Body:
{
  "title": "Rapat Penting",
  "description": "Diskusi project baru",
  "date": "2026-04-25",
  "time_start": "10:00:00",
  "time_end": "11:00:00",
  "location": "Ruang Meeting",
  "category": "meeting"
}
```

### Get Notifications
```
GET http://localhost/SI%20manajemen%20kampus/backend/api/notifications.php
Headers:
  Authorization: Bearer <TOKEN_HERE>
  Content-Type: application/json
```

### Mark Notification as Read
```
POST http://localhost/SI%20manajemen%20kampus/backend/api/notifications.php
Headers:
  Authorization: Bearer <TOKEN_HERE>
  Content-Type: application/json

Body:
{
  "id": 1,
  "is_read": true
}
```

---

## Next Steps

1. ✅ Update `agenda_screen.dart` dengan integration
2. ✅ Update `agenda_add_screen.dart` dengan create functionality
3. ✅ Update `notifikasi_screen.dart` dengan integration
4. ✅ Implement token storage menggunakan flutter_secure_storage
5. ✅ Update app_config.dart untuk API URL yang benar
6. ✅ Test semua endpoints dengan Postman sebelum testing di Flutter

---

## Sample Data

Ketika database di-import, sudah ada sample data:

**Agendas:**
- Rapat Rutin Pimpinan (2026-04-20 09:00-10:30)
- Meeting dengan Tim IT (2026-04-21 14:00-15:00)

**Notifications:**
- Notifikasi reminder untuk agenda hari ini
- Notifikasi agenda baru
