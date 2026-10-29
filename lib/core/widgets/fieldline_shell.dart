import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/account_sheet.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/offline_audit/presentation/controllers/audit_records_provider.dart';
import '../../features/workspace/data/workspace_settings.dart';
import '../../features/offline_audit/presentation/controllers/auto_sync_controller.dart';
import '../network/connectivity_provider.dart';
import '../theme/fieldline_theme.dart';
import '../utils/responsive_layout.dart';
import 'fieldline_widgets.dart';

class _NavItem {
  const _NavItem(this.label, this.icon, this.route, {this.matches = const []});

  final String label;
  final IconData icon;
  final String? route;

  /// Các route khác cũng làm mục này sáng lên.
  final List<String> matches;

  bool isActive(String location) {
    if (route == null) return false;
    if (route == '/') return location == '/';
    return location.startsWith(route!) ||
        matches.any((m) => location.startsWith(m));
  }
}

const _fieldItems = [
  _NavItem('Tổng quan', Icons.grid_view_outlined, '/'),
  _NavItem('Tài sản & thiết bị', Icons.inventory_2_outlined, '/assets'),
  _NavItem('Quét mã & AI', Icons.qr_code_scanner_rounded, '/scanner'),
  _NavItem(
    'Phiếu kiểm kê',
    Icons.description_outlined,
    '/audit-form',
    matches: ['/signature'],
  ),
  _NavItem('Báo cáo', Icons.bar_chart_rounded, '/reports'),
  _NavItem('Đồng bộ dữ liệu', Icons.sync_rounded, '/sync'),
];

const _workspaceItems = [
  _NavItem('Địa điểm', Icons.location_on_outlined, '/locations'),
  _NavItem('Cài đặt', Icons.settings_outlined, '/settings'),
];

const _mobileItems = [
  _NavItem('Tổng quan', Icons.radio_button_checked_rounded, '/'),
  _NavItem('Tài sản', Icons.crop_square_rounded, '/assets'),
  _NavItem('Quét mã', Icons.search_rounded, '/scanner'),
  _NavItem(
    'Phiếu',
    Icons.view_list_rounded,
    '/reports',
    matches: ['/audit-form', '/signature', '/sync'],
  ),
];

const _pageTitles = {
  '/assets': 'Tài sản & thiết bị',
  '/scanner': 'Quét mã & nhận diện AI',
  '/audit-form': 'Lập phiếu kiểm kê',
  '/signature': 'Ký xác nhận kiểm kê',
  '/reports': 'Báo cáo kiểm kê',
  '/sync': 'Đồng bộ dữ liệu',
  '/locations': 'Địa điểm',
  '/settings': 'Cài đặt',
};

/// Khung ứng dụng Fieldline: sidebar + thanh trên cho desktop/web,
/// thanh điều hướng dưới cho mobile.
class FieldlineShell extends ConsumerWidget {
  const FieldlineShell({
    super.key,
    required this.location,
    required this.child,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Luôn theo dõi trạng thái mạng để checkOnline() đọc được ở mọi màn,
    // kể cả trên mobile (không có thanh trên hiển thị trạng thái).
    ref.watch(isOnlineProvider);
    // Bộ tự đồng bộ chạy nền suốt lúc app mở (Card 24).
    ref.watch(autoSyncProvider);
    if (ResponsiveLayout.isDesktop(context)) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(location: location),
            Expanded(
              child: Column(
                children: [
                  _TopBar(location: location),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Trang nền sáng: chữ thanh trạng thái màu tối. Header tối (Tổng quan,
    // Đồng bộ) tự bọc AnnotatedRegion sáng và được ưu tiên vì nằm sâu hơn.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: child,
        bottomNavigationBar: _BottomNav(location: location),
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.location});

  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingSyncCountProvider);
    final workspace = ref.watch(workspaceProvider);

    return Container(
      width: 232,
      color: FlColors.sidebar,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Gap(24),
              // Logo
              Row(
                children: [
                  const Gap(10),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: FlColors.logoTile,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.center_focus_strong_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const Gap(12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FIELDLINE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'INVENTORY & EDGE AI',
                        style: TextStyle(color: Color(0xFF82A5AE), fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(28),
              // Không gian làm việc
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: FlColors.sidebarCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Không gian làm việc',
                      style: TextStyle(
                        color: FlColors.sidebarSubtle,
                        fontSize: 10,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      workspace.siteName,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      workspace.shift,
                      style: const TextStyle(
                        color: FlColors.sidebarSubtle,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 24),
                  children: [
                    const _SidebarLabel('Quản lý hiện trường'),
                    for (final item in _fieldItems)
                      _SidebarTile(
                        item: item,
                        active: item.isActive(location),
                        badge: item.route == '/sync' && pending > 0
                            ? '$pending'
                            : null,
                      ),
                    const Gap(20),
                    const _SidebarLabel('Không gian làm việc'),
                    for (final item in _workspaceItems)
                      _SidebarTile(item: item, active: item.isActive(location)),
                  ],
                ),
              ),
              // Trạng thái ngoại tuyến
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: FlColors.sidebarOffline,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: FlColors.sidebarOfflineDot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Gap(8),
                        const Text(
                          'Sẵn sàng ngoại tuyến',
                          style: TextStyle(
                            color: Color(0xFFC9EEE6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                    const Text(
                      'Dữ liệu được lưu trên máy.\nTự đồng bộ khi có kết nối.',
                      style: TextStyle(
                        color: Color(0xFF8EAEB8),
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              const Divider(color: FlColors.sidebarCard),
              const _SidebarAccount(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tài khoản đang đăng nhập ở chân sidebar; chạm để xem và đăng xuất.
class _SidebarAccount extends ConsumerWidget {
  const _SidebarAccount();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(signedInUserProvider);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => showAccountSheet(context, ref),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: FlColors.avatar,
              child: Text(
                user?.initials ?? '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFEAF1F4),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    user?.role.label ?? '',
                    style: const TextStyle(
                      color: Color(0xFF91ABB6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarLabel extends StatelessWidget {
  const _SidebarLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 0, 0, 10),
      child: SectionLabel(text, color: FlColors.sidebarLabel),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.item, required this.active, this.badge});

  final _NavItem item;
  final bool active;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : FlColors.sidebarText;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: active ? FlColors.sidebarActive : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (item.route != null) {
              context.go(item.route!);
            } else {
              showFlSnack(context, '${item.label} đang được phát triển');
            }
          },
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 22,
                  decoration: BoxDecoration(
                    color: active ? FlColors.sidebarAccent : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(2),
                    ),
                  ),
                ),
                const Gap(15),
                Icon(item.icon, size: 18, color: color),
                const Gap(14),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: FlColors.sidebarBadge,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: FlColors.sidebarBadgeText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.location});

  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Chưa đọc được trạng thái mạng (hoặc nền tảng không hỗ trợ) thì coi như có mạng.
    final online = ref.watch(isOnlineProvider).value ?? true;
    final title =
        _pageTitles.entries
            .where((e) => location.startsWith(e.key))
            .map((e) => e.value)
            .firstOrNull ??
        'Tổng quan hiện trường';
    final wide = MediaQuery.sizeOf(context).width >= 1180;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: FlColors.surface,
        border: Border(bottom: BorderSide(color: FlColors.border)),
      ),
      child: Row(
        children: [
          const Text(
            'Không gian làm việc',
            style: TextStyle(fontSize: 13, color: FlColors.muted),
          ),
          const Gap(22),
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: FlColors.ink),
            ),
          ),
          const Spacer(),
          if (wide) ...[
            SizedBox(
              width: 286,
              height: 40,
              child: TextField(
                onSubmitted: (_) => context.go('/assets'),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tìm mã tài sản, phiếu kiểm kê…',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: FlColors.muted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: FlColors.muted,
                  ),
                  fillColor: FlColors.background,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(FlRadius.control),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(FlRadius.control),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Gap(32),
          ],
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: online ? FlColors.online : FlColors.warningStrong,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(8),
          Text(
            online ? 'Đã kết nối' : 'Ngoại tuyến',
            style: TextStyle(
              fontSize: 11,
              color: online ? FlColors.primary : FlColors.warning,
            ),
          ),
          const Gap(40),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 20,
                color: FlColors.muted,
              ),
              Positioned(
                right: 1,
                top: -1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: FlColors.notification,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const Gap(28),
          const AccountAvatar(),
          const Gap(10),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: FlColors.muted,
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FlColors.surface,
        border: Border(top: BorderSide(color: FlColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (final item in _mobileItems)
                Expanded(
                  child: _BottomNavItem(
                    item: item,
                    active: item.isActive(location),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({required this.item, required this.active});

  final _NavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? FlColors.primary : FlColors.muted;
    return InkWell(
      onTap: () => context.go(item.route!),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 22, color: color),
          const Gap(6),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
