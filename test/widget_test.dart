import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remi/main.dart';

void main() {
  testWidgets('Remi app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RemiApp()));
    // Simply verify the app starts without crashing
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
