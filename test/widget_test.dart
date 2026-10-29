import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_records_provider.dart';
import 'package:field_inventory_edge_ai/features/auth/presentation/auth_providers.dart';
import 'package:field_inventory_edge_ai/main.dart';

import 'helpers/auth_fakes.dart';

void main() {
  testWidgets('App loads DashboardScreen smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          auditRecordsProvider.overrideWith((ref) => Stream.value(const [])),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(signedInAs: testUser),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // Pump to let GoRouter resolve initial route and animations
    await tester.pumpAndSettle();

    // Màn hình thử 800×600 dùng bố cục mobile: header Fieldline + thanh điều hướng.
    expect(find.text('FIELDLINE'), findsOneWidget);
    expect(find.text('Quét thiết bị'), findsOneWidget);
    expect(find.text('Tài sản'), findsWidgets);
  });
}
