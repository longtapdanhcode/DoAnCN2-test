import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_inventory_edge_ai/core/utils/responsive_layout.dart';

void main() {
  group('ResponsiveLayout Tests', () {
    testWidgets('Renders mobileBody when width < 800', (tester) async {
      tester.view.physicalSize = const Size(799, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobileBody: Text('Mobile Layout'),
            desktopBody: Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Mobile Layout'), findsOneWidget);
      expect(find.text('Desktop Layout'), findsNothing);
    });

    testWidgets('Renders desktopBody when width >= 800', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobileBody: Text('Mobile Layout'),
            desktopBody: Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Desktop Layout'), findsOneWidget);
      expect(find.text('Mobile Layout'), findsNothing);
    });
  });
}
