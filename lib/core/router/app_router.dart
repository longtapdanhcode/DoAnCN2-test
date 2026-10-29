import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:field_inventory_edge_ai/features/asset_catalog/presentation/screens/asset_conflicts_screen.dart';
import 'package:field_inventory_edge_ai/features/auth/presentation/auth_providers.dart';
import 'package:field_inventory_edge_ai/features/auth/presentation/screens/auth_screens.dart';
import 'package:field_inventory_edge_ai/features/workspace/presentation/screens/locations_screen.dart';
import 'package:field_inventory_edge_ai/features/workspace/presentation/screens/settings_screen.dart';

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

const _authPaths = {'/login', '/register'};

@riverpod
GoRouter goRouter(Ref ref) {
  final auth = ref.watch(authRepositoryProvider);

  // Đăng nhập/đăng xuất thì tính lại điều hướng (Card 26).
  final authChanged = ValueNotifier(0);
  ref.listen(currentUserProvider, (_, _) => authChanged.value++);
  ref.onDispose(authChanged.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authChanged,
    // Bắt buộc đăng nhập. Phiên được giữ trên máy nên vẫn vào thẳng app khi
    // ngoại tuyến sau lần đăng nhập đầu.
    redirect: (context, state) {
      final signedIn = auth.currentUser != null;
      final atAuth = _authPaths.contains(state.uri.path);
      if (!signedIn && !atAuth) return '/login';
      if (signedIn && atAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _tab(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => _tab(state, const RegisterScreen()),
      ),
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
            pageBuilder: (context, state) {
              // Mở từ màn Địa điểm: lọc sẵn theo khu vực.
              final area = state.uri.queryParameters['area'];
              return _tab(
                state,
                AssetsScreen(key: ValueKey(area), initialArea: area),
              );
            },
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
            path: '/locations',
            name: 'locations',
            pageBuilder: (context, state) =>
                _tab(state, const LocationsScreen()),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) =>
                _tab(state, const SettingsScreen()),
          ),
          GoRoute(
            path: '/sync',
            name: 'sync',
            pageBuilder: (context, state) => _tab(state, const SyncScreen()),
            routes: [
              GoRoute(
                path: 'conflicts',
                name: 'sync-conflicts',
                builder: (context, state) => const AssetConflictsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
