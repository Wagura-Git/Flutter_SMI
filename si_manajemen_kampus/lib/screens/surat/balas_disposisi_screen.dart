import 'package:flutter/material.dart';
import '../../shared/app_colors.dart';
import '../../shared/responsive_scaffold.dart';
import '../../models/disposition_model.dart';
import '../../services/disposition_service.dart';
import '../../services/auth_service.dart';

class BalasDisposisiScreen extends StatefulWidget {
  final Disposition parentDisposition;
  final String role;

  const BalasDisposisiScreen({
    super.key,
    required this.parentDisposition,
    required this.role,
  });

  @override
  State<BalasDisposisiScreen> createState() => _BalasDisposisiScreenState();
}

class _BalasDisposisiScreenState extends State<BalasDisposisiScreen> {
  late TextEditingController _descriptionController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deskripsi tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token tidak ditemukan')),
        );
        return;
      }

      final result = await DispositionService.updateDisposition(
        token: token,
        dispositionId: widget.parentDisposition.id,
        status: 'processed',
        replyInstruction: _descriptionController.text.trim(),
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Balas disposisi berhasil')),
        );
        Navigator.pop(context, result['disposition']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal membalas disposisi')),
        );
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
    return ResponsiveScaffold(
      role: widget.role,
      child: Container(
        color: Colors.white,
        padding: ResponsiveScaffold.pagePadding(context),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER DENGAN TOMBOL SIMPAN ---
                    _buildHeader(context),
                    const SizedBox(height: 40),

                    // --- SEKSI 1: BALAS DISPOSISI ---
                    _sectionTitle("Balas Disposisi"),
                    const Divider(),
                    const SizedBox(height: 20),

                    // --- INFO DISPOSISI ASLI ---
                    _buildOriginalDispositionInfo(),
                    const SizedBox(height: 30),

                    // --- SEKSI 2: DESKRIPSI BALAS ---
                    _sectionTitle("Deskripsi Balas Disposisi"),
                    Divider(
                      endIndent:
                          ResponsiveScaffold.isMobile(context) ? 0 : 400,
                    ),
                    const SizedBox(height: 20),

                    _buildFormField(
                      icon: Icons.description,
                      label: "Deskripsi Balas",
                      child: _buildDescriptionField(),
                    ),
                    const SizedBox(height: 40),

                    // --- TOMBOL SIMPAN ---
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                "Simpan",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isMobile = ResponsiveScaffold.isMobile(context);
    final title = Text(
      "Balas Disposisi Surat",
      style: TextStyle(
        fontSize: isMobile ? 28 : 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textTealDark,
      ),
    );
    final cancelButton = ElevatedButton(
      onPressed: () => Navigator.pop(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondaryPurple.withOpacity(0.7),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 0 : 40,
          vertical: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        "Batal",
        style: TextStyle(color: Colors.white),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: cancelButton),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        title,
        cancelButton,
      ],
    );
  }

  Widget _buildOriginalDispositionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Disposisi Asli:",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textTealDark,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow("Dari", widget.parentDisposition.senderName),
          _buildDetailRow("Subjek", widget.parentDisposition.letterSubject),
          _buildDetailRow(
            "Perihal",
            widget.parentDisposition.letterContent ?? "-",
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
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

  Widget _buildFormField({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.secondaryPurple, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _descriptionController,
        maxLines: 6,
        decoration: const InputDecoration(
          hintText: "Tambahkan deskripsi balas disposisi...",
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
