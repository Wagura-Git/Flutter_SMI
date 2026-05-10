import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../shared/app_colors.dart';

class UserMentionWidget extends StatefulWidget {
  final List<User> selectedUsers;
  final Function(List<User>) onUsersChanged;
  final String hint;

  const UserMentionWidget({
    super.key,
    required this.selectedUsers,
    required this.onUsersChanged,
    this.hint = 'Cari pengguna untuk ditambahkan...',
  });

  @override
  State<UserMentionWidget> createState() => _UserMentionWidgetState();
}

class _UserMentionWidgetState extends State<UserMentionWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final result = await ApiService.searchUsers(
        token: token,
        query: query,
      );

      if (result['success']) {
        final users = result['users'] as List<User>;
        setState(() {
          // Filter out already selected users
          _searchResults = users
              .where((user) => !widget.selectedUsers
                  .any((selected) => selected.id == user.id))
              .toList();
          _isLoading = false;
        });

        // Show overlay
        if (_searchResults.isNotEmpty) {
          _showSearchOverlay();
        }
      } else {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  void _showSearchOverlay() {
    _overlayEntry?.remove();

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height,
        width: size.width,
        child: Material(
          elevation: 4,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  leading: CircleAvatar(
                    child: Text(user.name.substring(0, 1).toUpperCase()),
                  ),
                  onTap: () {
                    _selectUser(user);
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                    });
                    _overlayEntry?.remove();
                    _overlayEntry = null;
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _selectUser(User user) {
    final updatedList = [...widget.selectedUsers, user];
    widget.onUsersChanged(updatedList);
  }

  void _removeUser(User user) {
    final updatedList = widget.selectedUsers
        .where((u) => u.id != user.id)
        .toList();
    widget.onUsersChanged(updatedList);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Field
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: (value) {
              setState(() {
                _isSearching = value.isNotEmpty;
              });
              if (value.length > 1) {
                _searchUsers(value);
              } else {
                setState(() {
                  _searchResults = [];
                });
                _overlayEntry?.remove();
                _overlayEntry = null;
              }
            },
            decoration: InputDecoration(
              hintText: widget.hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              suffixIcon: _isLoading
                  ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Selected Users Display
        if (widget.selectedUsers.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedUsers
                .map(
                  (user) => Chip(
                    avatar: CircleAvatar(
                      child: Text(user.name.substring(0, 1).toUpperCase()),
                    ),
                    label: Text(user.name),
                    onDeleted: () => _removeUser(user),
                    backgroundColor: AppColors.bgTeal.withOpacity(0.3),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
