import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import 'package:field_inventory_edge_ai/core/utils/responsive_layout.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/isar_audit_repository_impl.dart';

/// Hàm dùng chung để xuất báo cáo PDF và mở hộp thoại chia sẻ hệ thống
Future<void> _exportPdfReport(BuildContext context, WidgetRef ref) async {
  try {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            Gap(12),
            Text('Đang tạo báo cáo PDF...'),
          ],
        ),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final repository = ref.read(auditRepositoryProvider);
    final bytes = await repository.exportPdfReport();

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'bao_cao_kiem_ke.pdf',
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xuất PDF: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Màn hình Dashboard chính tích hợp Responsive cho Mobile & Desktop
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileBody: MobileDashboard(),
      desktopBody: DesktopDashboard(),
    );
  }
}

/// Giao diện Dashboard cho thiết bị di động (Mobile)
class MobileDashboard extends ConsumerWidget {
  const MobileDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Inventory & Edge AI'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Xuất Báo cáo PDF',
            onPressed: () => _exportPdfReport(context, ref),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: Colors.blueAccent,
              ),
              const Gap(16),
              const Text(
                'Hệ Thống Kiểm Kê Hiện Trường',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(8),
              const Text(
                'Tích hợp Edge AI & Quét mã barcode/QR siêu tốc offline.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const Gap(24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.push('/scanner'),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Mở Máy Quét Mã'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _exportPdfReport(context, ref),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Xuất Báo cáo PDF'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/scanner'),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Quét mã'),
      ),
    );
  }
}

/// Giao diện Dashboard cho màn hình lớn Desktop/Web
class DesktopDashboard extends ConsumerStatefulWidget {
  const DesktopDashboard({super.key});

  @override
  ConsumerState<DesktopDashboard> createState() => _DesktopDashboardState();
}

class _DesktopDashboardState extends ConsumerState<DesktopDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Bên trái: Sidebar Menu (NavigationRail cố định ~250px)
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Sidebar: Logo & Tên ứng dụng
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Field Inventory',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Edge AI Desktop',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Danh sách Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    children: [
                      _SidebarItem(
                        icon: Icons.dashboard_rounded,
                        label: 'Bảng điều khiển',
                        isSelected: _selectedIndex == 0,
                        onTap: () => setState(() => _selectedIndex = 0),
                      ),
                      _SidebarItem(
                        icon: Icons.qr_code_scanner_rounded,
                        label: 'Máy quét mã',
                        isSelected: _selectedIndex == 1,
                        onTap: () => context.push('/scanner'),
                      ),
                      _SidebarItem(
                        icon: Icons.cloud_sync_rounded,
                        label: 'Đồng bộ Supabase',
                        isSelected: _selectedIndex == 2,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tính năng đồng bộ tự động đang hoạt động!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      _SidebarItem(
                        icon: Icons.settings_rounded,
                        label: 'Cài đặt hệ thống',
                        isSelected: _selectedIndex == 3,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cài đặt hệ thống'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Footer Sidebar: Nút xuất báo cáo nhanh
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: OutlinedButton.icon(
                    onPressed: () => _exportPdfReport(context, ref),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Xuất Báo cáo PDF'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bên phải: Nội dung chính
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top App Bar của Desktop
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Field Inventory & Edge AI',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Gap(16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            tooltip: 'Xuất Báo cáo PDF',
                            onPressed: () => _exportPdfReport(context, ref),
                          ),
                          const Gap(8),
                          FilledButton.icon(
                            onPressed: () => context.push('/scanner'),
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Quét mã kiểm kê'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main body: Lưới thẻ thống kê & tính năng (GridView)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chỉ số hoạt động',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(16),

                        // GridView thẻ thống kê
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;
                            return GridView.count(
                              crossAxisCount: crossAxisCount,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 2.2,
                              children: [
                                _StatCard(
                                  title: 'Kiểm kê ngoại tuyến',
                                  subtitle: 'Cơ sở dữ liệu Isar Plus',
                                  icon: Icons.offline_bolt_rounded,
                                  color: Colors.green,
                                ),
                                _StatCard(
                                  title: 'Trí tuệ nhân tạo (AI)',
                                  subtitle: 'TFLite Edge Vision Model',
                                  icon: Icons.psychology_rounded,
                                  color: Colors.purple,
                                ),
                                _StatCard(
                                  title: 'Đám mây Supabase',
                                  subtitle: 'Cloud Sync & Auth',
                                  icon: Icons.cloud_done_rounded,
                                  color: Colors.blue,
                                ),
                              ],
                            );
                          },
                        ),
                        const Gap(28),

                        Text(
                          'Tác vụ nhanh',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(16),

                        // Thẻ tác vụ nhanh
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.camera_alt_outlined,
                                        size: 32,
                                        color: Colors.blueAccent,
                                      ),
                                      const Gap(12),
                                      const Text(
                                        'Quét mã thiết bị & QR',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Gap(4),
                                      const Text(
                                        'Sử dụng camera hoặc barcode scanner để ghi nhận tài sản hiện trường.',
                                        style: TextStyle(color: Colors.grey, fontSize: 13),
                                      ),
                                      const Gap(16),
                                      ElevatedButton.icon(
                                        onPressed: () => context.push('/scanner'),
                                        icon: const Icon(Icons.qr_code_scanner),
                                        label: const Text('Mở máy quét'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Gap(16),
                            Expanded(
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.summarize_outlined,
                                        size: 32,
                                        color: Colors.orangeAccent,
                                      ),
                                      const Gap(12),
                                      const Text(
                                        'Báo cáo kiểm kê PDF',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Gap(4),
                                      const Text(
                                        'Tạo tài liệu PDF chính thức với đầy đủ chữ ký và bảng chi tiết.',
                                        style: TextStyle(color: Colors.grey, fontSize: 13),
                                      ),
                                      const Gap(16),
                                      OutlinedButton.icon(
                                        onPressed: () => _exportPdfReport(context, ref),
                                        icon: const Icon(Icons.description_outlined),
                                        label: const Text('Tạo tệp PDF'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(
            icon,
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
          selected: isSelected,
          selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
