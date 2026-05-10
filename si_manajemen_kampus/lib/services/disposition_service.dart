import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/disposition_model.dart';
import '../config/app_config.dart';

class DispositionService {
  static String get baseUrl => AppConfig.getApiUrl();
  static const Duration timeoutDuration = Duration(seconds: 30);

  /// Headers untuk request yang memerlukan token
  static Map<String, String> _authHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Dapatkan semua disposisi (sesuai dengan role)
  /// - Admin: melihat semua disposisi
  /// - Pimpinan/User: melihat disposisi yang dibuat atau dikirimkan kepada mereka
  static Future<Map<String, dynamic>> getDispositions(String token) async {
    try {
      print('DEBUG: Fetching dispositions from: $baseUrl/dispositions.php');

      final response = await http
          .get(
            Uri.parse('$baseUrl/dispositions.php'),
            headers: _authHeaders(token),
          )
          .timeout(timeoutDuration);

      print('DEBUG: Get dispositions response status: ${response.statusCode}');
      print('DEBUG: Get dispositions response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        final dispositions = (responseData['data'] as List)
            .map((json) => Disposition.fromJson(json as Map<String, dynamic>))
            .toList();
        
        return {
          'success': true,
          'message': responseData['message'],
          'dispositions': dispositions,
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Gagal mengambil daftar disposisi',
        'dispositions': <Disposition>[],
      };
    } on http.ClientException catch (e) {
      print('DEBUG: Get dispositions ClientException: ${e.message}');
      return {
        'success': false,
        'message': 'Koneksi error: ${e.message}',
        'dispositions': <Disposition>[],
      };
    } catch (e) {
      print('DEBUG: Get dispositions Exception: ${e.toString()}');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'dispositions': <Disposition>[],
      };
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
      print('DEBUG: Creating disposition with recipients: $recipientIds');

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

      print('DEBUG: Create disposition response status: ${response.statusCode}');
      print('DEBUG: Create disposition response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          responseData['success']) {
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
    } on http.ClientException catch (e) {
      print('DEBUG: Create disposition ClientException: ${e.message}');
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      print('DEBUG: Create disposition Exception: ${e.toString()}');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Update disposisi dengan status dan/atau balasan
  static Future<Map<String, dynamic>> updateDisposition({
    required String token,
    required int dispositionId,
    String? status,
    String? replyInstruction,
  }) async {
    try {
      print('DEBUG: Updating disposition $dispositionId - status: $status, reply: $replyInstruction');

      final Map<String, dynamic> body = {
        'id': dispositionId,
      };
      if (status != null) body['status'] = status;
      if (replyInstruction != null) body['reply_instruction'] = replyInstruction;

      final response = await http
          .put(
            Uri.parse('$baseUrl/dispositions.php'),
            headers: _authHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration);

      print('DEBUG: Update disposition response status: ${response.statusCode}');
      print('DEBUG: Update disposition response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        final updatedDisposition = Disposition.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
        return {
          'success': true,
          'message': responseData['message'],
          'disposition': updatedDisposition,
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Gagal mengupdate disposisi',
      };
    } on http.ClientException catch (e) {
      print('DEBUG: Update disposition ClientException: ${e.message}');
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      print('DEBUG: Update disposition Exception: ${e.toString()}');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Hapus disposisi (admin only)
  static Future<Map<String, dynamic>> deleteDisposition({
    required String token,
    required int dispositionId,
  }) async {
    try {
      print('DEBUG: Deleting disposition $dispositionId');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/dispositions.php?id=$dispositionId'),
            headers: _authHeaders(token),
          )
          .timeout(timeoutDuration);

      print('DEBUG: Delete disposition response status: ${response.statusCode}');
      print('DEBUG: Delete disposition response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        return {
          'success': true,
          'message': responseData['message'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'Gagal menghapus disposisi',
      };
    } on http.ClientException catch (e) {
      print('DEBUG: Delete disposition ClientException: ${e.message}');
      return {'success': false, 'message': 'Koneksi error: ${e.message}'};
    } catch (e) {
      print('DEBUG: Delete disposition Exception: ${e.toString()}');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
