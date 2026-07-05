import 'package:flutter/material.dart';

import '../../../api/api_client.dart';
import '../../../models/admin_models.dart';
import '../../core/app_theme.dart';
import '../../models/app_models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../state/cinema_store.dart';

class AdminAccountSection extends StatefulWidget {
  const AdminAccountSection({super.key, required this.store});

  final CinemaStore store;

  @override
  State<AdminAccountSection> createState() => _AdminAccountSectionState();
}

class _AdminAccountSectionState extends State<AdminAccountSection> {
  final _search = TextEditingController();
  final _api = APIClient();
  bool _loading = false;
  List<AppUser>? _remoteUsers;

  static const _staffPermissions = [
    'Soát vé',
    'Hỗ trợ quầy',
    'Trạng thái phòng',
    'Báo cáo sự cố',
    'Danh sách suất',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final page = await _api.getAdminUsers(pageSize: 100);
      if (mounted) {
        setState(() {
          _remoteUsers = page.data.map(_appUserFromAdmin).toList();
        });
      }
    } catch (_) {
      // Keep local fallback data when backend is unavailable.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = _filteredUsers();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Tìm tài khoản theo tên, email hoặc số điện thoại',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        SectionTitle(
          title: 'Tài khoản và RBAC',
          action: FilledButton.icon(
            onPressed: () => _staffDialog(context),
            icon: const Icon(Icons.person_add_alt_rounded),
            label: const Text('Tạo Staff'),
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        ...users.map(_buildUserCard),
      ],
    );
  }

  Widget _buildUserCard(AppUser user) {
    final isAdmin = user.role == UserRole.admin;
    final isStaff = user.role == UserRole.staff;

    Color roleBg;
    Color roleText;
    String roleName;
    IconData roleIcon;
    switch (user.role) {
      case UserRole.admin:
        roleBg = const Color(0xFFEF4444).withValues(alpha: 0.12);
        roleText = const Color(0xFFB91C1C);
        roleName = 'Quản trị viên';
        roleIcon = Icons.admin_panel_settings_rounded;
        break;
      case UserRole.staff:
        roleBg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
        roleText = const Color(0xFFD97706);
        roleName = 'Nhân viên';
        roleIcon = Icons.badge_rounded;
        break;
      case UserRole.customer:
        roleBg = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        roleText = const Color(0xFF1D4ED8);
        roleName = 'Khách hàng';
        roleIcon = Icons.person_rounded;
        break;
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: roleBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(roleIcon, color: roleText, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isAdmin) ...[
                Text(
                  user.isActive ? 'Hoạt động' : 'Khóa',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: user.isActive
                        ? const Color(0xFF047857)
                        : const Color(0xFFB91C1C),
                  ),
                ),
                const SizedBox(width: 4),
                Switch(
                  value: user.isActive,
                  onChanged: (value) => _setUserActive(user, value),
                  activeThumbColor: const Color(0xFF10B981),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: roleBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  roleName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: roleText,
                  ),
                ),
              ),
              if (user.phone.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pearl,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        size: 10,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.phone,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              if (isStaff)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Phân quyền',
                  onPressed: () => _permissionsDialog(context, user),
                  icon: const Icon(
                    Icons.security_rounded,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                ),
              if (!isAdmin)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Xóa tài khoản',
                  onPressed: () => _deleteUser(user),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
            ],
          ),
          if (isStaff && user.permissions.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.line),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final perm in user.permissions)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      perm,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<AppUser> _filteredUsers() {
    final query = _search.text.trim().toLowerCase();
    final source = _remoteUsers ?? widget.store.users;
    return source.where((user) {
      return query.isEmpty ||
          user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.phone.toLowerCase().contains(query);
    }).toList();
  }

  AppUser _appUserFromAdmin(AdminUser user) {
    return AppUser(
      id: user.userId,
      fullName: user.fullName,
      email: user.email,
      password: '',
      phone: '',
      role: switch (user.role.toLowerCase()) {
        'admin' => UserRole.admin,
        'staff' => UserRole.staff,
        _ => UserRole.customer,
      },
      isActive: user.active,
      permissions: user.permissions,
    );
  }

  void _replaceRemoteUser(AppUser next) {
    setState(() {
      final current = _remoteUsers ?? widget.store.users;
      _remoteUsers = current
          .map((user) => user.id == next.id ? next : user)
          .toList();
    });
  }

  Future<void> _setUserActive(AppUser user, bool active) async {
    try {
      final updated = await _api.updateAdminUserStatus(user.id, active);
      _replaceRemoteUser(_appUserFromAdmin(updated));
    } catch (e) {
      _showSnack('Cập nhật trạng thái thất bại: $e', isError: true);
    }
  }

  Future<void> _deleteUser(AppUser user) async {
    try {
      await _api.deleteAdminUser(user.id);
      setState(() {
        final current = _remoteUsers ?? widget.store.users;
        _remoteUsers = current.where((item) => item.id != user.id).toList();
      });
    } catch (e) {
      _showSnack('Xóa tài khoản thất bại: $e', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _staffDialog(BuildContext context) {
    final name = TextEditingController(text: 'Nhân viên mới');
    final email = TextEditingController(text: 'new.staff@cineluxe.vn');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo tài khoản Staff'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Họ tên'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final created = await _api.createAdminUser(
                  CreateStaffUserRequest(
                    fullName: name.text.trim(),
                    email: email.text.trim(),
                    role: 'staff',
                    permissions: _staffPermissions.take(3).toList(),
                  ),
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                setState(() {
                  final next = _appUserFromAdmin(created.user);
                  _remoteUsers = [
                    next,
                    ...(_remoteUsers ?? widget.store.users),
                  ];
                });
                _showSnack(
                  'Đã tạo Staff. Mật khẩu tạm: ${created.temporaryPassword}',
                );
              } catch (e) {
                _showSnack('Tạo Staff thất bại: $e', isError: true);
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _permissionsDialog(BuildContext context, AppUser user) {
    final selected = user.permissions.toSet();
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Phân quyền ${user.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final permission in _staffPermissions)
                CheckboxListTile(
                  value: selected.contains(permission),
                  title: Text(permission),
                  onChanged: (value) {
                    setDialogState(() {
                      if (value == true) {
                        selected.add(permission);
                      } else {
                        selected.remove(permission);
                      }
                    });
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  final updated = await _api.updateAdminUserPermissions(
                    user.id,
                    selected.toList(),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _replaceRemoteUser(_appUserFromAdmin(updated));
                  _showSnack('Đã lưu quyền');
                } catch (e) {
                  _showSnack('Lưu quyền thất bại: $e', isError: true);
                }
              },
              child: const Text('Lưu quyền'),
            ),
          ],
        ),
      ),
    );
  }
}
