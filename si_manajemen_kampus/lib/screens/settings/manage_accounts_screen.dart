import 'package:flutter/material.dart';
import '../../shared/app_colors.dart';
import '../../shared/responsive_scaffold.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'edit_account_screen.dart';

class ManageAccountsScreen extends StatefulWidget {
  final String role;

  const ManageAccountsScreen({
    super.key,
    required this.role,
  });

  @override
  State<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  List<User> _accounts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final token = await AuthService.getToken();
    if (token == null) {
      setState(() {
        _errorMessage = 'Token tidak ditemukan. Silakan login ulang.';
        _isLoading = false;
      });
      return;
    }

    final response = await ApiService.getUsers(token);
    if (response['success']) {
      setState(() {
        _accounts = response['users'] as List<User>;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response['message'] ?? 'Gagal mengambil daftar akun.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      role: widget.role,
      child: Container(
        color: Colors.white,
        padding: ResponsiveScaffold.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Kelola Akun,",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textTealDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.role,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textTealLight,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? Center(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                            : _accounts.isEmpty
                                ? const Center(
                                    child: Text('Belum ada akun terdaftar.'),
                                  )
                                : SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        _buildTableHeader(),
                                        ..._accounts.asMap().entries.map((entry) {
                                          int index = entry.key + 1;
                                          User account = entry.value;
                                          return _buildTableRow(index, account);
                                        }),
                                      ],
                                    ),
                                  ),
                  ),
                ],
              ),
      ),
    );
  }

  // Header Tabel
  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _cellHeader("No", flex: 1),
          _cellHeader("Nama Akun", flex: 4),
          _cellHeader("NIK", flex: 2),
          _cellHeader("Jabatan", flex: 2),
          _cellHeader("Aksi", flex: 2),
        ],
      ),
    );
  }

  // Fungsi pembantu untuk header tabel
  Widget _cellHeader(String title, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Baris Data Tabel
  Widget _buildTableRow(int no, User account) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              no.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              account.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              account.nik ?? '-',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              account.jabatan ?? '-',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _showDeleteConfirmation(account.id, account.name),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _navigateToEdit(account),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: Colors.blue,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(User account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAccountScreen(
          role: widget.role,
          accountId: account.id,
          accountData: account.toJson(),
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadAccounts(); // Refresh data jika berhasil diupdate
      }
    });
  }

  void _showDeleteConfirmation(int accountId, String accountName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: Text("Apakah Anda yakin ingin menghapus akun '$accountName'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              _deleteAccount(accountId);
              Navigator.pop(context);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(int accountId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token tidak ditemukan. Silakan login ulang.")),
      );
      return;
    }

    final response = await ApiService.deleteUser(token: token, id: accountId);
    if (response['success']) {
      setState(() {
        _accounts.removeWhere((account) => account.id == accountId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Akun berhasil dihapus")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? "Gagal menghapus akun")),
      );
    }
  }
}
