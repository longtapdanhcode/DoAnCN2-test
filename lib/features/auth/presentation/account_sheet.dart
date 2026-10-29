import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_records_provider.dart';

import '../domain/app_user.dart';
import 'auth_providers.dart';

/// Ảnh đại diện chữ cái đầu của tài khoản đang đăng nhập; chạm để mở
/// [showAccountSheet].
class AccountAvatar extends ConsumerWidget {
  const AccountAvatar({
    super.key,
    this.radius = 17,
    this.background = FlColors.primaryTint,
    this.foreground = FlColors.primary,
  });

  final double radius;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(signedInUserProvider);
    return Semantics(
      button: true,
      label: 'Tài khoản',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showAccountSheet(context, ref),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: background,
          child: Text(
            user?.initials ?? '?',
            style: TextStyle(
              color: foreground,
              fontSize: radius * 0.72,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Thông tin tài khoản và nút đăng xuất.
Future<void> showAccountSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final user = ref.watch(signedInUserProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (user != null) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: FlColors.primaryTint,
                        child: Text(
                          user.initials,
                          style: const TextStyle(
                            color: FlColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Gap(14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: FlColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusPill(
                        label: user.role.label,
                        tone: user.role == UserRole.admin
                            ? FlTone.info
                            : FlTone.success,
                      ),
                    ],
                  ),
                  const Gap(24),
                ],
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Địa điểm'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    GoRouter.of(context).push('/locations');
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Cài đặt'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    GoRouter.of(context).push('/settings');
                  },
                ),
                const Gap(12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await confirmSignOut(context, ref);
                    if (!ok) return;
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    await ref.read(authRepositoryProvider).signOut();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Đăng xuất'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Hỏi lại trước khi đăng xuất (báo số phiếu chưa đồng bộ nếu có).
Future<bool> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final pending = ref.read(pendingSyncCountProvider);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Đăng xuất?'),
      content: Text(
        pending > 0
            ? 'Còn $pending phiếu chưa đồng bộ. Phiếu vẫn nằm trên máy và sẽ được gửi khi đăng nhập lại. Cần có mạng để đăng nhập lại.'
            : 'Cần có mạng để đăng nhập lại.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Đăng xuất'),
        ),
      ],
    ),
  );
  return result ?? false;
}
