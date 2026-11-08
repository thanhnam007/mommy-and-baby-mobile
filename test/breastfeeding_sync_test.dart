import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mommy_baby/core/theme/app_theme.dart';
import 'package:mommy_baby/models/activity_model.dart';
import 'package:mommy_baby/models/baby_model.dart';
import 'package:mommy_baby/providers/activity_provider.dart';
import 'package:mommy_baby/providers/baby_provider.dart';
import 'package:mommy_baby/views/timeline/activity_detail_sheet.dart';
import 'package:mommy_baby/views/quick_log/quick_log_sheet.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Breastfeeding Duration & Auto-sync Tests', () {
    testWidgets(
      'ActivityDetailSheet does not duplicate duration and nursing minutes in view mode',
      (WidgetTester tester) async {
        final act = ActivityModel(
          id: 201,
          babyId: 1,
          activityType: 'feeding',
          feedingType: 'breast',
          breastSide: 'left',
          durationMinutes: 20,
          nursingMinutes: 20,
          startTime: '2026-11-07T14:00:00',
          endTime: '2026-11-07T14:20:00',
          createdAt: '2026-11-07T14:00:00',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: ActivityDetailSheet(
                activity: act,
                babyId: 1,
                onUpdated: () {},
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // 1. Should show "Thời gian bú mẹ:" exactly once and highlighted
        expect(find.text('Thời gian bú mẹ:'), findsOneWidget);
        expect(find.text('20 phút'), findsOneWidget);

        // 2. Should NOT show redundant "Tổng thời lượng:" for breast feeding
        expect(find.text('Tổng thời lượng:'), findsNothing);
      },
    );

    testWidgets(
      'QuickLogSheet: When start and end are equal, duration defaults to 0 minutes, NOT 15 minutes',
      (WidgetTester tester) async {
        final babyProvider = BabyProvider();
        await babyProvider.selectBaby(
          BabyModel(
            id: 1,
            name: 'Bé Bông',
            gender: 'girl',
            birthDate: '2026-05-01',
            ageText: '6 tháng',
          ),
        );
        final activityProvider = ActivityProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<BabyProvider>.value(value: babyProvider),
              ChangeNotifierProvider<ActivityProvider>.value(value: activityProvider),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: QuickLogSheet(),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Tap "Bú mẹ" quick card
        await tester.tap(find.text('Bú mẹ'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Open End time picker
        await tester.tap(find.text('Để trống (Đang trong cữ chưa kết thúc)'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Tap OK on TimePicker
        await tester.tap(find.text('OK'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Since end time equals start time by default in time picker, duration must be '0' (not '15')
        expect(find.widgetWithText(TextField, '0'), findsOneWidget);
      },
    );
  });
}
