import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mommy_baby/models/activity_model.dart';
import 'package:mommy_baby/providers/activity_provider.dart';
import 'package:mommy_baby/providers/baby_provider.dart';
import 'package:mommy_baby/views/timeline/activity_detail_sheet.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Overnight sleep displays distinct wake-up date and overnight tag', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final overnightSleep = ActivityModel(
      id: 99,
      babyId: 1,
      activityType: 'sleeping',
      startTime: '2026-11-08T14:30:00Z', // 21:30 local time
      endTime: '2026-11-09T00:00:00Z',   // 07:00 next day local time
      durationMinutes: 570, // 9h 30m
      sleepQuality: 'good',
      createdAt: '2026-11-08T14:30:00Z',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ActivityProvider()),
          ChangeNotifierProvider(create: (_) => BabyProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ActivityDetailSheet(
              activity: overnightSleep,
              babyId: 1,
              onUpdated: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify View Mode displays sleeping specific labels
    expect(find.text('Thời gian đi ngủ:'), findsOneWidget);
    expect(find.text('Thời gian thức dậy:'), findsOneWidget);
    expect(find.textContaining('Ngủ xuyên đêm'), findsOneWidget);
    expect(find.text('9 giờ 30 phút'), findsWidgets);

    // Switch to edit mode by tapping Chỉnh sửa
    final editBtn = find.textContaining('Chỉnh sửa');
    expect(editBtn, findsOneWidget);
    await tester.tap(editBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Edit Mode has both Ngày thức dậy and Giờ thức dậy
    expect(find.text('Ngày đi ngủ'), findsOneWidget);
    expect(find.text('Giờ đi ngủ'), findsOneWidget);
    expect(find.text('Ngày thức dậy'), findsOneWidget);
    expect(find.text('Giờ thức dậy'), findsOneWidget);
    expect(find.textContaining('Hôm sau (+1 ngày)'), findsOneWidget);
    expect(find.textContaining('Ngủ xuyên đêm 🌙'), findsOneWidget);
  });
}
