import 'package:flutter/material.dart';

/// Tiện ích phân tách layout linh hoạt giữa Mobile và Desktop/Tablet.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget desktopBody;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    required this.desktopBody,
  });

  /// Điểm ngắt màn hình (breakpoint) giữa Mobile và Desktop
  static const double desktopBreakpoint = 800.0;

  /// Tiện ích kiểm tra xem màn hình hiện tại có thuộc kích thước Desktop hay không
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < desktopBreakpoint) {
          return mobileBody;
        } else {
          return desktopBody;
        }
      },
    );
  }
}
