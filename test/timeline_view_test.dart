import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mommy_baby/core/theme/app_theme.dart';
import 'package:mommy_baby/models/activity_model.dart';
import 'package:mommy_baby/models/baby_model.dart';
import 'package:mommy_baby/providers/activity_provider.dart';
import 'package:mommy_baby/providers/baby_provider.dart';
import 'package:mommy_baby/views/timeline/timeline_view.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'TimelineView renders 2x3 Bento filter grid, daily pulse summary, and grouped timeline nodes',
    (WidgetTester tester) async {
      final babyProvider = BabyProvider();
      await babyProvider.selectBaby(
        BabyModel(
          id: 1,
          name: 'Bé Bông',
          nickname: 'Bông',
          gender: 'girl',
          birthDate: '2026-05-01',
          ageText: '6 tháng',
        ),
      );

      final activityProvider = ActivityProvider();
      activityProvider.setTimelineForTesting([
        ActivityModel(
          id: 101,
          babyId: 1,
          activityType: 'sleeping',
          startTime: '2026-11-07T09:30:00',
          endTime: null,
          sleepQuality: 'good',
          createdAt: '2026-11-07T09:30:00',
        ),
        ActivityModel(
          id: 102,
          babyId: 1,
          activityType: 'feeding',
          feedingType: 'bottle_breast',
          amountMl: 120,
          durationMinutes: 15,
          startTime: '2026-11-07T08:00:00',
          endTime: '2026-11-07T08:15:00',
          notes: 'Bé bú ngoan hết bình',
          createdAt: '2026-11-07T08:00:00',
        ),
        ActivityModel(
          id: 103,
          babyId: 1,
          activityType: 'diaper',
          diaperType: 'both',
          startTime: '2026-11-07T07:15:00',
          endTime: '2026-11-07T07:15:00',
          createdAt: '2026-11-07T07:15:00',
        ),
        ActivityModel(
          id: 104,
          babyId: 1,
          activityType: 'bath',
          startTime: '2026-11-07T16:30:00',
          endTime: '2026-11-07T16:45:00',
          createdAt: '2026-11-07T16:30:00',
        ),
      ]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BabyProvider>.value(value: babyProvider),
            ChangeNotifierProvider<ActivityProvider>.value(value: activityProvider),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: TimelineView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. All 6 Bento category filter tiles are visible without scrolling
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Cữ bú'), findsOneWidget);
      expect(find.text('Ăn dặm'), findsOneWidget);
      expect(find.text('Giấc ngủ'), findsOneWidget);
      expect(find.text('Thay tã'), findsOneWidget);
      expect(find.text('Tắm & Khác'), findsOneWidget);

      // 2. Category counts are accurate (all=4, feeding=1, solid=0, sleeping=1, diaper=1, other=1)
      expect(activityProvider.categoryCounts['all'], 4);
      expect(activityProvider.categoryCounts['other'], 1);

      // 3. Timeline cards & semantic metric badges are displayed
      expect(find.text('🟣 ĐANG NGỦ'), findsOneWidget);
      expect(find.text('+120 ml'), findsOneWidget);
      expect(find.text('💧💩 Tè + Ị'), findsOneWidget);
      expect(find.text('Bé bú ngoan hết bình'), findsOneWidget);

      // 4. Tap "Cữ bú" tile -> filters immediately to only feeding item
      await tester.tap(find.text('Cữ bú'));
      await tester.pumpAndSettle();

      expect(activityProvider.selectedType, 'feeding');
      expect(find.text('+120 ml'), findsOneWidget);
      expect(find.text('🟣 ĐANG NGỦ'), findsNothing);

      // 5. Tap "Cữ bú" again -> toggles back to "all"
      await tester.tap(find.text('Cữ bú'));
      await tester.pumpAndSettle();
      expect(activityProvider.selectedType, 'all');
      expect(find.text('🟣 ĐANG NGỦ'), findsOneWidget);

      // 6. Tap "Ăn dặm" (0 items) -> shows filtered empty state with reset button
      await tester.tap(find.text('Ăn dặm'));
      await tester.pumpAndSettle();
      expect(find.text('Xem tất cả hoạt động'), findsOneWidget);

      await tester.tap(find.text('Xem tất cả hoạt động'));
      await tester.pumpAndSettle();
      expect(activityProvider.selectedType, 'all');
    },
  );
}
