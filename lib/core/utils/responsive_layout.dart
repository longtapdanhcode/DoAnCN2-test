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

  /// Điểm ngắt màn hình (breakpoint) giữa Mobile và Desktop.
  ///
  /// Dưới 1024px (điện thoại, tablet dọc) dùng bố cục mobile với thanh điều
  /// hướng dưới; từ 1024px trở lên dùng sidebar + bố cục web của Figma.
  static const double desktopBreakpoint = 1024.0;

  /// Tiện ích kiểm tra xem màn hình hiện tại có thuộc kích thước Desktop hay không
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  @override
  Widget build(BuildContext context) {
    // Dựa trên kích thước màn hình (không phải ràng buộc của widget cha) để
    // khớp với khung FieldlineShell: sidebar chiếm chỗ nhưng nội dung vẫn
    // phải dùng bố cục desktop.
    return isDesktop(context) ? desktopBody : mobileBody;
  }
}
