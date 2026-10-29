import 'package:flutter/material.dart';

import 'package:field_inventory_edge_ai/core/utils/responsive_layout.dart';
import 'package:field_inventory_edge_ai/core/widgets/fieldline_widgets.dart';

/// Khung trang dùng chung cho Địa điểm và Cài đặt: tiêu đề lớn trên
/// desktop, tiêu đề có nút quay lại trên mobile.
class WorkspacePage extends StatelessWidget {
  const WorkspacePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) {
      return DesktopPage(
        heading: DesktopPageHeading(title: title, subtitle: subtitle),
        children: children,
      );
    }
    return MobilePage(
      title: title,
      subtitle: subtitle,
      showBack: true,
      children: children,
    );
  }
}
