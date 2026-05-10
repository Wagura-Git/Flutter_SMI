import 'package:flutter/material.dart';

import '../../models/agenda_model.dart';
import '../../models/notification_model.dart' as notif_model;
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../shared/app_colors.dart';
import '../../shared/responsive_scaffold.dart';
import '../../utils/web_url_opener.dart';
import 'widgets/notification_card.dart';

class NotifikasiScreen extends StatefulWidget {
  final String role;

  const NotifikasiScreen({super.key, required this.role});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  List<notif_model.Notification> notifications = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() {
          errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
          isLoading = false;
        });
        return;
      }

      print('TEST: Checking Authorization Header...');
      final headerTest = await ApiService.debugHeaders(token);
      print('TEST: Header test result: $headerTest');

      final result = await ApiService.getNotifications(token: token);

      if (result['success']) {
        setState(() {
          notifications =
              (result['data'] as List<dynamic>?)
                  ?.map(
                    (e) =>
                        e is notif_model.Notification
                            ? e
                            : notif_model.Notification.fromJson(
                              e as Map<String, dynamic>,
                            ),
                  )
                  .toList() ??
              [];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Gagal mengambil notifikasi';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _markAllAsRead() async {
    final token = await AuthService.getToken();
    if (token == null) return;

    final result = await ApiService.markAllNotificationsAsRead(token);

    if (result['success']) {
      _loadNotifications();
    }
  }

  Future<void> _openAgendaAttachment(
    notif_model.Notification notification,
  ) async {
    final token = await AuthService.getToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token tidak ditemukan')),
      );
      return;
    }

    if (!notification.isRead) {
      await ApiService.markNotificationAsRead(
        token: token,
        notificationId: notification.id,
      );
    }

    if (notification.relatedAgendaId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi ini belum terhubung ke agenda tertentu'),
        ),
      );
      return;
    }

    final agendaResult = await ApiService.getAgendaById(
      token: token,
      agendaId: notification.relatedAgendaId!,
    );

    if (!mounted) return;

    if (!agendaResult['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            agendaResult['message'] ?? 'Gagal mengambil detail agenda',
          ),
        ),
      );
      _loadNotifications();
      return;
    }

    final agenda = agendaResult['data'] as Agenda;
    if (agenda.attachmentPath == null || agenda.attachmentPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agenda ini tidak memiliki file PDF yang diunggah'),
        ),
      );
      _loadNotifications();
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
            'Preview PDF otomatis saat ini didukung pada Flutter Web. Silakan buka dari browser.',
          ),
        ),
      );
    }

    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveScaffold.isMobile(context);
    final hasUnreadNotifications = notifications.any((n) => !n.isRead);

    return ResponsiveScaffold(
      role: widget.role,
      title: 'Notifikasi',
      child: Container(
        color: Colors.white,
        padding: ResponsiveScaffold.pagePadding(context, desktop: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderTitle(fontSize: 28),
                  _buildHeaderSubtitle(fontSize: 16),
                  if (hasUnreadNotifications) ...[
                    const SizedBox(height: 16),
                    _buildMarkAllButton(),
                  ],
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderTitle(fontSize: 36),
                      _buildHeaderSubtitle(fontSize: 18),
                    ],
                  ),
                  if (hasUnreadNotifications) _buildMarkAllButton(),
                ],
              ),
            SizedBox(height: isMobile ? 24 : 40),
            Expanded(child: _buildNotificationList(isMobile)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTitle({required double fontSize}) {
    return Text(
      "Notifikasi,",
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: AppColors.textTealDark,
      ),
    );
  }

  Widget _buildHeaderSubtitle({required double fontSize}) {
    return Text(
      "Bpk. William Agung",
      style: TextStyle(
        fontSize: fontSize,
        color: AppColors.textTealLight,
      ),
    );
  }

  Widget _buildMarkAllButton() {
    return ElevatedButton(
      onPressed: _markAllAsRead,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondaryPurple,
      ),
      child: const Text(
        'Tandai Semua Dibaca',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildNotificationList(bool isMobile) {
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
              onPressed: _loadNotifications,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (notifications.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada notifikasi',
          style: TextStyle(color: AppColors.textTealLight),
        ),
      );
    }

    return ListView(
      children: [
        if (notifications.where((n) => !n.isRead).isNotEmpty) ...[
          _buildSectionTitle("Belum Dibaca", isMobile: isMobile),
          ...notifications.where((n) => !n.isRead).map((notification) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NotificationCard(
                title: notification.title,
                subtitle: notification.message,
                imageUrl: "https://via.placeholder.com/80",
                onDetailPressed: () => _openAgendaAttachment(notification),
              ),
            );
          }),
          const SizedBox(height: 30),
        ],
        if (notifications.where((n) => n.isRead).isNotEmpty) ...[
          _buildSectionTitle("Sudah Dibaca", isMobile: isMobile),
          ...notifications.where((n) => n.isRead).map((notification) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NotificationCard(
                title: notification.title,
                subtitle: notification.message,
                imageUrl: "https://via.placeholder.com/80",
                onDetailPressed: () => _openAgendaAttachment(notification),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, {required bool isMobile}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isMobile ? 16 : 18,
          fontWeight: FontWeight.w500,
          color: AppColors.textTealLight,
        ),
      ),
    );
  }
}
