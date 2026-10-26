import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:field_inventory_edge_ai/core/theme/fieldline_theme.dart';

class ScannerOverlayWidget extends StatelessWidget {
  const ScannerOverlayWidget({
    super.key,
    this.boxSize = 260.0,
    this.borderColor = FlColors.cameraHighlight,
    this.borderLength = 28.0,
    this.borderWidth = 3.0,
  });

  final double boxSize;
  final Color borderColor;
  final double borderLength;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double scanSize = [
          boxSize,
          constraints.maxHeight * 0.8,
          width * 0.85,
        ].reduce(math.min).clamp(80.0, double.infinity);

        return Stack(
          children: [
            // Darkened background with square cutout
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.35),
                BlendMode.srcOut,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Center(
                    child: Container(
                      width: scanSize,
                      height: scanSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Corner border brackets
            Center(
              child: SizedBox(
                width: scanSize,
                height: scanSize,
                child: CustomPaint(
                  painter: _ScannerBorderPainter(
                    borderColor: borderColor,
                    borderLength: borderLength,
                    borderWidth: borderWidth,
                    borderRadius: 6.0,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScannerBorderPainter extends CustomPainter {
  _ScannerBorderPainter({
    required this.borderColor,
    required this.borderLength,
    required this.borderWidth,
    required this.borderRadius,
  });

  final Color borderColor;
  final double borderLength;
  final double borderWidth;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double w = size.width;
    final double h = size.height;
    final double r = borderRadius;
    final double l = borderLength;

    // Top-Left corner
    final pathTL = Path()
      ..moveTo(0, l)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(l, 0);
    canvas.drawPath(pathTL, paint);

    // Top-Right corner
    final pathTR = Path()
      ..moveTo(w - l, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, l);
    canvas.drawPath(pathTR, paint);

    // Bottom-Left corner
    final pathBL = Path()
      ..moveTo(0, h - l)
      ..lineTo(0, h - r)
      ..arcToPoint(Offset(r, h), radius: Radius.circular(r))
      ..lineTo(l, h);
    canvas.drawPath(pathBL, paint);

    // Bottom-Right corner
    final pathBR = Path()
      ..moveTo(w - l, h)
      ..lineTo(w - r, h)
      ..arcToPoint(Offset(w, h - r), radius: Radius.circular(r))
      ..lineTo(w, h - l);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerBorderPainter oldDelegate) => false;
}
