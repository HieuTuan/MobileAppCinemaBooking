import 'package:cine_book/src/app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Cineverse Club login screen renders', (tester) async {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is NetworkImageLoadException) return;
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(const CineverseApp());

    expect(find.text('Cineverse Club'), findsOneWidget);
    expect(find.text('Dang nhap'), findsOneWidget);
    expect(find.text('VAO SANH CINEVERSE'), findsOneWidget);
  });
}
