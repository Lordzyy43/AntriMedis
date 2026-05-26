import 'package:apps/core/widgets/app_error_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppErrorBanner renders message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppErrorBanner(message: 'Gagal memuat data antrean.'),
        ),
      ),
    );

    expect(find.text('Gagal memuat data antrean.'), findsOneWidget);
  });
}
