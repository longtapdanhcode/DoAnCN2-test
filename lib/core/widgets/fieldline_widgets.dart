import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../theme/fieldline_theme.dart';

/// Tông màu trạng thái dùng cho pill, chỉ số và biểu tượng.
enum FlTone {
  success(FlColors.primary, FlColors.primarySoft),
  warning(FlColors.warning, FlColors.warningSoft),
  info(FlColors.info, FlColors.infoSoft),
  danger(FlColors.danger, FlColors.dangerSoft),
  neutral(FlColors.muted, FlColors.neutralSoft);

  const FlTone(this.foreground, this.background);

  final Color foreground;
  final Color background;
}

/// Thẻ trắng viền mảnh, bo 12px — khối nền tảng của mọi màn hình.
class FlCard extends StatelessWidget {
  const FlCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = FlColors.surface,
    this.borderColor = FlColors.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(FlRadius.card);
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Nhãn trạng thái dạng viên thuốc.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = FlTone.success,
    this.dot = false,
    this.bold = false,
  });

  final String label;
  final FlTone tone;
  final bool dot;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: tone.foreground,
                shape: BoxShape.circle,
              ),
            ),
            const Gap(6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tone.foreground,
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô vuông bo góc chứa biểu tượng.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.tone = FlTone.success,
    this.size = 34,
    this.iconSize = 18,
    this.circle = false,
  });

  final IconData icon;
  final FlTone tone;
  final double size;
  final double iconSize;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.background,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size / 4),
      ),
      child: Icon(icon, size: iconSize, color: tone.foreground),
    );
  }
}

/// Thanh tiến độ bo tròn.
class FlProgressBar extends StatelessWidget {
  const FlProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color = FlColors.primary,
    this.trackColor = FlColors.track,
  });

  final double value;
  final double height;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        color: color,
        backgroundColor: trackColor,
      ),
    );
  }
}

/// Tiêu đề trong một thẻ: tiêu đề đậm, mô tả nhỏ và phần tử phụ bên phải.
class CardHeader extends StatelessWidget {
  const CardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: FlColors.ink,
                ),
              ),
              if (subtitle != null) ...[
                const Gap(6),
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 12, color: FlColors.muted),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const Gap(12), trailing!],
      ],
    );
  }
}

/// Nhãn nhỏ viết hoa dùng cho tiêu đề cột bảng và nhóm nội dung.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color = FlColors.muted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.3,
      ),
    );
  }
}

/// Dải thông báo nền màu nhạt với biểu tượng.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.check_rounded,
    this.tone = FlTone.success,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final FlTone tone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(FlRadius.control),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: tone.foreground),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: subtitle == null
                        ? FontWeight.w500
                        : FontWeight.w700,
                    color: tone.foreground,
                  ),
                ),
                if (subtitle != null) ...[
                  const Gap(4),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 11, color: tone.foreground),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Một dòng nhãn - giá trị có đường kẻ dưới (bảng tóm tắt).
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.divider = true,
  });

  final String label;
  final Widget value;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: divider
            ? const Border(bottom: BorderSide(color: FlColors.border))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: FlColors.muted),
            ),
          ),
          Expanded(flex: 3, child: value),
        ],
      ),
    );
  }
}

/// Tiêu đề trang trên desktop/web: breadcrumb ngày, tiêu đề lớn, mô tả và nút chính.
class DesktopPageHeading extends StatelessWidget {
  const DesktopPageHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FIELD OPERATIONS / $date',
                style: const TextStyle(fontSize: 10, color: FlColors.muted),
              ),
              const Gap(8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: FlColors.ink,
                  height: 1.15,
                ),
              ),
              const Gap(8),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: FlColors.muted),
              ),
            ],
          ),
        ),
        if (action != null) ...[
          const Gap(24),
          Padding(padding: const EdgeInsets.only(top: 16), child: action!),
        ],
      ],
    );
  }
}

/// Khung cuộn chuẩn của một trang desktop: tiêu đề, nội dung, chân trang.
class DesktopPage extends StatelessWidget {
  const DesktopPage({super.key, required this.heading, required this.children});

  final DesktopPageHeading heading;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading,
          const Gap(28),
          ...children,
          const Gap(28),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Fieldline • Field Inventory & Edge AI Suite',
                  style: TextStyle(fontSize: 11, color: FlColors.muted),
                ),
              ),
              Text(
                'Phiên bản 1.0',
                style: TextStyle(fontSize: 11, color: FlColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Khung trang mobile: tiêu đề (có nút quay lại tuỳ chọn), nội dung cuộn
/// và nút hành động chính ghim phía trên thanh điều hướng.
class MobilePage extends StatelessWidget {
  const MobilePage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.showBack = false,
    this.trailing,
    this.bottomAction,
    this.belowTitle,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final Widget? trailing;
  final Widget? bottomAction;

  /// Nội dung nằm ngay dưới tiêu đề (ví dụ thanh bước).
  final Widget? belowTitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(showBack ? 12 : 24, 16, 24, 0),
            child: Row(
              children: [
                if (showBack)
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    color: FlColors.ink,
                    tooltip: 'Quay lại',
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: showBack ? 20 : 24,
                      fontWeight: FontWeight.w700,
                      color: FlColors.ink,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
              child: Text(
                subtitle!,
                style: const TextStyle(fontSize: 14, color: FlColors.muted),
              ),
            ),
          if (belowTitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: belowTitle!,
            ),
          Expanded(
            // Chạm ra ngoài hoặc cuộn để đóng bàn phím.
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: children,
              ),
            ),
          ),
          if (bottomAction != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: bottomAction!,
            ),
        ],
      ),
    );
  }
}

/// Thanh bước cho luồng lập phiếu trên mobile ("BƯỚC 2 / 3 · ...").
class MobileStepBar extends StatelessWidget {
  const MobileStepBar({
    super.key,
    required this.step,
    required this.total,
    required this.label,
  });

  final int step;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel('Bước $step / $total  ·  $label', color: FlColors.primary),
        const Gap(10),
        FlProgressBar(value: step / total, height: 5),
      ],
    );
  }
}

/// Nút chính kích thước lớn của mobile (cao 52px).
class MobilePrimaryButton extends StatelessWidget {
  const MobilePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FlRadius.card),
        ),
        textStyle: Theme.of(context).textTheme.labelLarge!
            .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}

/// Hai cột 7:3 khi đủ rộng, xếp chồng khi hẹp.
class FlSplitRow extends StatelessWidget {
  const FlSplitRow({
    super.key,
    required this.main,
    required this.side,
    this.flex = 7,
    this.equalHeight = true,
  });

  final Widget main;
  final Widget side;
  final int flex;

  /// Kéo hai cột cao bằng nhau. Tắt khi một cột chứa LayoutBuilder
  /// hoặc platform view (camera, canvas) vì chúng không đo được intrinsic.
  final bool equalHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [main, const Gap(16), side],
          );
        }
        final row = Row(
          crossAxisAlignment: equalHeight
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          children: [
            Expanded(flex: flex, child: main),
            const Gap(16),
            Expanded(flex: 10 - flex, child: side),
          ],
        );
        return equalHeight ? IntrinsicHeight(child: row) : row;
      },
    );
  }
}

/// Lưới đơn giản với các ô cao bằng nhau trên mỗi hàng.
class FlGrid extends StatelessWidget {
  const FlGrid({
    super.key,
    required this.columns,
    required this.spacing,
    required this.children,
  });

  final int columns;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.skip(i).take(columns).toList();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) Gap(spacing),
                Expanded(child: j < slice.length ? slice[j] : const SizedBox()),
              ],
            ],
          ),
        ),
      );
      if (i + columns < children.length) rows.add(Gap(spacing));
    }
    return Column(children: rows);
  }
}

/// Ô nhập có nhãn phía trên, theo kiểu form của Fieldline.
class FlTextField extends StatelessWidget {
  const FlTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.enabled = true,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.autofillHints,
    this.suffix,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final Widget? suffix;

  /// Gọi khi bấm phím xong trên bàn phím; có giá trị thì ô là ô cuối.
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: FlColors.muted),
        ),
        const Gap(8),
        TextFormField(
          controller: controller,
          validator: validator,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          autocorrect: !obscureText,
          enableSuggestions: !obscureText,
          autofillHints: autofillHints,
          onFieldSubmitted: onSubmitted,
          textInputAction: onSubmitted != null
              ? TextInputAction.done
              : TextInputAction.next,
          style: TextStyle(
            fontSize: 14,
            color: enabled ? FlColors.ink : FlColors.muted,
          ),
          decoration: InputDecoration(
            hintText: hint,
            fillColor: enabled ? FlColors.surface : FlColors.surfaceAlt,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

/// Hiển thị thông báo ngắn theo phong cách Fieldline.
void showFlSnack(
  BuildContext context,
  String message, {
  FlTone tone = FlTone.neutral,
}) {
  final background = switch (tone) {
    FlTone.success => FlColors.primary,
    FlTone.danger => FlColors.danger,
    FlTone.warning => FlColors.warning,
    _ => FlColors.ink,
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), backgroundColor: background),
    );
}

/// Số có dấu chấm phân tách hàng nghìn theo kiểu Việt Nam (1.248).
String flNumber(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Định dạng `dd/MM/yyyy` và `HH:mm` không cần locale.
String flDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String flTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
