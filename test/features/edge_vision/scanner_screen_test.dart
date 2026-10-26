import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:field_inventory_edge_ai/features/edge_vision/presentation/controllers/scanner_controller.dart';
import 'package:field_inventory_edge_ai/features/edge_vision/presentation/screens/scanner_screen.dart';

/// Controller giả: không đụng tới camera hay quyền hệ thống.
class _FakeScannerController extends ScannerController {
  @override
  ScannerUiState build() =>
      const ScannerUiState(status: ScannerStatus.scanning);

  @override
  Future<void> initialize() async {}

  @override
  Future<void> onAppInactive() async {}

  @override
  Future<void> resumeScanning() async {}
}

void main() {
  testWidgets(
    'Manual code dialog opens the audit form without disposed-controller errors',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      String? openedCode;
      final router = GoRouter(
        initialLocation: '/scanner',
        routes: [
          GoRoute(
            path: '/scanner',
            builder: (context, state) => const Scaffold(body: ScannerScreen()),
          ),
          GoRoute(
            path: '/audit-form',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              openedCode = extra?['scanCode'] as String?;
              return const Scaffold(body: Text('audit form'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scannerControllerProvider.overrideWith(_FakeScannerController.new),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      // Vòng quay chờ camera chạy liên tục nên dùng pump theo thời gian
      // thay cho pumpAndSettle.
      Future<void> settle() async {
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await tester.tap(find.byTooltip('Nhập mã thủ công'));
      await settle();

      await tester.enterText(find.byType(TextField), 'TS-DC-0142');
      await tester.tap(find.text('Lập phiếu'));
      // Chạy hết hiệu ứng đóng hộp thoại: trước đây controller bị huỷ quá sớm
      // và ném "A TextEditingController was used after being disposed".
      await settle();

      expect(tester.takeException(), isNull);
      expect(openedCode, 'TS-DC-0142');
      expect(find.text('audit form'), findsOneWidget);
    },
  );
}
