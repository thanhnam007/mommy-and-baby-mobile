import 'package:flutter_test/flutter_test.dart';
import 'package:mommy_baby/main.dart';

void main() {
  testWidgets('MommyBabyApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MommyBabyApp());
    expect(find.byType(MommyBabyApp), findsOneWidget);
  });
}
