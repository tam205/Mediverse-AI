import 'package:flutter_test/flutter_test.dart';
import 'package:mediverse_ai/main.dart';

void main() {
  testWidgets('Mediverse app opens login through auth gate', (tester) async {
    await tester.pumpWidget(const MediverseApp());
    await tester.pump();

    expect(find.text('Mediverse AI'), findsOneWidget);
    expect(find.text('Good to see you again'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
