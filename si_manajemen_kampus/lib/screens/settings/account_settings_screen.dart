import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../shared/app_colors.dart';
import '../../shared/responsive_scaffold.dart';
import 'add_account_screen.dart';
import 'edit_account_screen.dart';
import 'manage_accounts_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  final String role;

  const AccountSettingsScreen({
    super.key,
    required this.role,
  });

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final rawData = await AuthService.getUserData();
      if (!mounted) return;

      if (rawData == null || rawData.isEmpty) {
        setState(() {
          _currentUser = null;
          _errorMessage = 'Data pengguna tidak ditemukan. Silakan login ulang.';
          _isLoading = false;
        });
        return;
      }

      final decodedData = jsonDecode(rawData);
      if (decodedData is! Map<String, dynamic>) {
        throw const FormatException('Format data pengguna tidak valid');
      }

      setState(() {
        _currentUser = decodedData;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentUser = null;
        _errorMessage = 'Data pengguna tidak valid. Silakan logout lalu login kembali.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveScaffold.isMobile(context);
    final isAdmin = widget.role.toLowerCase() == 'admin';

    return ResponsiveScaffold(
      role: widget.role,
      title: 'Pengaturan Akun',
      child: Container(
        color: Colors.white,
        padding: ResponsiveScaffold.pagePadding(context),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pengaturan Akun,",
                        style: TextStyle(
                          fontSize: isMobile ? 28 : 40,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textTealDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.role,
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: AppColors.textTealLight,
                        ),
                      ),
                      SizedBox(height: isMobile ? 32 : 60),
                      if (isAdmin)
                        isMobile
                            ? Column(
                              children: [
                                _buildMenuButton(
                                  "Penambahan Akun",
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AddAccountScreen(
                                            role: widget.role,
                                          ),
                                    ),
                                  ),
                                  isMobile: true,
                                ),
                                const SizedBox(height: 16),
                                _buildMenuButton(
                                  "Kelola Akun",
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ManageAccountsScreen(
                                            role: widget.role,
                                          ),
                                    ),
                                  ),
                                  isMobile: true,
                                ),
                              ],
                            )
                            : Row(
                              children: [
                                _buildMenuButton(
                                  "Penambahan Akun",
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AddAccountScreen(
                                            role: widget.role,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 30),
                                _buildMenuButton(
                                  "Kelola Akun",
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ManageAccountsScreen(
                                            role: widget.role,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_errorMessage != null) ...[
                              _buildErrorMessage(_errorMessage!),
                              const SizedBox(height: 24),
                            ],
                            Text(
                              "Halaman ini hanya untuk mengelola informasi akun pribadi Anda.",
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                color: AppColors.textTealLight,
                              ),
                            ),
                            const SizedBox(height: 40),
                            _buildMenuButton(
                              "Edit Profil Saya",
                              _currentUser == null
                                  ? null
                                  : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => EditAccountScreen(
                                              role: widget.role,
                                              accountId: _currentUserId,
                                              accountData: _currentUser,
                                            ),
                                      ),
                                    );
                                  },
                              isMobile: isMobile,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
      ),
    );
  }

  int? get _currentUserId {
    final id = _currentUser?['id'];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? '');
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    String title,
    VoidCallback? onTap, {
    bool isMobile = false,
  }) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: isMobile ? 28 : 50),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.shade400 : const Color(0xFF001663),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );

    if (isMobile) {
      return button;
    }

    return Expanded(child: button);
  }
}
