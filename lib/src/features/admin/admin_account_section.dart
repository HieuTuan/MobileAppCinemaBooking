import 'package:flutter/material.dart';

import '../../core/labels.dart';
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

  static const _staffPermissions = [
    'Soát vé',
    'Hỗ trợ quầy',
    'Trạng thái phòng',
    'Báo cáo sự cố',
    'Danh sách suất',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
        ...users.map(
          (user) => GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_roleIcon(user.role)),
              title: Text(
                user.fullName,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                '${user.email} • ${user.phone} • ${roleLabel(user.role, language: widget.store.language)}'
                '${user.permissions.isEmpty ? '' : ' • ${user.permissions.join(', ')}'}',
              ),
              trailing: Wrap(
                children: [
                  if (user.role == UserRole.staff)
                    IconButton(
                      tooltip: 'Phân quyền',
                      onPressed: () => _permissionsDialog(context, user),
                      icon: const Icon(Icons.security_rounded),
                    ),
                  Switch(
                    value: user.isActive,
                    onChanged: user.role == UserRole.admin
                        ? null
                        : (_) {
                            widget.store.toggleUserStatus(user.id);
                            setState(() {});
                          },
                  ),
                  if (user.role != UserRole.admin)
                    IconButton(
                      tooltip: 'Xóa tài khoản',
                      onPressed: () {
                        widget.store.deleteUser(user.id);
                        setState(() {});
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<AppUser> _filteredUsers() {
    final query = _search.text.trim().toLowerCase();
    return widget.store.users.where((user) {
      return query.isEmpty ||
          user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.phone.toLowerCase().contains(query);
    }).toList();
  }

  IconData _roleIcon(UserRole role) {
    return switch (role) {
      UserRole.admin => Icons.admin_panel_settings_rounded,
      UserRole.staff => Icons.badge_rounded,
      UserRole.customer => Icons.person_rounded,
    };
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
            onPressed: () {
              widget.store.addStaff(name.text.trim(), email.text.trim());
              Navigator.pop(context);
              setState(() {});
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
              onPressed: () {
                widget.store.updateUserPermissions(user.id, selected.toList());
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Lưu quyền'),
            ),
          ],
        ),
      ),
    );
  }
}
