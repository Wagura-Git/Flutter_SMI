import 'package:flutter/material.dart';

import '../screens/dashboard/widgets/sidebar.dart';
import 'app_colors.dart';

class ResponsiveScaffold extends StatefulWidget {
  static const double mobileBreakpoint = 640;
  static const double sidebarOverlayBreakpoint = 1024;
  static bool desktopSidebarCollapsed = false;
  static bool desktopSidebarHidden = false;

  final String role;
  final Widget child;
  final String? title;

  const ResponsiveScaffold({
    super.key,
    required this.role,
    required this.child,
    this.title,
  });

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < mobileBreakpoint;
  }

  static bool useOverlaySidebar(BuildContext context) {
    return MediaQuery.sizeOf(context).width < sidebarOverlayBreakpoint;
  }

  static EdgeInsets pagePadding(
    BuildContext context, {
    double desktop = 40,
    double mobile = 16,
  }) {
    return EdgeInsets.all(isMobile(context) ? mobile : desktop);
  }

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pageEntranceController;
  late final Animation<double> _pageFadeAnimation;
  late final Animation<double> _pageScaleAnimation;
  late bool _isDesktopSidebarCollapsed;
  late bool _isDesktopSidebarHidden;
  bool _isOverlaySidebarOpen = false;

  @override
  void initState() {
    super.initState();
    _pageEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    final pageEntranceCurve = CurvedAnimation(
      parent: _pageEntranceController,
      curve: Curves.easeOutQuart,
    );
    _pageFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(pageEntranceCurve);
    _pageScaleAnimation = Tween<double>(
      begin: 0.985,
      end: 1,
    ).animate(pageEntranceCurve);
    _isDesktopSidebarCollapsed = ResponsiveScaffold.desktopSidebarCollapsed;
    _isDesktopSidebarHidden = ResponsiveScaffold.desktopSidebarHidden;
    _pageEntranceController.forward();
  }

  @override
  void dispose() {
    _pageEntranceController.dispose();
    super.dispose();
  }

  double get _desktopSidebarWidth {
    if (_isDesktopSidebarHidden) return 0;
    return _isDesktopSidebarCollapsed ? 88 : 260;
  }

  double _overlaySidebarWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width < 420 ? width * 0.84 : 280;
  }

  void _toggleDesktopSidebar() {
    setState(() {
      _isDesktopSidebarHidden = false;
      _isDesktopSidebarCollapsed = !_isDesktopSidebarCollapsed;
      ResponsiveScaffold.desktopSidebarHidden = _isDesktopSidebarHidden;
      ResponsiveScaffold.desktopSidebarCollapsed = _isDesktopSidebarCollapsed;
    });
  }

  void _hideDesktopSidebar() {
    setState(() {
      _isDesktopSidebarHidden = true;
      ResponsiveScaffold.desktopSidebarHidden = true;
    });
  }

  void _showDesktopSidebar() {
    setState(() {
      _isDesktopSidebarHidden = false;
      ResponsiveScaffold.desktopSidebarHidden = false;
    });
  }

  void _openOverlaySidebar() {
    setState(() {
      _isOverlaySidebarOpen = true;
    });
  }

  void _closeOverlaySidebar() {
    setState(() {
      _isOverlaySidebarOpen = false;
    });
  }

  Widget _buildAnimatedPage(Widget child) {
    return FadeTransition(
      opacity: _pageFadeAnimation,
      child: ScaleTransition(
        scale: _pageScaleAnimation,
        alignment: Alignment.topCenter,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final useOverlaySidebar = ResponsiveScaffold.useOverlaySidebar(context);

    if (!useOverlaySidebar) {
      return Scaffold(
        body: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              width: _desktopSidebarWidth,
              child:
                  _isDesktopSidebarHidden
                      ? const SizedBox.shrink()
                      : Sidebar(
                        role: widget.role,
                        isCollapsed: _isDesktopSidebarCollapsed,
                        onToggleCollapse: _toggleDesktopSidebar,
                        onHide: _hideDesktopSidebar,
                      ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _buildAnimatedPage(widget.child)),
                  if (_isDesktopSidebarHidden)
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Material(
                        color: AppColors.primaryPurple,
                        elevation: 6,
                        borderRadius: BorderRadius.circular(14),
                        child: IconButton(
                          tooltip: 'Tampilkan sidebar',
                          onPressed: _showDesktopSidebar,
                          icon: const Icon(Icons.menu, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildAnimatedPage(widget.child)),
            Positioned(
              top: 16,
              left: 16,
              child: Material(
                color: AppColors.primaryPurple,
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                child: IconButton(
                  tooltip: _isOverlaySidebarOpen ? 'Tutup sidebar' : 'Buka sidebar',
                  onPressed:
                      _isOverlaySidebarOpen
                          ? _closeOverlaySidebar
                          : _openOverlaySidebar,
                  icon: Icon(
                    _isOverlaySidebarOpen ? Icons.close : Icons.menu,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (_isOverlaySidebarOpen) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeOverlaySidebar,
                  child: Container(color: Colors.black.withOpacity(0.22)),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: Material(
                  elevation: 10,
                  child: SizedBox(
                    width: _overlaySidebarWidth(context),
                    child: Sidebar(
                      role: widget.role,
                      isOverlay: true,
                      onCloseOverlay: _closeOverlaySidebar,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
