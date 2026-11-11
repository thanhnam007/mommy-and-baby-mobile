import 'package:flutter_test/flutter_test.dart';
import 'package:mommy_baby/models/milk_warming_model.dart';
import 'package:mommy_baby/providers/milk_warming_provider.dart';

void main() {
  group('MilkWarmingModel and 2-Hour Rules Tests', () {
    test('MilkWarmingRecordModel.fromJson parses correctly', () {
      final json = {
        'id': 101,
        'user_id': 1,
        'baby_id': 2,
        'start_time': '2026-11-11T05:00:00Z',
        'end_time': '2026-11-11T05:05:30Z',
        'amount_ml': 120,
        'duration_seconds': 330,
        'status': 'completed',
        'notes': 'Sữa mẹ ngăn mát',
        'created_at': '2026-11-11T05:00:00Z',
        'updated_at': '2026-11-11T05:05:30Z',
      };

      final model = MilkWarmingRecordModel.fromJson(json);
      expect(model.id, 101);
      expect(model.amountMl, 120);
      expect(model.durationSeconds, 330);
      expect(model.formatDuration(), '5p 30s');
      expect(model.status, 'completed');
    });

    test('MilkWarmingStatusModel.fromJson parses 2-hour expired status', () {
      final json = {
        'active_warming': null,
        'last_completed_warming': {
          'id': 101,
          'user_id': 1,
          'baby_id': 2,
          'start_time': '2026-11-11T02:00:00Z',
          'end_time': '2026-11-11T02:05:00Z',
          'amount_ml': 150,
          'duration_seconds': 300,
          'status': 'completed',
          'created_at': '2026-11-11T02:00:00Z',
          'updated_at': '2026-11-11T02:05:00Z',
        },
        'seconds_since_last_warming': 7500, // > 7200 (quá 2h)
        'minutes_since_last_warming': 125,
        'is_over_2_hours': true,
        'status_label': 'needs_new_milk',
        'display_message': 'Cần hâm sữa mới',
        'safe_remaining_seconds': 0,
      };

      final status = MilkWarmingStatusModel.fromJson(json);
      expect(status.isOver2Hours, isTrue);
      expect(status.displayMessage, 'Cần hâm sữa mới');
      expect(status.statusLabel, 'needs_new_milk');
      expect(status.safeRemainingSeconds, 0);
      expect(status.lastCompletedWarming?.amountMl, 150);
    });

    test('MilkWarmingProvider formatting helpers', () {
      expect(MilkWarmingProvider.formatSecondsToDigital(45), '00:45');
      expect(MilkWarmingProvider.formatSecondsToDigital(330), '05:30');
      expect(MilkWarmingProvider.formatSecondsToDigital(3665), '1:01:05');

      expect(MilkWarmingProvider.formatSecondsToDurationText(45), '45s');
      expect(MilkWarmingProvider.formatSecondsToDurationText(125), '2p 5s');
      expect(MilkWarmingProvider.formatSecondsToDurationText(7325), '2g 2p 5s');
    });
  });
}
