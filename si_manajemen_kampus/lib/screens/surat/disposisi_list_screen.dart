import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/app_colors.dart';
import '../../shared/responsive_scaffold.dart';
import '../../services/disposition_service.dart';
import '../../services/auth_service.dart';
import '../../models/disposition_model.dart';
import 'disposisi_input_screen.dart';
import 'disposisi_detail_screen.dart';

class DisposisiListScreen extends StatefulWidget {
  final String role;

  const DisposisiListScreen({super.key, required this.role});

  @override
  State<DisposisiListScreen> createState() => _DisposisiListScreenState();
}

class _DisposisiListScreenState extends State<DisposisiListScreen> {
  List<Disposition> _dispositions = [];
  String _sortOrder = 'terbaru';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDispositions();
  }

  Future<void> _loadDispositions() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token tidak ditemukan')),
        );
        return;
      }

      final result = await DispositionService.getDispositions(token);
      setState(() {
        if (result['success']) {
          _dispositions = result['dispositions'] ?? [];
          _sortDispositions();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Gagal memuat disposisi')),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _sortDispositions() {
    if (_sortOrder == 'terbaru') {
      _dispositions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      _dispositions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
  }

  Future<void> _updateDispositionStatus(
    int dispositionId,
    String newStatus,
  ) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final result = await DispositionService.updateDisposition(
        token: token,
        dispositionId: dispositionId,
        status: newStatus,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        await _loadDispositions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteDisposition(int dispositionId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final result = await DispositionService.deleteDisposition(
        token: token,
        dispositionId: dispositionId,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        await _loadDispositions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  String _getStatusBadgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#FFA500'; // Orange
      case 'processed':
        return '#4169E1'; // Royal Blue
      case 'completed':
        return '#28A745'; // Green
      case 'reassigned':
        return '#6C757D'; // Gray
      default:
        return '#808080';
    }
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

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveScaffold.isMobile(context);
    final hasOverlaySidebar = ResponsiveScaffold.useOverlaySidebar(context);

    return ResponsiveScaffold(
      role: widget.role,
      child: Container(
        color: Colors.white,
        padding: ResponsiveScaffold.pagePadding(context).copyWith(
          top: hasOverlaySidebar ? 88 : ResponsiveScaffold.pagePadding(context).top,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopHeader(context, isMobile),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            _buildFilterButton(isMobile),
            const SizedBox(height: 24),
            if (!isMobile) ...[
              _buildTableHeader(),
              const SizedBox(height: 4),
            ],
            Expanded(child: _buildDispositionContent(isMobile)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isMobile) {
    String roleDisplay = widget.role.toLowerCase() == 'pimpinan'
        ? 'Pimpinan'
        : widget.role.toUpperCase();

    final addButton = widget.role.toLowerCase() != 'user'
        ? ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisposisiInputScreen(role: widget.role),
              ),
            ),
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: Text(
              isMobile ? "Tambah Disposisi" : "Tambahkan Disposisi Baru",
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryPurple,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 18 : 24,
                vertical: isMobile ? 16 : 22,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          )
        : null;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Disposisi Surat",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textTealDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            roleDisplay,
            style: TextStyle(fontSize: 16, color: AppColors.textTealLight),
          ),
          if (addButton != null) ...[
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: addButton),
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
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
              roleDisplay,
              style: TextStyle(fontSize: 16, color: AppColors.textTealLight),
            ),
          ],
        ),
        if (addButton != null) addButton,
      ],
    );
  }

  Widget _buildFilterButton(bool isMobile) {
    return SizedBox(
      width: isMobile ? 150 : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButton<String>(
          isExpanded: true,
          underline: const SizedBox(),
          value: _sortOrder,
          items: const [
            DropdownMenuItem(value: 'terbaru', child: Text("Terbaru")),
            DropdownMenuItem(value: 'terlama', child: Text("Terlama")),
          ],
          onChanged: (value) {
            setState(() {
              _sortOrder = value ?? 'terbaru';
              _sortDispositions();
            });
          },
        ),
      ),
    );
  }

  Widget _buildDispositionContent(bool isMobile) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dispositions.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada disposisi',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _dispositions.length,
      itemBuilder: (context, index) {
        final disposition = _dispositions[index];
        if (isMobile) {
          return _buildMobileDispositionCard(index + 1, disposition);
        }

        return _buildTableRow(index + 1, disposition);
      },
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _cellHeader("No", flex: 1),
          _cellHeader("Dokumen", flex: 3),
          _cellHeader("Dari", flex: 2),
          _cellHeader("Untuk", flex: 2),
          _cellHeader("Tanggal", flex: 2),
          _cellHeader("Status", flex: 2),
          _cellHeader("Aksi", flex: 2),
        ],
      ),
    );
  }

  Widget _cellHeader(String title, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(int index, Disposition disposition) {
    final formattedDate = DateFormat('dd-MM-yyyy').format(
      DateTime.parse(disposition.createdAt),
    );
    final recipientsText = _buildRecipientsText(disposition);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(index.toString(), textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 3,
            child: Text(
              disposition.letterSubject,
              textAlign: TextAlign.left,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              disposition.senderName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              recipientsText,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formattedDate,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(
                      _getStatusBadgeColor(disposition.status)
                          .replaceFirst('#', '0xff'),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusLabel(disposition.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: _buildActionButton(disposition),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDispositionCard(int index, Disposition disposition) {
    final formattedDate = DateFormat('dd MMM yyyy').format(
      DateTime.parse(disposition.createdAt),
    );
    final recipientsText = _buildRecipientsText(disposition);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.bgTeal,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  index.toString(),
                  style: TextStyle(
                    color: AppColors.textTealDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disposition.letterSubject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      disposition.letterNumber?.isNotEmpty == true
                          ? disposition.letterNumber!
                          : 'Tanpa nomor surat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildActionButton(disposition, isCompact: true),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusBadge(disposition.status),
              _buildInfoChip(Icons.calendar_today_outlined, formattedDate),
            ],
          ),
          const SizedBox(height: 14),
          _buildMobileInfoRow('Dari', disposition.senderName),
          const SizedBox(height: 10),
          _buildMobileInfoRow('Untuk', recipientsText),
        ],
      ),
    );
  }

  Widget _buildMobileInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Color(
          int.parse(
            _getStatusBadgeColor(status).replaceFirst('#', '0xff'),
          ),
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _getStatusLabel(status),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    Disposition disposition, {
    bool isCompact = false,
  }) {
    return Container(
      width: isCompact ? 40 : 44,
      height: isCompact ? 40 : 36,
      decoration: BoxDecoration(
        color: AppColors.secondaryPurple.withOpacity(0.82),
        borderRadius: BorderRadius.circular(isCompact ? 12 : 18),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
        onSelected: (String choice) {
          if (choice == 'view_detail') {
            Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => DisposisiDetailScreen(
                  disposition: disposition,
                  role: widget.role,
                ),
              ),
            ).then((shouldReload) {
              if (shouldReload == true) {
                _loadDispositions();
              }
            });
          } else if (choice == 'update_pending') {
            _updateDispositionStatus(disposition.id, 'pending');
          } else if (choice == 'update_processed') {
            _updateDispositionStatus(disposition.id, 'processed');
          } else if (choice == 'update_completed') {
            _updateDispositionStatus(disposition.id, 'completed');
          } else if (choice == 'delete') {
            _showDeleteConfirmation(disposition.id);
          }
        },
        itemBuilder: (BuildContext context) => [
          const PopupMenuItem(
            value: 'view_detail',
            child: Text('Lihat Detail'),
          ),
          const PopupMenuDivider(),
          if (widget.role.toLowerCase() != 'user') ...[
            const PopupMenuItem(
              value: 'update_pending',
              child: Text('Menunggu'),
            ),
            const PopupMenuItem(
              value: 'update_processed',
              child: Text('Diproses'),
            ),
            const PopupMenuItem(
              value: 'update_completed',
              child: Text('Selesai'),
            ),
          ],
          if (widget.role.toLowerCase() == 'admin') const PopupMenuDivider(),
          if (widget.role.toLowerCase() == 'admin')
            const PopupMenuItem(
              value: 'delete',
              child: Text('Hapus'),
            ),
        ],
      ),
    );
  }

  String _buildRecipientsText(Disposition disposition) {
    return disposition.recipients.isNotEmpty
        ? disposition.recipients.map((r) => r.recipientName).join(', ')
        : '-';
  }

  void _showDeleteConfirmation(int dispositionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Disposisi'),
        content: const Text('Apakah Anda yakin ingin menghapus disposisi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDisposition(dispositionId);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
