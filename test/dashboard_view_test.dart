import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mommy_baby/core/theme/app_theme.dart';
import 'package:mommy_baby/models/activity_model.dart';
import 'package:mommy_baby/models/baby_model.dart';
import 'package:mommy_baby/providers/activity_provider.dart';
import 'package:mommy_baby/providers/baby_provider.dart';
import 'package:mommy_baby/providers/growth_provider.dart';
import 'package:mommy_baby/providers/pumping_provider.dart';
import 'package:mommy_baby/views/dashboard/dashboard_view.dart';
import 'package:mommy_baby/views/timeline/widgets/activity_timeline_row.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget({
    required BabyProvider babyProvider,
    required ActivityProvider activityProvider,
    required GrowthProvider growthProvider,
    required PumpingProvider pumpingProvider,
    required Function(int) onTabChange,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BabyProvider>.value(value: babyProvider),
        ChangeNotifierProvider<ActivityProvider>.value(value: activityProvider),
        ChangeNotifierProvider<GrowthProvider>.value(value: growthProvider),
        ChangeNotifierProvider<PumpingProvider>.value(value: pumpingProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: DashboardView(onTabChange: onTabChange),
        ),
      ),
    );
  }

  testWidgets(
    'DashboardView renders baby hero, bento grid 2x2, and feeding breakdown redirect to timeline',
    (WidgetTester tester) async {
      final babyProvider = BabyProvider();
      await babyProvider.selectBaby(
        BabyModel(
          id: 1,
          name: 'Bé Bơ',
          nickname: 'Bơ',
          gender: 'girl',
          birthDate: '2026-05-01',
          ageText: '6 tháng 9 ngày',
        ),
      );

      final activityProvider = ActivityProvider();
      activityProvider.setSummariesForTesting(
        feedingSummary: FeedingSummaryModel(
          feedingCount: 4,
          totalMl: 380,
          totalNursingMinutes: 35,
          breastCount: 2,
          breastNursingMinutes: 35,
          bottleCount: 2,
          formulaCount: 1,
          formulaMl: 200,
          bottleBreastCount: 1,
          bottleBreastMl: 180,
          isCurrentlyFeeding: false,
        ),
        sleepSummary: SleepSummaryModel(
          sleepCount: 2,
          totalSleepMinutes: 1496,
          totalSleepFormatted: '24g 56p',
          isCurrentlySleeping: false,
        ),
      );

      activityProvider.setTimelineForTesting([
        ActivityModel(
          id: 201,
          babyId: 1,
          activityType: 'sleeping',
          startTime: '2026-11-08T00:00:00',
          endTime: '2026-11-08T00:56:00',
          sleepQuality: 'good',
          createdAt: '2026-11-08T00:00:00',
        ),
        ActivityModel(
          id: 202,
          babyId: 1,
          activityType: 'feeding',
          feedingType: 'direct_breast',
          durationMinutes: 15,
          breastSide: 'left',
          startTime: '2026-11-07T21:45:00',
          endTime: '2026-11-07T22:00:00',
          createdAt: '2026-11-07T21:45:00',
        ),
      ]);

      final growthProvider = GrowthProvider();
      final pumpingProvider = PumpingProvider();

      int? redirectedTab;

      await tester.pumpWidget(
        buildTestableWidget(
          babyProvider: babyProvider,
          activityProvider: activityProvider,
          growthProvider: growthProvider,
          pumpingProvider: pumpingProvider,
          onTabChange: (tab) {
            redirectedTab = tab;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Check Baby name and age in hero
      expect(find.text('Bé Bơ'), findsOneWidget);
      expect(find.text('(Bơ)'), findsOneWidget);
      expect(find.textContaining('6 tháng 9 ngày'), findsOneWidget);

      // Check Bento Grid 2x2 items
      expect(find.text('Tăng trưởng WHO'), findsOneWidget);
      expect(find.text('Hút sữa của mẹ'), findsOneWidget);
      expect(find.text('Kho ảnh VIP'), findsOneWidget);
      expect(find.text('Nhắc nhở bé'), findsOneWidget);

      // Check feeding breakdown title and ratio
      expect(find.text('Phân loại cữ bú hôm nay'), findsOneWidget);
      expect(find.textContaining('380ml'), findsWidgets);

      // Check Timeline elements in recent activities
      expect(find.byType(ActivityTimelineRow), findsNWidgets(2));

      // Tap on Feeding Breakdown card and verify redirect to timeline (tab 1) with filter 'feeding'
      await tester.tap(find.text('Phân loại cữ bú hôm nay'));
      await tester.pumpAndSettle();

      expect(redirectedTab, equals(1));
      expect(activityProvider.selectedType, equals('feeding'));
    },
  );

  testWidgets(
    'DashboardView disables buttons and shows loading spinner when action is loading to prevent duplicate clicks',
    (WidgetTester tester) async {
      final babyProvider = BabyProvider();
      await babyProvider.selectBaby(
        BabyModel(
          id: 1,
          name: 'Bé Bơ',
          gender: 'boy',
          birthDate: '2026-05-01',
          ageText: '6 tháng',
        ),
      );

      final activityProvider = ActivityProvider();
      activityProvider.setSummariesForTesting(
        isFeedingActionLoading: true,
        isSleepActionLoading: true,
      );

      final growthProvider = GrowthProvider();
      final pumpingProvider = PumpingProvider();

      await tester.pumpWidget(
        buildTestableWidget(
          babyProvider: babyProvider,
          activityProvider: activityProvider,
          growthProvider: growthProvider,
          pumpingProvider: pumpingProvider,
          onTabChange: (_) {},
        ),
      );
      await tester.pump();

      // Check that loading indicator text "Đang xử lý..." appears on both feeding and sleep buttons
      expect(find.text('Đang xử lý...'), findsNWidgets(2));
      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));

      // Find the elevated buttons and confirm they are disabled (onPressed == null)
      final buttons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton)).toList();
      expect(buttons.length, greaterThanOrEqualTo(2));
      expect(buttons[0].onPressed, isNull);
      expect(buttons[1].onPressed, isNull);
    },
  );
}
