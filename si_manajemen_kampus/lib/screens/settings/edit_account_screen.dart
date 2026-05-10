import 'package:flutter/material.dart';
import '../../shared/app_colors.dart';
import '../../shared/responsive_scaffold.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class EditAccountScreen extends StatefulWidget {
  final String role;
  final int? accountId;
  final Map<String, dynamic>? accountData;

  const EditAccountScreen({
    super.key,
    required this.role,
    this.accountId,
    this.accountData,
  });

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nipController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedRole;
  String? _selectedPosition;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _roles = ['admin', 'pimpinan', 'user'];
  static const List<String> _defaultPositions = [
    'Admin Sistem',
    'Dekan',
    'Wakil Dekan BARPM',
    'Wakil Dekan BSKOP',
    'Wakil Dekan BKKM',
    'Kaprodi',
    'KPK',
    'GKM',
    'KTU',
    'Ka. Subag',
    'Dosen',
    'Staff',
  ];

  List<String> get _positionOptions => _buildDropdownItems(
    _defaultPositions,
    _selectedPosition,
  );

  @override
  void initState() {
    super.initState();
    _loadAccountData();
  }

  void _loadAccountData() {
    if (widget.accountData != null) {
      _nameController.text = widget.accountData!['name'] ?? '';
      _nipController.text = widget.accountData!['nik'] ?? '';
      _phoneController.text = widget.accountData!['phone'] ?? '';
      _emailController.text = widget.accountData!['email'] ?? '';
      _selectedRole = _normalizeDropdownValue(
        widget.accountData!['role']?.toString(),
        _roles,
      );
      _selectedPosition = _normalizeDropdownValue(
        (widget.accountData!['jabatan'] ?? widget.accountData!['position'])
            ?.toString(),
        _defaultPositions,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nipController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveScaffold.isMobile(context);

    return ResponsiveScaffold(
      role: widget.role,
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Padding(
            padding: ResponsiveScaffold.pagePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER ---
                      Text(
                        "Edit Akun,",
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
                      const SizedBox(height: 40),

                      // --- FORM ---
                      Container(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Row 1: Nama Lengkap & Role
                              _buildResponsiveFieldRow(
                                isMobile: isMobile,
                                first: _buildTextField(
                                      label: "Nama Lengkap",
                                      controller: _nameController,
                                      hint: "Masukkan nama lengkap",
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Nama tidak boleh kosong";
                                        }
                                        return null;
                                      },
                                    ),
                                second: _buildDropdownField(
                                      label: "Role/Hiraki Akun",
                                      value: _selectedRole,
                                      items: _roles,
                                      enabled: widget.role.toLowerCase() == 'admin',
                                      onChanged: (value) {
                                        setState(() => _selectedRole = value);
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Role harus dipilih";
                                        }
                                        return null;
                                      },
                                    ),
                              ),
                              const SizedBox(height: 25),

                              // Row 2: NIP & Password
                              _buildResponsiveFieldRow(
                                isMobile: isMobile,
                                first: _buildTextField(
                                      label: "Nomor Induk Kepegawaian",
                                      controller: _nipController,
                                      hint: "Masukkan NIP",
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "NIP tidak boleh kosong";
                                        }
                                        return null;
                                      },
                                    ),
                                second: _buildPasswordField(
                                      label: "Input Password",
                                      controller: _passwordController,
                                      obscure: _obscurePassword,
                                      onToggle: () {
                                        setState(
                                          () => _obscurePassword = !_obscurePassword,
                                        );
                                      },
                                      hint: "(Kosongkan jika tidak ingin mengubah)",
                                    ),
                              ),
                              const SizedBox(height: 25),

                              // Row 3: Jabatan & Ulangi Password
                              _buildResponsiveFieldRow(
                                isMobile: isMobile,
                                first: _buildDropdownField(
                                      label: "Jabatan",
                                      value: _selectedPosition,
                                      items: _positionOptions,
                                      onChanged: (value) {
                                        setState(() => _selectedPosition = value);
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Jabatan harus dipilih";
                                        }
                                        return null;
                                      },
                                    ),
                                second: _buildPasswordField(
                                      label: "Ulangi Input Password",
                                      controller: _confirmPasswordController,
                                      obscure: _obscureConfirmPassword,
                                      onToggle: () {
                                        setState(
                                          () =>
                                              _obscureConfirmPassword =
                                              !_obscureConfirmPassword,
                                        );
                                      },
                                      hint: "(Kosongkan jika tidak ingin mengubah)",
                                    ),
                              ),
                              const SizedBox(height: 25),

                              // Row 4: No. Whatsapp & Email
                              _buildResponsiveFieldRow(
                                isMobile: isMobile,
                                first: _buildTextField(
                                      label: "No. Whatsapp",
                                      controller: _phoneController,
                                      hint: "Masukkan nomor whatsapp",
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "No. Whatsapp tidak boleh kosong";
                                        }
                                        return null;
                                      },
                                    ),
                                second: _buildTextField(
                                      label: "Email",
                                      controller: _emailController,
                                      hint: "Masukkan email",
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Email tidak boleh kosong";
                                        }
                                        if (!value.contains('@')) {
                                          return "Email tidak valid";
                                        }
                                        return null;
                                      },
                                    ),
                              ),
                              const SizedBox(height: 40),

                              // Button Simpan Perubahan
                              Align(
                                alignment: Alignment.bottomRight,
                                child: ElevatedButton(
                                  onPressed: _updateAccount,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF001663),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 50,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    "Simpan Perubahan",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveFieldRow({
    required bool isMobile,
    required Widget first,
    required Widget second,
  }) {
    if (isMobile) {
      return Column(
        children: [
          first,
          const SizedBox(height: 18),
          second,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 30),
        Expanded(child: second),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String? Function(String?) validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: enabled ? onChanged : null,
          validator: enabled ? validator : (_) => null,
          disabledHint: Text(value ?? ''),
        ),
      ],
    );
  }

  List<String> _buildDropdownItems(List<String> defaults, String? selectedValue) {
    final values = <String>[];

    for (final item in defaults) {
      final normalizedItem = item.trim();
      if (normalizedItem.isNotEmpty && !values.contains(normalizedItem)) {
        values.add(normalizedItem);
      }
    }

    final normalizedSelectedValue = selectedValue?.trim();
    if (normalizedSelectedValue != null &&
        normalizedSelectedValue.isNotEmpty &&
        !values.contains(normalizedSelectedValue)) {
      values.insert(0, normalizedSelectedValue);
    }

    return values;
  }

  String? _normalizeDropdownValue(String? value, List<String> defaults) {
    final normalizedValue = value?.trim();
    if (normalizedValue == null || normalizedValue.isEmpty) {
      return null;
    }

    for (final item in defaults) {
      if (item.toLowerCase() == normalizedValue.toLowerCase()) {
        return item;
      }
    }

    return normalizedValue;
  }

  Future<void> _updateAccount() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ID akun tidak ditemukan.")),
      );
      return;
    }

    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password konfirmasi tidak cocok.")),
      );
      return;
    }

    final token = await AuthService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token tidak ditemukan. Silakan login ulang.")),
      );
      return;
    }

    final isAdmin = widget.role.toLowerCase() == 'admin';
    final response = await ApiService.updateUser(
      token: token,
      id: widget.accountId!,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
      role: isAdmin ? _selectedRole : null,
      nik: _nipController.text.trim(),
      jabatan: _selectedPosition,
      phone: _phoneController.text.trim(),
      address: null,
      department: null,
      position: _selectedPosition,
    );

    if (response['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Akun berhasil diperbarui")),
        );
        Navigator.pop(context, true); // Kembali dengan indikasi berhasil
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Gagal memperbarui akun")),
        );
      }
    }
  }
}
