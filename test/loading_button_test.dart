import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mommy_baby/core/widgets/loading_button.dart';

void main() {
  group('LoadingButton Tests', () {
    testWidgets('renders idle label and responds to tap', (WidgetTester tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              label: 'Lưu dữ liệu',
              loadingLabel: 'Đang lưu...',
              onPressed: () async {
                tapCount++;
              },
            ),
          ),
        ),
      );

      expect(find.text('Lưu dữ liệu'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('Lưu dữ liệu'));
      await tester.pump();
      expect(tapCount, 1);
    });

    testWidgets('shows loading indicator and prevents duplicate taps during async action', (WidgetTester tester) async {
      int tapCount = 0;
      final completer = Completer<void>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              label: 'Submit',
              loadingLabel: 'Đang xử lý...',
              onPressed: () async {
                tapCount++;
                await completer.future;
              },
            ),
          ),
        ),
      );

      // First tap
      await tester.tap(find.text('Submit'));
      await tester.pump(); // Start async action

      expect(tapCount, 1);
      // Button is now in loading state: shows spinner and loading label
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Đang xử lý...'), findsOneWidget);

      // Try tapping again while loading is active
      await tester.tap(find.byType(LoadingButton), warnIfMissed: false);
      await tester.pump();

      // Tap count must remain 1 (no duplicate execution)
      expect(tapCount, 1);

      // Complete async action
      completer.complete();
      await tester.pumpAndSettle();

      // Reverts back to idle label
      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
