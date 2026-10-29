import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/asset_catalog/presentation/screens/asset_editor_screen.dart';
import '../../features/asset_catalog/presentation/screens/assets_screen.dart';
import '../../features/canvas_signature/presentation/screens/signature_screen.dart';
import '../../features/edge_vision/presentation/screens/scanner_screen.dart';
import '../../features/offline_audit/presentation/screens/audit_form_screen.dart';
import '../../features/offline_audit/presentation/screens/sync_screen.dart';
import '../../features/report_dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/report_dashboard/presentation/screens/report_preview_screen.dart';
import '../../features/report_dashboard/presentation/screens/reports_screen.dart';
import '../widgets/fieldline_shell.dart';

part 'app_router.g.dart';

/// Trang không có hiệu ứng chuyển cho các mục điều hướng chính.
Page<void> _tab(GoRouterState state, Widget child) =>
    NoTransitionPage<void>(key: state.pageKey, child: child);

@riverpod
GoRouter goRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            FieldlineShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            pageBuilder: (context, state) =>
                _tab(state, const DashboardScreen()),
          ),
          GoRoute(
            path: '/assets',
            name: 'assets',
            pageBuilder: (context, state) => _tab(state, const AssetsScreen()),
            routes: [
              GoRoute(
                path: 'new',
                name: 'asset-new',
                builder: (context, state) => const AssetEditorScreen(),
              ),
              GoRoute(
                path: ':code',
                name: 'asset-edit',
                builder: (context, state) =>
                    AssetEditorScreen(code: state.pathParameters['code']),
              ),
            ],
          ),
          GoRoute(
            path: '/scanner',
            name: 'scanner',
            pageBuilder: (context, state) => _tab(state, const ScannerScreen()),
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
                draftId: extra?['draftId'] as int?,
              );
            },
          ),
          GoRoute(
            path: '/signature',
            name: 'signature',
            builder: (BuildContext context, GoRouterState state) =>
                SignatureScreen(
                  summary: state.extra is AuditSummary
                      ? state.extra! as AuditSummary
                      : null,
                ),
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            pageBuilder: (context, state) => _tab(state, const ReportsScreen()),
            routes: [
              GoRoute(
                path: 'preview',
                name: 'report-preview',
                builder: (context, state) => const ReportPreviewScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/sync',
            name: 'sync',
            pageBuilder: (context, state) => _tab(state, const SyncScreen()),
          ),
        ],
      ),
    ],
  );
}
