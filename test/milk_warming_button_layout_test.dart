import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mommy_baby/core/theme/app_theme.dart';
import 'package:mommy_baby/models/milk_warming_model.dart';
import 'package:mommy_baby/providers/baby_provider.dart';
import 'package:mommy_baby/providers/milk_warming_provider.dart';
import 'package:mommy_baby/views/dashboard/widgets/milk_warming_dashboard_card.dart';
import 'package:mommy_baby/views/milk_warming/milk_warming_view.dart';

class StubMilkWarmingProvider extends MilkWarmingProvider {
  bool _mockIsWarming = false;
  bool _mockIsOver2h = false;
  MilkWarmingRecordModel? _mockLastCompleted;
  MilkWarmingOverviewModel? _mockOverview;

  void setMockState({
    required bool isWarming,
    required bool isOver2h,
    MilkWarmingRecordModel? lastCompleted,
    MilkWarmingOverviewModel? overview,
  }) {
    _mockIsWarming = isWarming;
    _mockIsOver2h = isOver2h;
    _mockLastCompleted = lastCompleted;
    _mockOverview = overview;
  }

  @override
  bool get isWarming => _mockIsWarming;

  @override
  bool get liveIsOver2Hours => _mockIsOver2h;

  @override
  MilkWarmingOverviewModel? get overview => _mockOverview;

  @override
  Future<void> fetchStatus(int? babyId) async {}

  @override
  Future<void> fetchOverview(int? babyId, {String? startDate, String? endDate}) async {}

  @override
  MilkWarmingStatusModel? get status => MilkWarmingStatusModel(
        activeWarming: _mockIsWarming
            ? MilkWarmingRecordModel(
                id: 99,
                userId: 1,
                startTime: DateTime.now().toIso8601String(),
                amountMl: 120,
                durationSeconds: 0,
                status: 'warming',
                createdAt: DateTime.now().toIso8601String(),
                updatedAt: DateTime.now().toIso8601String(),
              )
            : null,
        lastCompletedWarming: _mockLastCompleted,
        secondsSinceLastWarming: _mockIsOver2h ? 7500 : 1800,
        isOver2Hours: _mockIsOver2h,
        statusLabel: _mockIsOver2h ? 'needs_new_milk' : 'safe',
        displayMessage: _mockIsOver2h ? 'Cần hâm sữa mới' : 'Sữa còn dùng được',
        safeRemainingSeconds: _mockIsOver2h ? 0 : 5400,
      );
}

void main() {
  group('MilkWarmingDashboardCard & Button Layout Tests', () {
    testWidgets('MilkWarmingDashboardCard renders without overflow on 360px viewport (idle state)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final stub = StubMilkWarmingProvider();
      stub.setMockState(isWarming: false, isOver2h: false, lastCompleted: null);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<MilkWarmingProvider>.value(
            value: stub,
            child: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: MilkWarmingDashboardCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final btnFinder = find.widgetWithText(ElevatedButton, 'Ghi nhanh lịch hâm');
      expect(btnFinder, findsOneWidget);

      final RenderBox btnBox = tester.renderObject(btnFinder);
      expect(btnBox.size.height, equals(40.0));

      final iconFinder = find.descendant(of: btnFinder, matching: find.byIcon(Icons.bolt_rounded));
      expect(iconFinder, findsOneWidget);
      final RenderBox iconBox = tester.renderObject(iconFinder);
      // Icon height should be 18, well within 40
      expect(iconBox.size.height, equals(18.0));

      final textFinder = find.descendant(of: btnFinder, matching: find.text('Ghi nhanh lịch hâm'));
      final RenderBox textBox = tester.renderObject(textFinder);
      // Text height should not be squashed to 10px
      expect(textBox.size.height, greaterThanOrEqualTo(12.0));

      stub.dispose();
    });

    testWidgets('MilkWarmingDashboardCard renders without overflow on 360px viewport (over 2h state)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final stub = StubMilkWarmingProvider();
      stub.setMockState(isWarming: false, isOver2h: true, lastCompleted: null);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<MilkWarmingProvider>.value(
            value: stub,
            child: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: MilkWarmingDashboardCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final btnFinder = find.widgetWithText(ElevatedButton, 'Ghi nhanh lịch hâm');
      expect(btnFinder, findsOneWidget);

      stub.dispose();
    });

    testWidgets('MilkWarmingDashboardCard renders without overflow on 360px viewport (safe state)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final stub = StubMilkWarmingProvider();
      stub.setMockState(
        isWarming: false,
        isOver2h: false,
        lastCompleted: MilkWarmingRecordModel(
          id: 1,
          userId: 1,
          startTime: DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
          endTime: DateTime.now().subtract(const Duration(minutes: 25)).toIso8601String(),
          amountMl: 150,
          durationSeconds: 300,
          status: 'completed',
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 25)).toIso8601String(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<MilkWarmingProvider>.value(
            value: stub,
            child: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: MilkWarmingDashboardCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final btnFinder = find.widgetWithText(ElevatedButton, 'Ghi nhanh lịch hâm');
      expect(btnFinder, findsOneWidget);

      stub.dispose();
    });

    testWidgets('MilkWarmingView FAB renders bolt icon and text cleanly', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final stub = StubMilkWarmingProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MilkWarmingProvider>.value(value: stub),
            ChangeNotifierProvider(create: (_) => BabyProvider()),
          ],
          child: const MaterialApp(
            home: MilkWarmingView(babyId: 1),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      expect(find.descendant(of: fabFinder, matching: find.byIcon(Icons.bolt_rounded)), findsOneWidget);
      expect(find.descendant(of: fabFinder, matching: find.text('Ghi nhanh lịch hâm')), findsOneWidget);

      stub.dispose();
    });
  });
}
