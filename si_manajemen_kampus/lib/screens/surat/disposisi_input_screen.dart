import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/disposition_service.dart';
import '../../shared/app_colors.dart';
import '../../shared/responsive_scaffold.dart';

class DisposisiInputScreen extends StatefulWidget {
  final String role;

  const DisposisiInputScreen({super.key, this.role = 'admin'});

  @override
  State<DisposisiInputScreen> createState() => _DisposisiInputScreenState();
}

class _DisposisiInputScreenState extends State<DisposisiInputScreen> {
  final TextEditingController _suratJudulController = TextEditingController();
  final TextEditingController _suratNomorController = TextEditingController();
  final TextEditingController _pengirimController = TextEditingController();
  final TextEditingController _perihalController = TextEditingController();
  final TextEditingController _disposisiIsiController = TextEditingController();

  DateTime _tanggalBuat = DateTime.now();
  DateTime _tanggalTerima = DateTime.now();
  String _tipeDocumen = 'Surat Tugas';
  PlatformFile? _selectedFile;

  List<User> _allUsers = [];
  final List<User> _selectedRecipients = [];
  User? _selectedUserForAdd;

  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _suratJudulController.dispose();
    _suratNomorController.dispose();
    _pengirimController.dispose();
    _perihalController.dispose();
    _disposisiIsiController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final result = await ApiService.getUsers(token);
      if (result['success']) {
        setState(() {
          _allUsers = result['users'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(bool isBuat) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isBuat ? _tanggalBuat : _tanggalTerima,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isBuat) {
          _tanggalBuat = picked;
        } else {
          _tanggalTerima = picked;
        }
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: ${e.toString()}')),
      );
    }
  }

  void _addRecipient() {
    if (_selectedUserForAdd != null) {
      setState(() {
        if (!_selectedRecipients.contains(_selectedUserForAdd)) {
          _selectedRecipients.add(_selectedUserForAdd!);
          _selectedUserForAdd = null;
        }
      });
    }
  }

  void _removeRecipient(User user) {
    setState(() {
      _selectedRecipients.remove(user);
    });
  }

  Future<void> _submitDisposition() async {
    if (_suratJudulController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul surat harus diisi')),
      );
      return;
    }

    if (_selectedRecipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu penerima disposisi')),
      );
      return;
    }

    if (_disposisiIsiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi disposisi harus diisi')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final docResult = await ApiService.createDocument(
        token: token,
        title: _suratJudulController.text.trim(),
        docType: _tipeDocumen,
        docDate: DateFormat('yyyy-MM-dd').format(_tanggalBuat),
        docTime: TimeOfDay.now().format(context),
        documentNumber: _suratNomorController.text.trim(),
        description: _perihalController.text.trim(),
        status: 'draft',
        visibility: 'private',
        file: _selectedFile,
      );

      if (!mounted) return;

      if (!docResult['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error membuat dokumen: ${docResult['message']}'),
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final documentId = docResult['data']?['id'] ?? 0;
      if (documentId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mendapatkan ID dokumen')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      for (final recipient in _selectedRecipients) {
        final dispositionResult = await DispositionService.createDisposition(
          token: token,
          documentId: documentId,
          recipientIds: [recipient.id],
          instruction: _disposisiIsiController.text.trim(),
        );

        if (!mounted) return;

        if (!dispositionResult['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${dispositionResult['message']}')),
          );
          setState(() => _isSubmitting = false);
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disposisi berhasil dibuat dan dikirim')),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveScaffold.isMobile(context);

    if (_isLoading) {
      return ResponsiveScaffold(
        role: widget.role,
        title: 'Input Disposisi Surat',
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return ResponsiveScaffold(
      role: widget.role,
      title: 'Input Disposisi Surat',
      child: Container(
        color: Colors.white,
        padding: ResponsiveScaffold.pagePadding(context),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isMobile: isMobile),
              const SizedBox(height: 40),
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection(),
                    const SizedBox(height: 24),
                    _buildSidePanel(),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildDetailSection()),
                    const SizedBox(width: 40),
                    SizedBox(
                      width: 280,
                      child: _buildSidePanel(),
                    ),
                  ],
                ),
              const SizedBox(height: 40),
              _sectionTitle("Isi Disposisi"),
              const Divider(),
              const SizedBox(height: 16),
              _buildDispositionContent(),
              const SizedBox(height: 40),
              _buildSaveButton(isMobile: isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required bool isMobile}) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Input Disposisi Surat",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textTealDark,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryPurple.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Batal", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Input Disposisi Surat",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textTealDark,
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryPurple.withValues(alpha: 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("Batal", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildDetailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Detail Dokumen"),
        const Divider(),
        const SizedBox(height: 20),
        _buildFormField("Judul Surat", _suratJudulController, Icons.title),
        const SizedBox(height: 16),
        _buildFormField("Nomor Surat", _suratNomorController, Icons.numbers),
        const SizedBox(height: 16),
        _buildDateField("Tanggal Surat Dibuat", _tanggalBuat, true),
        const SizedBox(height: 16),
        _buildDateField("Tanggal Surat Diterima", _tanggalTerima, false),
        const SizedBox(height: 16),
        _buildFormField("Pengiriman Surat", _pengirimController, Icons.person),
        const SizedBox(height: 16),
        _buildFormField("Perihal", _perihalController, Icons.assignment),
      ],
    );
  }

  Widget _buildSidePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTargetSection(),
        const SizedBox(height: 30),
        _buildDocumentTypeSection(),
        const SizedBox(height: 20),
        _buildUploadSection(),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textTealDark,
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.secondaryPurple),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const Text(" :", style: TextStyle(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime date, bool isBuat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: AppColors.secondaryPurple),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const Text(" :", style: TextStyle(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _selectDate(isBuat),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('dd MMMM yyyy').format(date),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group, size: 20, color: AppColors.secondaryPurple),
              const SizedBox(width: 8),
              const Text(
                "Tujuan Disposisi",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<User>(
              value: _selectedUserForAdd,
              hint: const Text("Pilih User", style: TextStyle(fontSize: 12)),
              isExpanded: true,
              underline: const SizedBox(),
              items:
                  _allUsers.map((user) {
                    return DropdownMenuItem<User>(
                      value: user,
                      child: Text(user.name, style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
              onChanged: (user) => setState(() => _selectedUserForAdd = user),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _addRecipient,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryPurple.withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const SizedBox(
              width: double.infinity,
              child: Text(
                "Tambahkan Tujuan",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedRecipients.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      _selectedRecipients.map((user) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgTeal,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    user.name,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _removeRecipient(user),
                                  child: const Icon(Icons.close, size: 16),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category, size: 20, color: AppColors.secondaryPurple),
            const SizedBox(width: 8),
            const Text(
              "Tipe Dokumen",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<String>(
            value: _tipeDocumen,
            isExpanded: true,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'Surat Tugas', child: Text('Surat Tugas')),
              DropdownMenuItem(
                value: 'Surat Keputusan',
                child: Text('Surat Keputusan'),
              ),
              DropdownMenuItem(
                value: 'Surat Personal',
                child: Text('Surat Personal'),
              ),
              DropdownMenuItem(value: 'Lain-lain', child: Text('Lain-lain')),
            ],
            onChanged:
                (value) =>
                    setState(() => _tipeDocumen = value ?? 'Surat Tugas'),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedFile != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedFile!.name,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _selectedFile = null),
                  child: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
          ),
        if (_selectedFile != null) const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file, color: Colors.white),
            label: const Text(
              "Upload Dokumen",
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryPurple.withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDispositionContent() {
    return TextField(
      controller: _disposisiIsiController,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: "Masukkan isi disposisi...",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildSaveButton({required bool isMobile}) {
    return SizedBox(
      width: isMobile ? double.infinity : 200,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitDisposition,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryPurple,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:
            _isSubmitting
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Text(
                  "Simpan",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }
}
