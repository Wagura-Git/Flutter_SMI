import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../shared/app_colors.dart';
import '../../shared/responsive_scaffold.dart';

class DisposisiCreateScreen extends StatefulWidget {
  final String role;

  const DisposisiCreateScreen({
    super.key,
    required this.role,
  });

  @override
  State<DisposisiCreateScreen> createState() => _DisposisiCreateScreenState();
}

class _DisposisiCreateScreenState extends State<DisposisiCreateScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedDocumentType;
  List<User> _availableUsers = [];
  User? _selectedRecipient;
  final List<User> _selectedRecipients = [];
  PlatformFile? _selectedFile;
  String _fileUploadStatus = "Belum ada file";
  bool _isSaving = false;

  final List<String> _documentTypes = [
    'Surat Keputusan',
    'Surat Tugas',
    'Surat Personal',
    'Lain-lain',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final token = await AuthService.getToken();
    if (token == null) return;

    final response = await ApiService.getUsers(token);
    if (response['success'] == true) {
      setState(() {
        _availableUsers = response['users'] as List<User>;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      _buildHeader(),
                      const SizedBox(height: 40),

                      // --- MAIN FORM ---
                      Container(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- TAMBAHKAN JUDUL DISINI ---
                            _buildTitleSection(),
                            const SizedBox(height: 30),

                            // --- DATE TIME SECTION ---
                            _buildDateTimeSection(),
                            const SizedBox(height: 40),

                            // --- DETAIL DOKUMEN ---
                            _buildDetailDokumenSection(),
                            const SizedBox(height: 40),

                            // --- RECIPIENTS SECTION ---
                            _buildRecipientsSection(),
                            const SizedBox(height: 40),

                            // --- DESKRIPSI DOKUMEN ---
                            _buildDescriptionSection(),
                            const SizedBox(height: 40),

                            // --- BUTTONS ---
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // Header Section
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Penambahan Dokumen",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textTealDark,
          ),
        ),
      ],
    );
  }

  // Title Input Section
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tambahkan Judul Disini",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textTealDark,
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: "Masukkan judul dokumen...",
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  // Date Time Section
  Widget _buildDateTimeSection() {
    String formattedDate = _selectedDate != null
        ? "${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)} ${_selectedDate!.year}"
        : "Pilih tanggal";
    String formattedTime = _selectedTime != null ? _selectedTime!.format(context) : "Pilih waktu";

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tanggal Dokumen :",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectDate,
                  child: Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Waktu :",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectTime,
                  child: Text(
                    formattedTime,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Detail Dokumen Section
  Widget _buildDetailDokumenSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Detail Dokumen",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textTealDark,
          ),
        ),
        const SizedBox(height: 15),
        const Divider(),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Jenis Dokumen",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDocumentType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: _documentTypes
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedDocumentType = value),
                    hint: const Text("Pilih jenis dokumen"),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Upload Dokumen",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _pickFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Upload Dokumen",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fileUploadStatus,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Recipients Section
  Widget _buildRecipientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Tujuan Dokumen",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textTealDark,
              ),
            ),
            Icon(
              Icons.group,
              color: AppColors.primaryPurple,
              size: 32,
            ),
          ],
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedRecipients
              .map((recipient) => Chip(
                    label: Text(recipient.name),
                    onDeleted: () {
                      setState(() => _selectedRecipients.remove(recipient));
                    },
                  ))
              .toList(),
        ),
        const SizedBox(height: 15),
        DropdownButtonFormField<User>(
          initialValue: _selectedRecipient,
          decoration: InputDecoration(
            labelText: "Pilih akun tujuan",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: _availableUsers
              .map((user) => DropdownMenuItem(
                    value: user,
                    child: Text(user.name),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _selectedRecipient = value),
          hint: const Text("Pilih akun tujuan"),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _selectedRecipient == null ? null : _addRecipient,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryPurple,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            "Tambahkan Tujuan",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  // Description Section
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Deskripsi Dokumen",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: "Tambahkan Deskripsi...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  // Action Buttons
  Widget _buildActionButtons() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveDisposisi,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryPurple,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                "Simpan",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // Helper Methods
  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xlsx', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    if (file.bytes == null) {
      setState(() => _fileUploadStatus = 'Gagal membaca file');
      return;
    }

    setState(() {
      _selectedFile = file;
      _fileUploadStatus = file.name;
    });
  }

  void _addRecipient() {
    if (_selectedRecipient == null) return;
    if (_selectedRecipients.any((user) => user.id == _selectedRecipient!.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun sudah ditambahkan sebagai tujuan')),
      );
      return;
    }

    setState(() {
      _selectedRecipients.add(_selectedRecipient!);
      _selectedRecipient = null;
    });
  }

  Future<void> _saveDisposisi() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul dokumen harus diisi")),
      );
      return;
    }

    if (_selectedDocumentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jenis dokumen harus dipilih")),
      );
      return;
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih file dokumen")),
      );
      return;
    }

    if (_selectedRecipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimal 1 tujuan harus dipilih")),
      );
      return;
    }

    final token = await AuthService.getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token tidak ditemukan')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    final uploadResult = await ApiService.uploadDocument(
      token: token,
      title: _titleController.text.trim(),
      documentType: _selectedDocumentType!,
      docDate: _selectedDate!.toIso8601String().split('T').first,
      docTime: '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00',
      description: _descriptionController.text.trim(),
      file: _selectedFile!,
    );

    if (uploadResult['success'] != true) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uploadResult['message'] ?? 'Gagal mengunggah dokumen')),
      );
      return;
    }

    final documentData = uploadResult['document'] as Map<String, dynamic>;
    final documentId = documentData['id'] as int;

    final dispositionResult = await ApiService.createDisposition(
      token: token,
      documentId: documentId,
      recipientIds: _selectedRecipients.map((user) => user.id).toList(),
      instruction: _descriptionController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (dispositionResult['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dispositionResult['message'] ?? 'Gagal menyimpan disposisi')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Disposisi berhasil disimpan")),
    );

    Navigator.pop(context);
  }
}
