import 'package:flutter/material.dart';

import '../../models/agenda_model.dart';
import '../../models/disposition_model.dart';
import '../../models/notification_model.dart' as notif_model;
import '../../screens/agenda/agenda_screen.dart';
import '../../screens/surat/disposisi_list_screen.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/disposition_service.dart';
import '../../shared/app_colors.dart';
import '../../shared/responsive_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  final String role;

  const DashboardScreen({super.key, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  bool _isStatsLoading = true;
  int _unreadAgendaCount = 0;
  int _newDispositionCount = 0;
  List<Agenda> _upcomingAgendas = [];
  String? _statsErrorMessage;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _loadDashboardStats();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardStats() async {
    setState(() {
      _isStatsLoading = true;
      _statsErrorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _statsErrorMessage = 'Token tidak ditemukan';
          _isStatsLoading = false;
        });
        return;
      }

      final results = await Future.wait([
        ApiService.getNotifications(token: token, isRead: false),
        DispositionService.getDispositions(token),
        ApiService.getAgendas(token),
      ]);

      if (!mounted) return;

      final notificationResult = results[0];
      final dispositionResult = results[1];
      final agendaResult = results[2];

      final notifications =
          (notificationResult['data'] as List<dynamic>? ?? [])
              .map(
                (item) =>
                    item is notif_model.Notification
                        ? item
                        : notif_model.Notification.fromJson(
                          item as Map<String, dynamic>,
                        ),
              )
              .toList();

      final dispositions =
          (dispositionResult['dispositions'] as List<dynamic>? ?? [])
              .whereType<Disposition>()
              .toList();

      final agendas =
          (agendaResult['data'] as List<dynamic>? ?? [])
              .whereType<Agenda>()
              .toList();

      setState(() {
        _unreadAgendaCount =
            notifications
                .where(
                  (notification) =>
                      (notification.type ?? '').toLowerCase() == 'agenda',
                )
                .length;
        _newDispositionCount =
            notifications
                .where(
                  (notification) =>
                      (notification.type ?? '').toLowerCase() == 'disposisi',
                )
                .length;

        if (_newDispositionCount == 0) {
          _newDispositionCount =
              dispositions
                  .where(
                    (disposition) =>
                        disposition.status.toLowerCase() == 'pending',
                  )
                  .length;
        }

        _upcomingAgendas = _getUpcomingAgendas(agendas);
        _isStatsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statsErrorMessage = 'Statistik belum dapat dimuat';
        _isStatsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveScaffold.isMobile(context);

    return ResponsiveScaffold(
      role: widget.role,
      title: 'Beranda',
      child: Container(
        color: Colors.white,
        padding: ResponsiveScaffold.pagePadding(context, desktop: 48),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Selamat Datang,",
                style: TextStyle(
                  fontSize: isMobile ? 28 : 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textTealDark,
                ),
              ),
              Text(
                _getRoleDisplay(widget.role),
                style: TextStyle(
                  fontSize: isMobile ? 16 : 20,
                  color: AppColors.textTealLight,
                ),
              ),
              SizedBox(height: isMobile ? 24 : 48),
              Row(
                children: [
                  Expanded(
                    child: _sectionLabel("Statistik", isMobile: isMobile),
                  ),
                  if (_statsErrorMessage != null)
                    IconButton(
                      tooltip: 'Muat ulang statistik',
                      onPressed: _loadDashboardStats,
                      icon: const Icon(Icons.refresh, color: AppColors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSummaryCards(isMobile),
              SizedBox(height: isMobile ? 24 : 32),
              _buildUpcomingAgendaCard(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, {required bool isMobile}) => Text(
    text,
    style: TextStyle(
      fontSize: isMobile ? 18 : 22,
      fontWeight: FontWeight.bold,
      color: AppColors.textTealDark,
    ),
  );

  Widget _buildSummaryCards(bool isMobile) {
    final cards = [
      _AnimatedDashboardCard(
        controller: _entranceController,
        intervalStart: 0,
        child: _DashboardStatCard(
          title: 'Agenda',
          subtitle:
              _isStatsLoading
                  ? 'Memuat agenda terbaru'
                  : _unreadAgendaCount > 0
                  ? 'Ada $_unreadAgendaCount agenda baru'
                  : 'Tidak ada agenda baru',
          count: _isStatsLoading ? null : _unreadAgendaCount,
          icon: Icons.event_available_outlined,
          hasNewItem: _unreadAgendaCount > 0,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AgendaScreen(role: widget.role),
                ),
              ),
        ),
      ),
      _AnimatedDashboardCard(
        controller: _entranceController,
        intervalStart: 0.12,
        child: _DashboardStatCard(
          title: 'Disposisi',
          subtitle:
              _isStatsLoading
                  ? 'Memuat disposisi terbaru'
                  : _newDispositionCount > 0
                  ? 'Ada $_newDispositionCount disposisi baru'
                  : 'Tidak ada disposisi baru',
          count: _isStatsLoading ? null : _newDispositionCount,
          icon: Icons.description_outlined,
          hasNewItem: _newDispositionCount > 0,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DisposisiListScreen(role: widget.role),
                ),
              ),
        ),
      ),
    ];

    if (isMobile) {
      return Column(children: cards);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          cards
              .map(
                (card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: card,
                  ),
                ),
              )
              .toList(),
    );
  }

  List<Agenda> _getUpcomingAgendas(List<Agenda> agendas) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcoming =
        agendas.where((agenda) {
          final agendaDate = _parseAgendaDate(agenda.date);
          if (agendaDate == null) return false;
          final normalizedDate = DateTime(
            agendaDate.year,
            agendaDate.month,
            agendaDate.day,
          );
          return !normalizedDate.isBefore(today) &&
              agenda.status.toLowerCase() != 'cancelled';
        }).toList();

    upcoming.sort((a, b) {
      final dateA = _parseAgendaDateTime(a) ?? DateTime(9999);
      final dateB = _parseAgendaDateTime(b) ?? DateTime(9999);
      return dateA.compareTo(dateB);
    });

    return upcoming.take(3).toList();
  }

  Widget _buildUpcomingAgendaCard(bool isMobile) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AgendaScreen(role: widget.role)),
            ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.primaryPurple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Agenda yang Akan Datang',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isStatsLoading
                              ? 'Memuat agenda terdekat'
                              : _upcomingAgendas.isEmpty
                              ? 'Belum ada agenda yang akan datang'
                              : '${_upcomingAgendas.length} agenda terdekat',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.55),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.grey),
                ],
              ),
              const SizedBox(height: 16),
              if (_isStatsLoading)
                const LinearProgressIndicator(minHeight: 3)
              else if (_upcomingAgendas.isEmpty)
                _buildEmptyUpcomingAgenda()
              else
                Column(
                  children:
                      _upcomingAgendas
                          .map((agenda) => _buildUpcomingAgendaItem(agenda))
                          .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyUpcomingAgenda() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Agenda terjadwal akan muncul di sini.',
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.55),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildUpcomingAgendaItem(Agenda agenda) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  _formatDay(agenda.date),
                  style: const TextStyle(
                    color: AppColors.textTealDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _formatShortMonth(agenda.date),
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agenda.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _buildAgendaMeta(agenda),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseAgendaDate(String date) {
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
      return _parseAgendaDate(agenda.date);
    }
  }

  String _buildAgendaMeta(Agenda agenda) {
    final time = _formatTime(agenda.timeStart);
    final location = agenda.location?.trim();
    if (location == null || location.isEmpty) {
      return '${_formatFullDate(agenda.date)} - $time';
    }
    return '${_formatFullDate(agenda.date)} - $time - $location';
  }

  String _formatTime(String time) {
    final normalizedTime = time.trim();
    if (normalizedTime.isEmpty) return '-';
    if (normalizedTime.length >= 5) return normalizedTime.substring(0, 5);
    return normalizedTime;
  }

  String _formatDay(String date) {
    final parsedDate = _parseAgendaDate(date);
    return parsedDate == null ? '-' : parsedDate.day.toString();
  }

  String _formatShortMonth(String date) {
    final parsedDate = _parseAgendaDate(date);
    if (parsedDate == null) return '-';
    const months = [
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
    return months[parsedDate.month - 1];
  }

  String _formatFullDate(String date) {
    final parsedDate = _parseAgendaDate(date);
    if (parsedDate == null) return date;
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
    return '${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}';
  }

  String _getRoleDisplay(String role) {
    switch (role.toLowerCase()) {
      case 'pimpinan':
        return 'Pimpinan';
      case 'admin':
        return 'Admin';
      case 'user':
        return 'Pengguna';
      default:
        return role;
    }
  }
}

class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int? count;
  final IconData icon;
  final bool hasNewItem;
  final VoidCallback onTap;

  const _DashboardStatCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.hasNewItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primaryPurple, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (hasNewItem)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple.withValues(
                                alpha: 0.14,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Baru',
                              style: TextStyle(
                                color: AppColors.primaryPurple,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.55),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (count == null)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  count.toString(),
                  style: const TextStyle(
                    color: AppColors.textTealDark,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedDashboardCard extends StatelessWidget {
  final AnimationController controller;
  final double intervalStart;
  final Widget child;

  const _AnimatedDashboardCard({
    required this.controller,
    required this.intervalStart,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(intervalStart, 1, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
        child: child,
      ),
    );
  }
}
