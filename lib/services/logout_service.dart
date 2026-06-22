import 'package:flutter/material.dart';

import '../src/state/cinema_store.dart';
import 'analytics_service.dart';
import 'auth_service.dart';

class LogoutService {
  static bool _isSigningOut = false;

  /// Hiển thị dialog xác nhận đăng xuất, sau đó thực hiện nếu người dùng đồng ý.
  static Future<void> signOut({
    required BuildContext context,
    required CinemaStore store,
  }) async {
    if (_isSigningOut) return;

    // ── Hỏi xác nhận ──────────────────────────────────────────
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFFFEEEE),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.logout_rounded,
            color: Color(0xFFD04747),
            size: 26,
          ),
        ),
        title: const Text(
          'Đăng xuất',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất không?\nPhiên đăng nhập hiện tại sẽ kết thúc.',
          textAlign: TextAlign.center,
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF71788A),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Huỷ',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD04747),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return; // người dùng nhấn Huỷ

    // ── Thực hiện đăng xuất ────────────────────────────────────
    _isSigningOut = true;

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Đang đăng xuất...'),
          duration: Duration(milliseconds: 900),
        ),
      );

    try {
      await AuthService().signOut().timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('LogoutService: remote sign-out failed: $e');
    } finally {
      try {
        await AnalyticsService.instance.trackLogout();
      } catch (_) {}
      store.logout();
      _isSigningOut = false;
    }

    if (!context.mounted) return;
    final messenger2 = ScaffoldMessenger.maybeOf(context);
    messenger2
      ?..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('Đăng xuất thành công')),
      );
  }
}
