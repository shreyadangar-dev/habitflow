import 'package:flutter_test/flutter_test.dart';
import 'package:habitflow/app.dart';
void main() {
  testWidgets('HabitFlow smoke test', (t) async {
    await t.pumpWidget(const HabitFlowApp());
  });
}
