import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signature/signature.dart';
import 'package:field_inventory_edge_ai/features/canvas_signature/presentation/screens/signature_screen.dart';

void main() {
  group('SignatureScreen Widget Tests', () {
    Widget buildTestWidget() {
      return const MaterialApp(
        home: SignatureScreen(),
      );
    }

    testWidgets('Renders Signature canvas, action buttons, and title', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ký xác nhận kiểm kê'), findsOneWidget);
      expect(
        find.text('Ký tên hoặc vẽ chú thích vào khung bên dưới'),
        findsOneWidget,
      );
      expect(find.byType(Signature), findsOneWidget);
      expect(find.text('Xóa lại'), findsOneWidget);
      expect(find.text('Xác nhận chữ ký'), findsOneWidget);
    });

    testWidgets(
      'Shows warning snackbar when confirming with empty canvas',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Tap confirm on empty canvas
        await tester.tap(find.text('Xác nhận chữ ký'));
        await tester.pumpAndSettle();

        expect(
          find.text('Vui lòng ký tên hoặc vẽ chú thích trước khi xác nhận!'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Clear button is clickable and resets canvas', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final clearFinder = find.text('Xóa lại');
      expect(clearFinder, findsOneWidget);

      await tester.tap(clearFinder);
      await tester.pumpAndSettle();

      expect(find.byType(Signature), findsOneWidget);
    });
  });
}
