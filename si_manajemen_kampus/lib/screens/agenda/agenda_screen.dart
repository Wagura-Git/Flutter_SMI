import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/agenda_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../shared/app_colors.dart';
import '../../shared/responsive_scaffold.dart';
import '../../utils/web_url_opener.dart';
import 'agenda_add_screen.dart';

enum _AgendaSortOption { newest, oldest }

class AgendaScreen extends StatefulWidget {
  final String role;

  const AgendaScreen({super.key, required this.role});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  List<Agenda> agendas = [];
  bool isLoading = false;
  String? errorMessage;
  String? _currentUserRole;
  _AgendaSortOption _sortOption = _AgendaSortOption.newest;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadCurrentUser();
    _loadAgendas();
  }

  Future<void> _loadCurrentUser() async {
    final rawUserData = await AuthService.getUserData();
    if (rawUserData == null) return;

    try {
      final userData = jsonDecode(rawUserData) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _currentUserRole = userData['role']?.toString().toLowerCase();
      });
    } catch (_) {
      // Abaikan jika data user lokal tidak valid, daftar agenda tetap dicoba dimuat.
    }
  }

  void _loadAgendas() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (!mounted) return;
      if (token == null) {
        setState(() {
          errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
          isLoading = false;
        });
        return;
      }

      final result = await ApiService.getAgendas(token);
      if (!mounted) return;

      if (result['success']) {
        setState(() {
          agendas = result['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Gagal mengambil agenda';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  bool get _canManageAgenda {
    return _currentUserRole == 'admin' || _currentUserRole == 'pimpinan';
  }

  void _deleteAgenda(int agendaId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Agenda'),
          content: const Text('Apakah Anda yakin ingin menghapus agenda ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (confirmed != true) return;

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token tidak ditemukan')),
        );
        return;
      }

      final result = await ApiService.deleteAgenda(
        token: token,
        agendaId: agendaId,
      );
      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agenda berhasil dihapus')),
        );
        _loadAgendas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: ${result['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _markAgendaCompleted(Agenda agenda) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token tidak ditemukan')),
        );
        return;
      }

      final result = await ApiService.updateAgenda(
        token: token,
        agendaId: agenda.id,
        status: 'completed',
      );
      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agenda ditandai selesai')),
        );
        _loadAgendas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal mengubah agenda')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _showEditAgendaDialog(Agenda agenda) async {
    final titleController = TextEditingController(text: agenda.title);
    final descriptionController = TextEditingController(
      text: agenda.description ?? '',
    );
    final locationController = TextEditingController(text: agenda.location ?? '');
    DateTime selectedDate = _parseDate(agenda.date) ?? DateTime.now();
    TimeOfDay selectedStartTime =
        _parseTimeOfDay(agenda.timeStart) ?? TimeOfDay.now();
    TimeOfDay? selectedEndTime = _parseTimeOfDay(agenda.timeEnd ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Agenda'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Judul Agenda',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi Agenda',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Tempat Agenda',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedDate = picked;
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(_formatDateWithDay(selectedDate)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: dialogContext,
                                  initialTime: selectedStartTime,
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedStartTime = picked;
                                  });
                                }
                              },
                              icon: const Icon(Icons.schedule),
                              label: Text(
                                'Mulai ${_formatTimeOfDay(selectedStartTime)}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: dialogContext,
                                  initialTime:
                                      selectedEndTime ?? selectedStartTime,
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedEndTime = picked;
                                  });
                                }
                              },
                              icon: const Icon(Icons.timer_outlined),
                              label: Text(
                                selectedEndTime == null
                                    ? 'Selesai'
                                    : 'Selesai ${_formatTimeOfDay(selectedEndTime!)}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Judul agenda harus diisi')),
                      );
                      return;
                    }

                    final token = await AuthService.getToken();
                    if (token == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Token tidak ditemukan')),
                      );
                      return;
                    }

                    final result = await ApiService.updateAgenda(
                      token: token,
                      agendaId: agenda.id,
                      title: titleController.text.trim(),
                      description:
                          descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                      date: _formatApiDate(selectedDate),
                      timeStart: _formatApiTime(selectedStartTime),
                      timeEnd:
                          selectedEndTime == null
                              ? null
                              : _formatApiTime(selectedEndTime!),
                      location:
                          locationController.text.trim().isEmpty
                              ? null
                              : locationController.text.trim(),
                    );

                    if (!mounted) return;
                    if (result['success']) {
                      Navigator.pop(dialogContext, true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result['message'] ?? 'Gagal memperbarui agenda',
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryPurple,
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agenda berhasil diperbarui')),
      );
      _loadAgendas();
    }
  }

  Future<void> _previewDocument(Agenda agenda) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token tidak ditemukan')),
        );
        return;
      }

      final previewUrl = ApiService.getFilePreviewUrl(
        token,
        agenda.attachmentPath!,
      );
      final opened = openUrlInNewTab(previewUrl);

      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Preview PDF otomatis saat ini didukung pada Flutter Web.',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  String _getRecipientsText(Agenda agenda) {
    if (agenda.recipients == null || agenda.recipients!.isEmpty) {
      return '-';
    }
    return agenda.recipients!.map((r) => r['name'] as String).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveScaffold.isMobile(context);
    final normalizedRole = widget.role.toLowerCase();
    final canCreateAgenda =
        normalizedRole == 'admin' || normalizedRole == 'pimpinan';

    return ResponsiveScaffold(
      role: widget.role,
      title: 'Agenda',
      child: Container(
        color: Colors.white,
        padding: ResponsiveScaffold.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(fontSize: 28),
                  _buildSubtitle(),
                  if (canCreateAgenda) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: _buildCreateAgendaButton(compact: true),
                    ),
                  ],
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(fontSize: 32),
                      _buildSubtitle(),
                    ],
                  ),
                  if (canCreateAgenda) _buildCreateAgendaButton(),
                ],
              ),
            const SizedBox(height: 20),
            _buildSortDropdown(isMobile: isMobile),
            SizedBox(height: isMobile ? 16 : 20),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle({required double fontSize}) {
    return Text(
      "Agenda",
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: AppColors.textTealDark,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      "Daftar agenda yang mengundang akun Anda",
      style: TextStyle(
        fontSize: 14,
        color: AppColors.textTealLight,
      ),
    );
  }

  Widget _buildCreateAgendaButton({bool compact = false}) {
    return ElevatedButton.icon(
      onPressed:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AgendaAddScreen(role: widget.role),
            ),
          ).then((_) => _loadAgendas()),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        "Tambah Agenda",
        style: TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondaryPurple,
        padding:
            compact
                ? const EdgeInsets.symmetric(vertical: 12)
                : const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  Widget _buildSortDropdown({required bool isMobile}) {
    final dropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_AgendaSortOption>(
          value: _sortOption,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: const [
            DropdownMenuItem(
              value: _AgendaSortOption.newest,
              child: Text('Terbaru'),
            ),
            DropdownMenuItem(
              value: _AgendaSortOption.oldest,
              child: Text('Terlama'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _sortOption = value;
            });
          },
        ),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSortLabel(),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: dropdown),
        ],
      );
    }

    return Row(
      children: [
        _buildSortLabel(),
        const SizedBox(width: 12),
        SizedBox(width: 180, child: dropdown),
      ],
    );
  }

  Widget _buildSortLabel() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.sort, size: 18, color: AppColors.textTealDark),
        const SizedBox(width: 6),
        Text(
          'Urutkan agenda',
          style: TextStyle(
            color: AppColors.textTealDark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadAgendas,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (agendas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: AppColors.bgTeal,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada agenda',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textTealLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agenda akan tampil jika akun Anda diundang oleh admin atau pimpinan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTealLight,
              ),
            ),
          ],
        ),
      );
    }

    final sortedAgendas = _sortAgendas(agendas);

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: sortedAgendas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _buildAgendaCard(sortedAgendas[index]);
      },
    );
  }

  List<Agenda> _sortAgendas(List<Agenda> source) {
    final sortedAgendas = [...source];
    sortedAgendas.sort((a, b) {
      final dateA = _parseAgendaDateTime(a) ?? DateTime(9999);
      final dateB = _parseAgendaDateTime(b) ?? DateTime(9999);
      return _sortOption == _AgendaSortOption.newest
          ? dateB.compareTo(dateA)
          : dateA.compareTo(dateB);
    });
    return sortedAgendas;
  }

  Widget _buildAgendaCard(Agenda agenda) {
    final canViewDocument =
        agenda.attachmentPath != null && agenda.attachmentPath!.isNotEmpty;
    final isMobile = ResponsiveScaffold.isMobile(context);
    final actionButtons = <Widget>[
      _buildActionButton(
        label: 'Lihat',
        icon: Icons.visibility_outlined,
        foregroundColor: Colors.blue,
        backgroundColor: Colors.blue.withValues(alpha: 0.08),
        onPressed: canViewDocument ? () => _previewDocument(agenda) : null,
      ),
      if (_canManageAgenda)
        _buildActionButton(
          label: 'Selesai',
          icon: Icons.check_circle_outline,
          foregroundColor: Colors.black87,
          backgroundColor: Colors.grey.withValues(alpha: 0.10),
          onPressed:
              agenda.status.toLowerCase() == 'completed'
                  ? null
                  : () => _markAgendaCompleted(agenda),
        ),
      if (_canManageAgenda)
        _buildActionButton(
          label: 'Edit',
          icon: Icons.edit_outlined,
          foregroundColor: Colors.black87,
          backgroundColor: Colors.grey.withValues(alpha: 0.10),
          onPressed: () => _showEditAgendaDialog(agenda),
        ),
      if (_canManageAgenda)
        _buildActionButton(
          label: 'Hapus',
          icon: Icons.delete_outline,
          foregroundColor: Colors.red,
          backgroundColor: Colors.red.withValues(alpha: 0.08),
          onPressed: () => _deleteAgenda(agenda.id),
        ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAgendaSummary(agenda),
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, runSpacing: 8, children: actionButtons),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildAgendaSummary(agenda)),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 420,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: actionButtons,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _buildMetaItem(
                  Icons.calendar_today_outlined,
                  _formatDateWithDay(_parseDate(agenda.date)),
                  AppColors.primaryPurple,
                ),
                _buildMetaItem(
                  Icons.alarm_outlined,
                  _formatTimeRange(agenda),
                  Colors.red,
                ),
                _buildMetaItem(
                  Icons.place_outlined,
                  agenda.location?.trim().isNotEmpty == true
                      ? agenda.location!.trim()
                      : 'Tempat belum diisi',
                  Colors.pink,
                ),
                _buildMetaItem(
                  Icons.people_outline,
                  _getRecipientsText(agenda),
                  AppColors.textTealDark,
                ),
                _buildStatusBadge(agenda.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaSummary(Agenda agenda) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          agenda.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          (agenda.description?.trim().isNotEmpty == true)
              ? agenda.description!.trim()
              : 'Tidak ada deskripsi agenda',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: Colors.black.withValues(alpha: 0.56),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color foregroundColor,
    required Color backgroundColor,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor:
            onPressed == null ? Colors.grey.shade500 : foregroundColor,
        backgroundColor:
            onPressed == null ? Colors.grey.shade100 : backgroundColor,
        side: BorderSide(
          color: onPressed == null
              ? Colors.grey.shade300
              : foregroundColor.withValues(alpha: 0.16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.68),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final normalizedStatus = status.toLowerCase();
    final isCompleted = normalizedStatus == 'completed';
    final color = isCompleted ? Colors.green : AppColors.primaryPurple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isCompleted ? 'Selesai' : 'Terjadwal',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  DateTime? _parseDate(String date) {
    try {
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseAgendaDateTime(Agenda agenda) {
    try {
      return DateTime.parse('${agenda.date} ${agenda.timeStart}');
    } catch (_) {
      return _parseDate(agenda.date);
    }
  }

  TimeOfDay? _parseTimeOfDay(String time) {
    final normalizedTime = time.trim();
    if (normalizedTime.isEmpty) return null;

    final parts = normalizedTime.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatDateWithDay(DateTime? date) {
    if (date == null) return 'Tanggal belum tersedia';

    const dayNames = [
      'Sen',
      'Sel',
      'Rab',
      'Kam',
      'Jum',
      'Sab',
      'Min',
    ];
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${dayNames[date.weekday - 1]}, ${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  String _formatTimeRange(Agenda agenda) {
    final start = _formatTimeString(agenda.timeStart);
    final end = _formatTimeString(agenda.timeEnd ?? '');
    if (end == '-') return start;
    return '$start - $end';
  }

  String _formatTimeString(String time) {
    final normalizedTime = time.trim();
    if (normalizedTime.isEmpty) return '-';
    return normalizedTime.length >= 5
        ? normalizedTime.substring(0, 5)
        : normalizedTime;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatApiDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatApiTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }
}
