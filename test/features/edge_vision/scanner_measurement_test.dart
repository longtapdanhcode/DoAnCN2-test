import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/damage_enums.dart';
import 'package:field_inventory_edge_ai/features/edge_vision/data/repositories/tflite_vision_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/edge_vision/domain/entities/detection.dart';
import 'package:field_inventory_edge_ai/features/edge_vision/domain/entities/vision_analysis.dart';
import 'package:field_inventory_edge_ai/features/edge_vision/domain/repositories/scanner_repository.dart';
import 'package:field_inventory_edge_ai/features/edge_vision/domain/repositories/vision_ai_repository.dart';
import 'package:field_inventory_edge_ai/features/edge_vision/presentation/controllers/scanner_controller.dart';

class _Vision implements VisionAiRepository {
  VisionAnalysis next = const VisionAnalysis();
  Completer<VisionAnalysis>? pending;
  int calls = 0;

  @override
  VisionModelStatus get modelStatus => VisionModelStatus.loaded;
  @override
  String? get modelError => null;
  @override
  int get labelCount => 9;
  @override
  Future<void> loadModel() async {}

  @override
  Future<VisionAnalysis> analyze(
    List<int> imageBytes, {
    Uint8List? squareRgb,
    int frameWidth = 0,
    int frameHeight = 0,
  }) async {
    calls++;
    final p = pending;
    if (p != null) {
      pending = null;
      return p.future;
    }
    return next;
  }

  @override
  Future<List<String>> analyzeFrame(List<int> b, int w, int h) async =>
      const [];
  @override
  void close() {}
}

class _Camera implements ScannerRepository {
  @override
  MobileScannerController get controller => throw UnimplementedError();
  @override
  Future<bool> checkPermission() async => true;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> toggleTorch() async {}
  @override
  Future<void> switchCamera() async {}
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
  @override
  void dispose() {}
}

/// Thẻ QR 200 px trên ảnh 1000×1500: 10 cm / 200 px = 0,05 cm/px.
const _qr = Barcode(
  rawValue: 'P-A101-TT',
  format: BarcodeFormat.qrCode,
  corners: [
    Offset(100, 100),
    Offset(300, 100),
    Offset(300, 300),
    Offset(100, 300),
  ],
);

const _water = Detection(
  classIndex: 2, // Thấm nước (model 9 lớp)
  label: 'Thấm nước',
  score: 0.88,
  cx: 0.5,
  cy: 0.5,
  w: 0.5,
  h: 0.4,
);

const _chair = Detection(
  classIndex: 6,
  label: 'Ghế',
  score: 0.9,
  cx: 0.2,
  cy: 0.2,
  w: 0.1,
  h: 0.1,
);

BarcodeCapture capture({List<Barcode> barcodes = const [_qr]}) =>
    BarcodeCapture(
      barcodes: barcodes,
      image: Uint8List.fromList([1, 2, 3]),
      size: const Size(1000, 1500),
    );

Future<void> settle(ProviderContainer c) async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
    if (!c.read(scannerControllerProvider).isMeasuring) return;
  }
}

void main() {
  late _Vision vision;
  late ProviderContainer c;

  setUp(() async {
    vision = _Vision();
    c = ProviderContainer(
      overrides: [
        visionAiRepositoryProvider.overrideWithValue(vision),
        scannerRepositoryProvider.overrideWithValue(_Camera()),
      ],
    );
    addTearDown(c.dispose);
    c.listen(scannerControllerProvider, (_, _) {});
    await c.read(scannerControllerProvider.notifier).startCamera();
    expect(c.read(scannerControllerProvider).status, ScannerStatus.scanning);
  });

  test('Quét được mã: đo hư hỏng theo thẻ QR, bỏ đồ vật', () async {
    vision.next = const VisionAnalysis(detections: [_water, _chair]);
    c.read(scannerControllerProvider.notifier).onBarcodeScanned(capture());
    await settle(c);

    final s = c.read(scannerControllerProvider);
    expect(s.status, ScannerStatus.success);
    final m = s.measurement!;
    expect(m.hasScale, isTrue);
    expect(m.ignoredDetections, 1);
    final d = m.measurements.single;
    expect(d.type, DamageType.waterMold);
    // Ô AI = 0,7 × 1000 px × 0,05 cm/px = 35 cm.
    // 0,5 × 0,4 × π/4 × 0,35² ≈ 0,0192 m² => 0,02
    expect(d.quantity, 0.02);
    expect(m.capturedAreaM2, closeTo(0.12, 1e-9));
  });

  test(
    'AI còn bận khung trước: chờ xong rồi đo lại chính khung có mã',
    () async {
      final notifier = c.read(scannerControllerProvider.notifier);
      final busy = Completer<VisionAnalysis>();
      vision.pending = busy;
      unawaited(notifier.processCameraFrame(capture(barcodes: const [])));
      await Future<void>.delayed(Duration.zero);

      vision.next = const VisionAnalysis(detections: [_water]);
      notifier.onBarcodeScanned(capture());
      expect(c.read(scannerControllerProvider).isMeasuring, isTrue);

      busy.complete(const VisionAnalysis());
      await settle(c);
      final s = c.read(scannerControllerProvider);
      expect(s.measurement!.measurements.single.type, DamageType.waterMold);
      expect(vision.calls, 2);
    },
  );

  test(
    'Mã không có góc đủ rõ: vẫn liệt kê hư hỏng, chưa có thước đo',
    () async {
      vision.next = const VisionAnalysis(detections: [_water]);
      c
          .read(scannerControllerProvider.notifier)
          .onBarcodeScanned(
            capture(
              barcodes: const [
                Barcode(rawValue: 'X', format: BarcodeFormat.qrCode),
              ],
            ),
          );
      await settle(c);
      final m = c.read(scannerControllerProvider).measurement!;
      expect(m.hasScale, isFalse);
      expect(m.measurements.single.quantity, 0);
    },
  );

  test('Quét tiếp xoá kết quả đo cũ', () async {
    vision.next = const VisionAnalysis(detections: [_water]);
    final notifier = c.read(scannerControllerProvider.notifier);
    notifier.onBarcodeScanned(capture());
    await settle(c);
    expect(c.read(scannerControllerProvider).measurement, isNotNull);

    await notifier.resumeScanning();
    expect(c.read(scannerControllerProvider).measurement, isNull);
  });
}
