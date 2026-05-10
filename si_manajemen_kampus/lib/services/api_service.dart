import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/agenda_model.dart';
import '../models/notification_model.dart';
import '../config/app_config.dart';

class ApiService {
  // Get base URL dari configuration
  static String get baseUrl => AppConfig.getApiUrl();

  static const Duration timeoutDuration = Duration(seconds: 30);

  /// Test API connectivity
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      print('DEBUG: Testing API connectivity at: $baseUrl/test.php');

      final response = await http
          .get(
            Uri.parse('$baseUrl/test.php'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeoutDuration);

      print('DEBUG: Test response status: ${response.statusCode}');
      print('DEBUG: Test response body: ${response.body}');

      final responseData = jsonDecode(response.body);
      return {
        'success': true,
        'message': 'API connection successful',
        'data': responseData,
      };
    } catch (e) {
      print('DEBUG: Connection test failed: ${e.toString()}');
      return {
        'success': false,
        'message': 'API connection failed: ${e.toString()}',
      };
    }
  }

  /// Login dengan email dan password
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('DEBUG: Attempting login for email: $email');
      print('DEBUG: API URL: $baseUrl/login.php');

      final response = await http
          .post(
            Uri.parse('$baseUrl/login.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(timeoutDuration);

      print('DEBUG: Login response status: ${response.statusCode}');
      print('DEBUG: Login response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        print('DEBUG: Login successful for user: $email');
        return {
          'success': true,
          'message': responseData['message'],
          'token': responseData['data']['token'],
          'user': User.fromJson(responseData['data']['user']),
        };
      } else {
        print('DEBUG: Login failed with message: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login gagal',
        };
      }
    } on http.ClientException catch (e) {
      print('DEBUG: Login ClientException: ${e.message}');
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      print('DEBUG: Login Exception: ${e.toString()}');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Registrasi user baru
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirm,
    String role = 'user',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'password_confirm': passwordConfirm,
              'role': role,
            }),
          )
          .timeout(timeoutDuration);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success']) {
        return {
          'success': true,
          'message': responseData['message'],
          'token': responseData['data']['token'],
          'user': User.fromJson(responseData['data']['user']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registrasi gagal',
        };
      }
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Verifikasi token
  static Future<Map<String, dynamic>> verifyToken(String token) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/verify_token.php'),
            headers: _authHeaders(token),
          )
          .timeout(timeoutDuration);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        return {
          'success': true,
          'message': responseData['message'],
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Token verification gagal',
        };
      }
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Headers untuk request yang memerlukan token
  static Map<String, String> _authHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Dapatkan semua user (admin only)
  static Future<Map<String, dynamic>> getUsers(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/users.php'),
            headers: _authHeaders(token),
          )
          .timeout(timeoutDuration);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        final users = (responseData['data'] as List)
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
        return {
          'success': true,
          'message': responseData['message'],
          'users': users,
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Gagal mengambil daftar user',
      };
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Search users by name or email
  static Future<Map<String, dynamic>> searchUsers({
    required String token,
    required String query,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/users.php?search=$query'),
            headers: _authHeaders(token),
          )
          .timeout(timeoutDuration);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        final users = (responseData['data'] as List)
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
        return {
          'success': true,
          'message': responseData['message'],
          'users': users,
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Gagal mencari user',
      };
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Upload dokumen ke server
  static Future<Map<String, dynamic>> uploadDocument({
    required String token,
    required String title,
    required String documentType,
    required String docDate,
    required String docTime,
    String? description,
    required PlatformFile file,
  }) async {
    try {
      final fileBytes = file.bytes;
      if (fileBytes == null || fileBytes.isEmpty) {
        return {
          'success': false,
          'message': 'File tidak dapat dibaca. Silakan pilih file kembali.',
        };
      }

      final uri = Uri.parse('$baseUrl/documents.php');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({'Authorization': 'Bearer $token'});
      request.fields['title'] = title;
      request.fields['doc_type'] = documentType;
      request.fields['doc_date'] = docDate;
      request.fields['doc_time'] = docTime;
      if (description != null) request.fields['description'] = description;

      final multipartFile = http.MultipartFile.fromBytes(
        'document_file',
        fileBytes,
        filename: file.name,
      );

      request.files.add(multipartFile);
      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success']) {
        return {
          'success': true,
          'message': responseData['message'],
          'document': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Gagal mengunggah dokumen',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Buat disposisi baru
  static Future<Map<String, dynamic>> createDisposition({
    required String token,
    required int documentId,
    required List<int> recipientIds,
    required String instruction,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/dispositions.php'),
            headers: _authHeaders(token),
            body: jsonEncode({
              'document_id': documentId,
              'recipient_ids': recipientIds,
              'instruction': instruction,
            }),
          )
          .timeout(timeoutDuration);

      final responseData = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && responseData['success']) {
        return {
          'success': true,
          'message': responseData['message'],
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Gagal membuat disposisi',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Tambah user baru
  static Future<Map<String, dynamic>> createUser({
    required String token,
    required String name,
    required String email,
    required String password,
    required String role,
    String? nik,
    String? jabatan,
    String? phone,
    String? address,
    String? department,
    String? position,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users.php'),
            headers: _authHeaders(token),
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'role': role,
              'nik': nik,
              'jabatan': jabatan,
              'phone': phone,
              'address': address,
              'department': department,
              'position': position,
            }),
          )
          .timeout(timeoutDuration);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success']) {
        return {
          'success': true,
          'message': responseData['message'],
          'user': User.fromJson(responseData['data'] as Map<String, dynamic>),
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Gagal menambahkan user',
      };
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Update user data
  static Future<Map<String, dynamic>> updateUser({
    required String token,
    required int id,
    String? name,
    String? email,
    String? password,
    String? role,
    String? status,
    String? nik,
    String? jabatan,
    String? phone,
    String? address,
    String? department,
    String? position,
  }) async {
    try {
      final body = <String, dynamic>{'id': id};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (password != null) body['password'] = password;
      if (role != null) body['role'] = role;
      if (status != null) body['status'] = status;
      if (nik != null) body['nik'] = nik;
      if (jabatan != null) body['jabatan'] = jabatan;
      if (phone != null) body['phone'] = phone;
      if (address != null) body['address'] = address;
      if (department != null) body['department'] = department;
      if (position != null) body['position'] = position;

      final response = await http
          .put(
            Uri.parse('$baseUrl/users.php'),
            headers: _authHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        return {
          'success': true,
          'message': responseData['message'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Gagal memperbarui user',
      };
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Hapus user
  static Future<Map<String, dynamic>> deleteUser({
    required String token,
    required int id,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/users.php'),
            headers: _authHeaders(token),
            body: jsonEncode({'id': id}),
          )
          .timeout(timeoutDuration);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        return {
          'success': true,
          'message': responseData['message'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Gagal menghapus user',
      };
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Set base URL (untuk testing atau multiple environments)
  static void setBaseUrl(String url) {
    // Anda bisa menggunakan static variable atau environment configuration
    // Ini adalah contoh sederhana
  }

  // ============ AGENDA METHODS ============

  /// Debug: Test Authorization header
  static Future<Map<String, dynamic>> debugHeaders(String token) async {
    try {
      print(
        'DEBUG: Testing Authorization Header at: $baseUrl/debug_headers.php',
      );

      final response = await http
          .get(
            Uri.parse('$baseUrl/debug_headers.php'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(timeoutDuration);

      print('DEBUG: Header test response status: ${response.statusCode}');
      print('DEBUG: Header test response body: ${response.body}');

      return {
        'success': response.statusCode == 200,
        'message': 'Header test completed',
        'data': response.body,
      };
    } catch (e) {
      print('DEBUG: Header test failed: ${e.toString()}');
      return {
        'success': false,
        'message': 'Header test error: ${e.toString()}',
      };
    }
  }

  /// Fetch semua agenda user
  static Future<Map<String, dynamic>> getAgendas(String token) async {
    try {
      print('DEBUG: Fetching agendas from: $baseUrl/agenda.php');
      print('DEBUG: Token: ${token.substring(0, 20)}...');

      final response = await http
          .get(
            Uri.parse('$baseUrl/agenda.php'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(timeoutDuration);

      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        final agendas =
            (responseData['data'] as List)
                .map((agenda) => Agenda.fromJson(agenda))
                .toList();
        print('DEBUG: Successfully fetched ${agendas.length} agendas');
        return {
          'success': true,
          'message': responseData['message'],
          'data': agendas,
        };
      } else {
        print('DEBUG: Error response: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal fetch agenda',
        };
      }
    } on http.ClientException catch (e) {
      print('DEBUG: ClientException: ${e.message}');
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      print('DEBUG: Exception: ${e.toString()}');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Upload dokumen untuk agenda
  static Future<Map<String, dynamic>> uploadAgendaDocument({
    required String token,
    required PlatformFile file,
  }) async {
    try {
      final fileBytes = file.bytes;
      if (fileBytes == null || fileBytes.isEmpty) {
        return {
          'success': false,
          'message': 'File tidak dapat dibaca. Silakan pilih file kembali.',
        };
      }

      final uri = Uri.parse('$baseUrl/upload_agenda_document.php');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({'Authorization': 'Bearer $token'});

      final multipartFile = http.MultipartFile.fromBytes(
        'document',
        fileBytes,
        filename: file.name,
      );

      request.files.add(multipartFile);
      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        return {
          'success': true,
          'message': responseData['message'],
          'file_path': responseData['data']['file_path'],
          'original_name': responseData['data']['original_name'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Gagal mengunggah dokumen',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Buat agenda baru
  static Future<Map<String, dynamic>> createAgenda({
    required String token,
    required String title,
    required String date,
    required String timeStart,
    String? description,
    String? timeEnd,
    String? location,
    String? category,
    String? agendaType = 'pribadi',
    List<int>? recipientUserIds,
    String? notifValue,
    String? notifUnit,
    String? attachmentPath,
  }) async {
    try {
      final body = {
        'title': title,
        'description': description,
        'date_start': date,
        'time_start': timeStart,
        'time_end': timeEnd,
        'location': location,
        'category': category,
        'agenda_type': agendaType,
        'notif_value': notifValue ?? '30',
        'notif_unit': notifUnit ?? 'Menit',
        if (attachmentPath != null) 'attachment_path': attachmentPath,
        if (recipientUserIds != null && recipientUserIds.isNotEmpty)
          'invitations': recipientUserIds,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/agenda.php'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration);

      final responseBody = response.body.trim();
      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 201 && responseData['success']) {
        return {
          'success': true,
          'message': responseData['message'],
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal buat agenda',
        };
      }
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } on FormatException {
      return {
        'success': false,
        'message':
            'Server mengembalikan respons yang tidak valid saat menyimpan agenda',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Update agenda
  static Future<Map<String, dynamic>> updateAgenda({
    required String token,
    required int agendaId,
    String? title,
    String? description,
    String? date,
    String? timeStart,
    String? timeEnd,
    String? location,
    String? category,
    String? status,
  }) async {
    try {
      final body = <String, dynamic>{'id': agendaId};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (date != null) body['date_start'] = date;
      if (timeStart != null) body['time_start'] = timeStart;
      if (timeEnd != null) body['time_end'] = timeEnd;
      if (location != null) body['location'] = location;
      if (category != null) body['category'] = category;
      if (status != null) body['status'] = status;

      final response = await http
          .put(
            Uri.parse('$baseUrl/agenda.php'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal update agenda',
        };
      }
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Hapus agenda
  static Future<Map<String, dynamic>> deleteAgenda({
    required String token,
    required int agendaId,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/agenda.php'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'id': agendaId}),
          )
          .timeout(timeoutDuration);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal hapus agenda',
        };
      }
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ============ NOTIFICATION METHODS ============

  /// Fetch semua notifikasi user
  static Future<Map<String, dynamic>> getNotifications({
    required String token,
    bool? isRead,
  }) async {
    try {
      String url = '$baseUrl/notifications.php';
      if (isRead != null) {
        url += '?is_read=${isRead.toString()}';
      }

      print('DEBUG: Fetching notifications from: $url');
      print('DEBUG: Token: ${token.substring(0, 20)}...');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(timeoutDuration);

      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        final notifications =
            (responseData['data'] as List)
                .map((notif) => Notification.fromJson(notif))
                .toList();
        print(
          'DEBUG: Successfully fetched ${notifications.length} notifications',
        );
        return {
          'success': true,
          'message': responseData['message'],
          'data': notifications,
        };
      } else {
        print('DEBUG: Error response: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal fetch notifikasi',
        };
      }
    } on http.ClientException catch (e) {
      print('DEBUG: ClientException: ${e.message}');
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      print('DEBUG: Exception: ${e.toString()}');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Mark notifikasi sebagai sudah dibaca
  static Future<Map<String, dynamic>> markNotificationAsRead({
    required String token,
    required int notificationId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/notifications.php'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'id': notificationId, 'is_read': true}),
          )
          .timeout(timeoutDuration);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal update notifikasi',
        };
      }
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Mark semua notifikasi sebagai sudah dibaca
  static Future<Map<String, dynamic>> markAllNotificationsAsRead(
    String token,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/notifications.php'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(timeoutDuration);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal update notifikasi',
        };
      }
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Dapatkan semua dokumen
  static Future<Map<String, dynamic>> getDocuments(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/documents.php'),
            headers: _authHeaders(token),
          )
          .timeout(timeoutDuration);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        return {
          'success': true,
          'message': responseData['message'],
          'documents': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Gagal mengambil daftar dokumen',
      };
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Buat dokumen baru
  static Future<Map<String, dynamic>> createDocument({
    required String token,
    required String title,
    required String docType,
    required String docDate,
    String? docTime,
    String? documentNumber,
    String? description,
    String? status,
    String? visibility,
    PlatformFile? file,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/documents.php');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({'Authorization': 'Bearer $token'})
        ..fields['title'] = title
        ..fields['doc_type'] = docType
        ..fields['doc_date'] = docDate;

      if (docTime != null) request.fields['doc_time'] = docTime;
      if (documentNumber != null) request.fields['document_number'] = documentNumber;
      if (description != null) request.fields['description'] = description;
      if (status != null) request.fields['status'] = status;
      if (visibility != null) request.fields['visibility'] = visibility;

      if (file != null) {
        final fileBytes = file.bytes;
        if (fileBytes == null || fileBytes.isEmpty) {
          return {
            'success': false,
            'message': 'File tidak dapat dibaca. Silakan pilih file kembali.',
          };
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'document_file',
            fileBytes,
            filename: file.name,
          ),
        );
      }

      final response = await request.send().timeout(timeoutDuration);
      final responseBody = await response.stream.bytesToString();
      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 201 && responseData['success']) {
        return {
          'success': true,
          'message': responseData['message'],
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Gagal membuat dokumen',
      };
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Download file dokumen
  static String getFileDownloadUrl(String token, String filePath) {
    return '$baseUrl/download.php?path=${Uri.encodeComponent(filePath)}&token=$token';
  }

  /// Get file preview URL untuk dibuka inline di browser
  static String getFilePreviewUrl(String token, String filePath) {
    return '$baseUrl/download.php?path=${Uri.encodeComponent(filePath)}&token=$token&mode=inline';
  }

  /// Get file preview/view URL
  static Future<bool> canAccessFile(String token, String filePath) async {
    try {
      final response = await http
          .head(
            Uri.parse('$baseUrl/download.php?path=${Uri.encodeComponent(filePath)}'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Download dokumen agenda
  static Future<Map<String, dynamic>> downloadAgendaDocument({
    required String token,
    required String filePath,
  }) async {
    try {
      final url = '$baseUrl/download.php?path=${Uri.encodeComponent(filePath)}';
      final response = await http
          .get(
            Uri.parse(url),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'file': response.bodyBytes,
          'fileName': filePath.split('/').last,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Gagal download file',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Ambil detail agenda berdasarkan ID
  static Future<Map<String, dynamic>> getAgendaById({
    required String token,
    required int agendaId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/agenda.php?id=$agendaId'),
            headers: _authHeaders(token),
          )
          .timeout(timeoutDuration);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        return {
          'success': true,
          'message': responseData['message'],
          'data': Agenda.fromJson(responseData['data'] as Map<String, dynamic>),
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Gagal mengambil detail agenda',
      };
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
