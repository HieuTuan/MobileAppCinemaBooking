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
          'Bạn có chắc chắn muốn đăng xuất không?',
          textAlign: TextAlign.center,
          style: TextStyle(height: 1.5, fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF71788A),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white24,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFFC9A44C),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Đang đăng xuất...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
        SnackBar(
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E1A1A), Color(0xFF451A1A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFD04747).withValues(alpha: .5),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD04747).withValues(alpha: .15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD04747).withValues(alpha: .2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD04747).withValues(alpha: .5),
                    ),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFFF7A7A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Đăng xuất thành công',
                        style: TextStyle(
                          color: Color(0xFFFF7A7A),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Hẹn gặp lại bạn sớm! 🎬',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
