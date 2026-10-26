import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';
import 'package:field_inventory_edge_ai/features/canvas_signature/presentation/screens/signature_screen.dart';

/// Kích thước khung web 1440×1000 của Figma (bố cục desktop).
void useDesktopView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('SignatureScreen Widget Tests', () {
    Widget buildTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: SignatureScreen(
            summary: AuditSummary(
              scanCode: 'TS-DC-0142',
              label: 'Động cơ điện',
              name: '',
              area: 'Xưởng sản xuất A',
              quantity: 8,
              condition: 'Hoạt động tốt',
              conditionTone: FlTone.success,
              createdAt: DateTime(2026, 10, 22, 9, 44),
            ),
          ),
        ),
      );
    }

    testWidgets('Renders Signature canvas, action buttons, and title', (
      tester,
    ) async {
      useDesktopView(tester);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ký xác nhận kiểm kê'), findsOneWidget);
      expect(find.text('Chạm và kéo để ký'), findsOneWidget);
      expect(find.text('TS-DC-0142'), findsOneWidget);
      expect(find.byType(Signature), findsOneWidget);
      expect(find.text('Xóa và ký lại'), findsOneWidget);
      expect(find.text('Hoàn tất & lưu phiếu kiểm kê'), findsOneWidget);
    });

    testWidgets('Shows warning snackbar when confirming with empty canvas', (
      tester,
    ) async {
      useDesktopView(tester);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap confirm on empty canvas
      final confirm = find.text('Hoàn tất & lưu phiếu kiểm kê');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng ký tên trước khi hoàn tất!'), findsOneWidget);
    });

    testWidgets('Clear button is clickable and resets canvas', (tester) async {
      useDesktopView(tester);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final clearFinder = find.text('Xóa và ký lại');
      expect(clearFinder, findsOneWidget);
      await tester.ensureVisible(clearFinder);

      await tester.tap(clearFinder);
      await tester.pumpAndSettle();

      expect(find.byType(Signature), findsOneWidget);
    });

    testWidgets('Returns signature bytes with signer name and role', (
      tester,
    ) async {
      useDesktopView(tester);
      SignatureResult? result;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    result = await context.push<SignatureResult>('/signature'),
                child: const Text('open'),
              ),
            ),
          ),
          GoRoute(
            path: '/signature',
            builder: (context, state) =>
                const Scaffold(body: SignatureScreen()),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Vẽ một nét lên canvas và đổi tên người ký.
      final canvas = find.byType(Signature);
      await tester.ensureVisible(canvas);
      await tester.drag(canvas, const Offset(120, 30));
      await tester.enterText(
        find.widgetWithText(TextField, 'Hoàng An'),
        'Nguyễn Minh Anh',
      );
      await tester.pump();

      final confirm = find.text('Hoàn tất & lưu phiếu kiểm kê');
      await tester.ensureVisible(confirm);
      // Xuất PNG cần event loop thật nên chạy trong runAsync.
      await tester.runAsync(() async {
        await tester.tap(confirm);
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.bytes, isNotEmpty);
      expect(result!.signerName, 'Nguyễn Minh Anh');
      expect(result!.signerRole, 'Kiểm kê viên');
    });
  });
}
