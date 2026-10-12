import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/canvas_signature/presentation/screens/signature_screen.dart';
import '../../features/edge_vision/presentation/screens/scanner_screen.dart';
import '../../features/offline_audit/presentation/screens/audit_form_screen.dart';
import '../../features/report_dashboard/presentation/screens/dashboard_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter goRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (BuildContext context, GoRouterState state) =>
            const DashboardScreen(),
      ),
      GoRoute(
        path: '/scanner',
        name: 'scanner',
        builder: (BuildContext context, GoRouterState state) =>
            const ScannerScreen(),
      ),
      GoRoute(
        path: '/audit-form',
        name: 'audit-form',
        builder: (BuildContext context, GoRouterState state) {
          final extra = state.extra as Map<String, dynamic>?;
          final scanCode = extra?['scanCode'] as String? ?? '';
          final aiLabel = extra?['aiLabel'] as String?;
          return AuditFormScreen(
            initialScanCode: scanCode,
            initialAiLabel: aiLabel,
          );
        },
      ),
      GoRoute(
        path: '/signature',
        name: 'signature',
        builder: (BuildContext context, GoRouterState state) =>
            const SignatureScreen(),
      ),
    ],
  );
}
