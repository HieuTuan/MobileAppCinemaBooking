import 'package:cine_book/src/app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CineLuxe auth screen renders', (tester) async {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is NetworkImageLoadException) return;
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(const CineBookingApp());

    expect(find.text('CineLuxe'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('Vào hệ thống'), findsOneWidget);
    expect(find.text('Truy cập nhanh'), findsOneWidget);
  });
}
