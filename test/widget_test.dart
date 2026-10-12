import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/main.dart';

void main() {
  testWidgets('App loads DashboardScreen smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Pump to let GoRouter resolve initial route and animations
    await tester.pumpAndSettle();

    // Verify that the AppBar title is displayed.
    expect(find.text('Field Inventory & Edge AI'), findsOneWidget);
  });
}
