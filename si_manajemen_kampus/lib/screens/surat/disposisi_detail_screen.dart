import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../shared/app_colors.dart';
import '../../shared/responsive_scaffold.dart';
import '../../utils/web_url_opener.dart';
import '../../models/disposition_model.dart';
import 'balas_disposisi_screen.dart';

class DisposisiDetailScreen extends StatefulWidget {
  final Disposition disposition;
  final String role;

  const DisposisiDetailScreen({
    super.key,
    required this.disposition,
    required this.role,
  });

  @override
  State<DisposisiDetailScreen> createState() => _DisposisiDetailScreenState();
}

class _DisposisiDetailScreenState extends State<DisposisiDetailScreen> {
  late Disposition _currentDisposition;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _currentDisposition = widget.disposition;
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'processed':
        return 'Diproses';
      case 'completed':
        return 'Selesai';
      case 'reassigned':
        return 'Dialihkan';
      default:
        return status;
    }
  }

  Future<void> _openDocument() async {
    if (_currentDisposition.documentFile == null ||
        _currentDisposition.documentFile!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dokumen tidak tersedia untuk disposisi ini')),
      );
      return;
    }

    final token = await AuthService.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token tidak ditemukan')),
      );
      return;
    }

    final previewUrl = ApiService.getFilePreviewUrl(
      token,
      _currentDisposition.documentFile!,
    );
    final opened = openUrlInNewTab(previewUrl);

    if (!mounted) return;

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preview dokumen otomatis saat ini didukung pada Flutter Web.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedCreatedDate = DateFormat('dd MMMM yyyy', 'id_ID').format(
      DateTime.parse(_currentDisposition.createdAt),
    );

    final formattedCreatedTime = DateFormat('HH:mm', 'id_ID').format(
      DateTime.parse(_currentDisposition.createdAt),
    );

    return ResponsiveScaffold(
      role: widget.role,
      child: Container(
        color: Colors.white,
        padding: ResponsiveScaffold.pagePadding(context),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 30),
                    _buildDocumentDetails(
                      formattedCreatedDate,
                      formattedCreatedTime,
                    ),
                    const SizedBox(height: 30),
                    _buildActionButtons(context),
                    const SizedBox(height: 40),
                    _buildStatusDisposisiSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Disposisi Surat",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textTealDark,
              ),
            ),
            Text(
              _capitalizeRole(widget.role),
              style: TextStyle(fontSize: 16, color: AppColors.textTealLight),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, _hasChanges),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          label: const Text(
            "Kembali",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryPurple,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentDetails(String date, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow("Judul Surat", _currentDisposition.letterSubject),
        _buildDetailRow("Nomor Surat", _currentDisposition.letterNumber ?? "-"),
        _buildDetailRow(
          "Tanggal Surat Dibuat",
          _currentDisposition.letterDate ?? "-",
        ),
        _buildDetailRow("Tanggal Surat Diterima", date),
        _buildDetailRow("Pengirim Surat", _currentDisposition.senderName),
        _buildDetailRow("Perihal", _currentDisposition.letterContent ?? "-"),
        _buildDetailRow("Tipe Dokumen", "Surat Tugas"),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          const Text(":", style: TextStyle(fontSize: 14, color: Colors.black87)),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Membuka dokumen...")),
            );
            await _openDocument();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryPurple.withOpacity(0.8),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            "Lihat Dokumen",
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () async {
            final updatedDisposition = await Navigator.push<Disposition>(
              context,
              MaterialPageRoute(
                builder: (context) => BalasDisposisiScreen(
                  parentDisposition: _currentDisposition,
                  role: widget.role,
                ),
              ),
            );

            if (updatedDisposition != null && mounted) {
              setState(() {
                _currentDisposition = updatedDisposition;
                _hasChanges = true;
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryPurple,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            "Balas Disposisi",
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDisposisiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            "Status Disposisi",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildStatusTable(),
      ],
    );
  }

  Widget _buildStatusTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          _buildTableHeaderRow(),
          _buildTableInfoRow(1),
          ..._currentDisposition.updates.asMap().entries.map(
            (entry) => _buildTableDataRow(entry.key + 2, entry.value),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderRow() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[350],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          _buildTableCell("No", flex: 1, isHeader: true),
          _buildTableCell("Tanggal", flex: 2, isHeader: true),
          _buildTableCell("Pengirim Disposisi", flex: 2, isHeader: true),
          _buildTableCell("Status", flex: 1, isHeader: true),
          _buildTableCell("Isi Disposisi", flex: 3, isHeader: true),
        ],
      ),
    );
  }

  Widget _buildTableDataRow(int rowNumber, DispositionUpdate update) {
    final formattedDate = DateFormat('dd-MM-yyyy HH:mm', 'id_ID').format(
      DateTime.parse(update.createdAt),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          _buildTableCell(rowNumber.toString(), flex: 1),
          _buildTableCell(formattedDate, flex: 2),
          _buildTableCell(update.updatedByName, flex: 2),
          _buildTableCell(
            _getStatusLabel(update.newStatus ?? _currentDisposition.status),
            flex: 1,
          ),
          _buildTableCell(update.updateNotes ?? "-", flex: 3),
        ],
      ),
    );
  }

  Widget _buildTableInfoRow(int rowNumber) {
    final formattedDate = DateFormat('dd-MM-yyyy HH:mm', 'id_ID').format(
      DateTime.parse(_currentDisposition.createdAt),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          _buildTableCell(rowNumber.toString(), flex: 1),
          _buildTableCell(formattedDate, flex: 2),
          _buildTableCell(_currentDisposition.senderName, flex: 2),
          _buildTableCell(_getStatusLabel(_currentDisposition.status), flex: 1),
          _buildTableCell(_currentDisposition.letterContent ?? "-", flex: 3),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {required int flex, bool isHeader = false}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: isHeader ? Colors.white : Colors.black87,
            fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _capitalizeRole(String role) {
    if (role.toLowerCase() == 'pimpinan') return 'Pimpinan';
    return role.toUpperCase();
  }
}
