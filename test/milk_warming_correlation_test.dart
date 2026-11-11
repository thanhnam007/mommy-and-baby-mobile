import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mommy_baby/models/activity_model.dart';
import 'package:mommy_baby/models/milk_warming_model.dart';
import 'package:mommy_baby/providers/activity_provider.dart';
import 'package:mommy_baby/providers/baby_provider.dart';
import 'package:mommy_baby/providers/milk_warming_provider.dart';
import 'package:mommy_baby/views/timeline/activity_detail_sheet.dart';
import 'package:mommy_baby/views/milk_warming/milk_warming_view.dart';

class _StubMilkWarmingProvider extends MilkWarmingProvider {
  MilkWarmingOverviewModel? _customOverview;

  void setTestOverview(MilkWarmingOverviewModel ov) {
    _customOverview = ov;
    notifyListeners();
  }

  @override
  MilkWarmingOverviewModel? get overview => _customOverview;

  @override
  Future<void> fetchStatus(int? babyId) async {}

  @override
  Future<void> fetchOverview(int? babyId, {String? startDate, String? endDate}) async {}
}

void main() {
  group('Milk Warming Correlation Models & UI Tests', () {
    test('ActivityModel and FeedingSummaryModel parse is_warmed & split stats accurately', () {
      final actWarmed = ActivityModel.fromJson({
        'id': 1,
        'baby_id': 10,
        'activity_type': 'feeding',
        'feeding_type': 'bottle_breast',
        'amount_ml': 120,
        'is_warmed': true,
        'start_time': '2026-11-11T08:00:00Z',
        'created_at': '2026-11-11T08:00:00Z',
      });
      expect(actWarmed.isWarmed, isTrue);

      final actDirect = ActivityModel.fromJson({
        'id': 2,
        'baby_id': 10,
        'activity_type': 'feeding',
        'feeding_type': 'bottle_breast',
        'amount_ml': 90,
        'is_warmed': false,
        'start_time': '2026-11-11T10:00:00Z',
        'created_at': '2026-11-11T10:00:00Z',
      });
      expect(actDirect.isWarmed, isFalse);

      final summary = FeedingSummaryModel.fromJson({
        'total_ml': 210,
        'total_nursing_minutes': 0,
        'feeding_count': 2,
        'is_currently_feeding': false,
        'bottle_count': 2,
        'bottle_total_ml': 210,
        'bottle_breast_count': 2,
        'bottle_breast_ml': 210,
        'bottle_breast_warmed_count': 1,
        'bottle_breast_warmed_ml': 120,
        'bottle_breast_direct_count': 1,
        'bottle_breast_direct_ml': 90,
      });

      expect(summary.bottleBreastWarmedCount, 1);
      expect(summary.bottleBreastWarmedMl, 120);
      expect(summary.bottleBreastDirectCount, 1);
      expect(summary.bottleBreastDirectMl, 90);
    });

    test('MilkWarmingOverviewModel parses today_correlation and group correlation', () {
      final overview = MilkWarmingOverviewModel.fromJson({
        'status': {
          'is_over_2_hours': false,
          'status_label': 'safe',
          'display_message': 'Sữa còn dùng được',
        },
        'today_total_ml': 250,
        'today_sessions_count': 2,
        'today_correlation': {
          'date': '2026-11-11',
          'display_date': 'Hôm nay, 11/11/2026',
          'warmed_total_ml': 250,
          'warmed_sessions_count': 2,
          'consumed_warmed_ml': 225,
          'consumed_warmed_count': 2,
          'consumed_direct_ml': 60,
          'consumed_direct_count': 1,
          'difference_ml': 25,
          'consumption_ratio_percent': 90.0,
          'status': 'optimal',
          'message': 'Tuyệt vời! Bé bú đạt 90.0% lượng sữa đã hâm (chỉ dư 25ml).',
        },
        'groups': [
          {
            'date_str': '2026-11-11',
            'display_date': 'Hôm nay, 11/11/2026',
            'total_amount_ml': 250,
            'sessions_count': 2,
            'records': [],
            'correlation': {
              'date': '2026-11-11',
              'display_date': 'Hôm nay, 11/11/2026',
              'warmed_total_ml': 250,
              'warmed_sessions_count': 2,
              'consumed_warmed_ml': 225,
              'consumed_warmed_count': 2,
              'consumed_direct_ml': 60,
              'consumed_direct_count': 1,
              'difference_ml': 25,
              'consumption_ratio_percent': 90.0,
              'status': 'optimal',
              'message': 'Tuyệt vời!',
            },
          }
        ],
      });

      expect(overview.todayCorrelation, isNotNull);
      expect(overview.todayCorrelation!.consumptionRatioPercent, 90.0);
      expect(overview.todayCorrelation!.differenceMl, 25);
      expect(overview.todayCorrelation!.consumedDirectMl, 60);
      expect(overview.groups.first.correlation?.consumedWarmedMl, 225);
    });

    testWidgets('ActivityDetailSheet shows warmed badge and edit checkbox for bottle_breast', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final act = ActivityModel(
        id: 99,
        babyId: 1,
        activityType: 'feeding',
        feedingType: 'bottle_breast',
        amountMl: 140,
        isWarmed: true,
        startTime: '2026-11-11T08:00:00Z',
        endTime: '2026-11-11T08:15:00Z',
        createdAt: '2026-11-11T08:00:00Z',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ActivityProvider()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ActivityDetailSheet(
                activity: act,
                babyId: 1,
                onUpdated: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // View mode shows warmed milk label
      expect(find.textContaining('Sữa mẹ đã hâm'), findsOneWidget);

      // Tap Edit button
      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Edit mode shows checkbox for Sữa mẹ đã hâm
      expect(find.textContaining('Sữa mẹ đã hâm (để lạnh / đông đem hâm)'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('MilkWarmingView renders Today Correlation Card cleanly', (WidgetTester tester) async {
      final stubWarmingProv = _StubMilkWarmingProvider();
      stubWarmingProv.setTestOverview(
        MilkWarmingOverviewModel(
          status: MilkWarmingStatusModel(statusLabel: 'none', displayMessage: 'Chưa có cữ hâm'),
          todayTotalMl: 300,
          todaySessionsCount: 2,
          todayCorrelation: MilkWarmingCorrelationModel(
            date: '2026-11-11',
            displayDate: 'Hôm nay',
            warmedTotalMl: 300,
            warmedSessionsCount: 2,
            consumedWarmedMl: 270,
            consumedWarmedCount: 2,
            consumedDirectMl: 80,
            consumedDirectCount: 1,
            differenceMl: 30,
            consumptionRatioPercent: 90.0,
            status: 'optimal',
            message: 'Tuyệt vời! Bé bú đạt 90.0% lượng sữa đã hâm.',
          ),
          groups: [],
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MilkWarmingProvider>.value(value: stubWarmingProv),
            ChangeNotifierProvider(create: (_) => BabyProvider()),
          ],
          child: const MaterialApp(
            home: MilkWarmingView(babyId: 1),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tương quan Hâm & Bú hôm nay'), findsOneWidget);
      expect(find.text('300 ml'), findsWidgets);
      expect(find.text('270 ml'), findsOneWidget);
      expect(find.text('Tỉ lệ bú / hâm: 90.0%'), findsOneWidget);
      expect(find.text('Dư/hao hụt: 30 ml'), findsOneWidget);
      expect(find.textContaining('80 ml (1 cữ)'), findsOneWidget);

      stubWarmingProv.dispose();
    });
  });
}
