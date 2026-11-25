import 'package:flutter_test/flutter_test.dart';
import 'package:gymos_mobile/main.dart';

void main() {
  testWidgets('App initializes', (WidgetTester tester) async {
    await tester.pumpWidget(const GymOSApp());
  });
}
