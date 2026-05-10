import 'package:flutter/material.dart';

import '../../../models/notification_model.dart' as notif_model;
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/custom_styles.dart';
import '../../notifikasi/notifikasi_screen.dart';

class AgendaCard extends StatefulWidget {
  final String role;

  const AgendaCard({super.key, required this.role});

  @override
  State<AgendaCard> createState() => _AgendaCardState();
}

class _AgendaCardState extends State<AgendaCard> {
  bool _isLoading = true;
  String? _errorMessage;
  notif_model.Notification? _latestAgendaNotification;

  @override
  void initState() {
    super.initState();
    _loadAgendaNotification();
  }

  Future<void> _loadAgendaNotification() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Token tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      final result = await ApiService.getNotifications(token: token);
      if (!mounted) return;

      if (result['success']) {
        final notifications =
            (result['data'] as List<dynamic>? ?? [])
                .map(
                  (item) =>
                      item is notif_model.Notification
                          ? item
                          : notif_model.Notification.fromJson(
                            item as Map<String, dynamic>,
                          ),
                )
                .toList();

        final unreadAgendaNotifications =
            notifications
                .where(
                  (notification) =>
                      (notification.type ?? '').toLowerCase() == 'agenda' &&
                      !notification.isRead,
                )
                .toList();

        final allAgendaNotifications =
            notifications
                .where(
                  (notification) =>
                      (notification.type ?? '').toLowerCase() == 'agenda',
                )
                .toList();

        setState(() {
          _latestAgendaNotification =
              unreadAgendaNotifications.isNotEmpty
                  ? unreadAgendaNotifications.first
                  : allAgendaNotifications.isNotEmpty
                  ? allAgendaNotifications.first
                  : null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              result['message'] ?? 'Gagal mengambil notifikasi agenda';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        margin: EdgeInsets.only(bottom: 12),
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildCard(
        context,
        icon: Icons.notifications_off_outlined,
        iconColor: AppColors.warning,
        title: 'Notifikasi agenda belum dapat dimuat',
        subtitle: _errorMessage!,
        trailing: IconButton(
          onPressed: _loadAgendaNotification,
          icon: const Icon(Icons.refresh, color: AppColors.grey),
          tooltip: 'Muat ulang',
        ),
      );
    }

    if (_latestAgendaNotification == null) {
      return _buildCard(
        context,
        icon: Icons.notifications_none,
        iconColor: AppColors.textTealLight,
        title: 'Belum ada notifikasi agenda baru',
        subtitle:
            'Jika admin atau pimpinan mengundang Anda ke agenda, notifikasinya akan tampil di sini.',
      );
    }

    final notification = _latestAgendaNotification!;
    final isUnread = !notification.isRead;

    return _buildCard(
      context,
      icon: isUnread ? Icons.notifications_active : Icons.notifications,
      iconColor: isUnread ? AppColors.primaryPurple : AppColors.secondaryPurple,
      title:
          isUnread
              ? 'Anda mendapatkan notifikasi agenda baru'
              : 'Notifikasi agenda terakhir',
      subtitle: '${notification.title}\n${notification.message}',
      badgeLabel: isUnread ? 'Baru' : 'Terbaru',
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotifikasiScreen(role: widget.role),
            ),
          ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    String? badgeLabel,
    VoidCallback? onTap,
  }) {
    final cardChild = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: CustomStyles.subtitle1.copyWith(
                          color: AppColors.greyDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (badgeLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeLabel,
                          style: const TextStyle(
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
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: CustomStyles.caption.copyWith(
                    color: AppColors.greyDark.withOpacity(0.8),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing ??
              const Icon(
                Icons.chevron_right,
                color: AppColors.grey,
              ),
        ],
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child:
          onTap == null
              ? cardChild
              : InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onTap,
                child: cardChild,
              ),
    );
  }
}
