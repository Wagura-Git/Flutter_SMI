import 'package:flutter/material.dart';
// Import Halaman yang baru dibuat
import 'package:si_manajemen_kampus/screens/agenda/agenda_screen.dart';
import 'package:si_manajemen_kampus/screens/surat/disposisi_list_screen.dart';
import 'package:si_manajemen_kampus/screens/notifikasi/notifikasi_screen.dart';
import 'package:si_manajemen_kampus/screens/settings/account_settings_screen.dart';
import 'package:si_manajemen_kampus/screens/dashboard/dashboard_screen.dart';
import 'package:si_manajemen_kampus/screens/login/login_screen.dart';
import 'package:si_manajemen_kampus/services/auth_service.dart';

import '../../../shared/app_colors.dart';

class Sidebar extends StatelessWidget {
  final String role;
  final bool isDrawer;
  final bool isOverlay;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final VoidCallback? onHide;
  final VoidCallback? onCloseOverlay;

  const Sidebar({
    super.key,
    required this.role,
    this.isDrawer = false,
    this.isOverlay = false,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.onHide,
    this.onCloseOverlay,
  });

  @override
  Widget build(BuildContext context) {
    final showLabels = isDrawer || isOverlay || !isCollapsed;

    return Container(
      width: double.infinity,
      color: AppColors.primaryPurple,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: isDrawer ? 20 : 40,
                bottom: 32,
                left: showLabels ? 24 : 12,
                right: showLabels ? 24 : 12,
              ),
              child:
                  isDrawer
                      ? const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                      : isOverlay
                      ? _buildOverlayHeader()
                      : _buildDesktopHeader(showLabels),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // 1. BERANDA
                  _item(
                    context,
                    Icons.home,
                    "Beranda",
                    onTap:
                        () => _openPage(
                          context,
                          DashboardScreen(role: role),
                          replace: true,
                        ),
                  ),

                  // 2. NOTIFIKASI
                  _item(
                    context,
                    Icons.notifications,
                    "Notifikasi",
                    onTap:
                        () => _openPage(context, NotifikasiScreen(role: role)),
                  ),

                  // 3. DAFTAR AGENDA
                  _item(
                    context,
                    Icons.event_available,
                    "Agenda",
                    onTap: () => _openPage(context, AgendaScreen(role: role)),
                  ),

                  // 4. DISPOSISI SURAT
                  _item(
                    context,
                    Icons.description,
                    "Disposisi Surat",
                    onTap:
                        () =>
                            _openPage(context, DisposisiListScreen(role: role)),
                  ),

                  // 5. PENGATURAN AKUN
                  _item(
                    context,
                    Icons.save,
                    "Pengaturan Akun",
                    onTap:
                        () => _openPage(
                          context,
                          AccountSettingsScreen(role: role),
                        ),
                  ),
                ],
              ),
            ),

            // KELUAR - Logout dan Clear Token
            _item(
              context,
              Icons.logout,
              "Keluar",
              onTap: () => _logout(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _openPage(BuildContext context, Widget page, {bool replace = true}) {
    final navigator = Navigator.of(context);
    if (isDrawer && navigator.canPop()) {
      navigator.pop();
    }

    final route = MaterialPageRoute(builder: (_) => page);
    Future<void>.microtask(() {
      if (replace) {
        navigator.pushReplacement(route);
      } else {
        navigator.push(route);
      }
    });
  }

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    await AuthService.clearToken();

    if (isDrawer && navigator.canPop()) {
      navigator.pop();
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title, {
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    final showLabels = isDrawer || isOverlay || !isCollapsed;

    if (!showLabels) {
      return Tooltip(
        message: title,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? Colors.black12 : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.9)),
          ),
        ),
      );
    }

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white.withValues(alpha: 0.8)),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 15,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: Colors.black12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Widget _buildDesktopHeader(bool showLabels) {
    if (showLabels) {
      return Row(
        children: [
          const Icon(Icons.menu, color: Colors.white),
          const Spacer(),
          _buildHeaderButton(
            tooltip: 'Collapse sidebar',
            icon: Icons.keyboard_double_arrow_left,
            onPressed: onToggleCollapse,
          ),
          const SizedBox(width: 8),
          _buildHeaderButton(
            tooltip: 'Sembunyikan sidebar',
            icon: Icons.visibility_off_outlined,
            onPressed: onHide,
          ),
        ],
      );
    }

    return Column(
      children: [
        const Icon(Icons.menu, color: Colors.white),
        const SizedBox(height: 16),
        _buildHeaderButton(
          tooltip: 'Expand sidebar',
          icon: Icons.keyboard_double_arrow_right,
          onPressed: onToggleCollapse,
        ),
        const SizedBox(height: 8),
        _buildHeaderButton(
          tooltip: 'Sembunyikan sidebar',
          icon: Icons.visibility_off_outlined,
          onPressed: onHide,
        ),
      ],
    );
  }

  Widget _buildOverlayHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Menu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _buildHeaderButton(
          tooltip: 'Tutup sidebar',
          icon: Icons.close,
          onPressed: onCloseOverlay,
        ),
      ],
    );
  }

  Widget _buildHeaderButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}
