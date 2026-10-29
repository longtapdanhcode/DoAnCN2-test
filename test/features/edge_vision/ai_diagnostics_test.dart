import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:field_inventory_edge_ai/features/edge_vision/data/repositories/tflite_vision_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/edge_vision/domain/entities/vision_analysis.dart';
import 'package:field_inventory_edge_ai/features/edge_vision/domain/repositories/vision_ai_repository.dart';
import 'package:field_inventory_edge_ai/features/edge_vision/presentation/controllers/scanner_controller.dart';
import 'package:field_inventory_edge_ai/features/edge_vision/presentation/widgets/ai_diagnostics_panel.dart';

class _FakeVision implements VisionAiRepository {
  VisionAnalysis next = const VisionAnalysis();

  /// Đặt để giữ lượt phân tích treo cho tới khi test hoàn tất nó.
  Completer<VisionAnalysis>? pending;
  bool closed = false;
  int calls = 0;
  int loadCalls = 0;

  @override
  VisionModelStatus get modelStatus => VisionModelStatus.loaded;

  @override
  String? get modelError => null;

  @override
  int get labelCount => 9;

  @override
  Future<void> loadModel() async => loadCalls++;

  @override
  Future<VisionAnalysis> analyze(List<int> imageBytes) async {
    calls++;
    final p = pending;
    return p == null ? next : p.future;
  }

  @override
  Future<List<String>> analyzeFrame(List<int> b, int w, int h) async =>
      (await analyze(b)).labels;

  @override
  void close() => closed = true;
}

const _chair = VisionAnalysis(
  labels: ['Ghế (93.4%)'],
  topLabel: 'Ghế',
  topScore: 0.934,
  topThreshold: 0.5,
  frameWidth: 1080,
  frameHeight: 1920,
);

void main() {
  group('topCandidate', () {
    test('lấy nhãn điểm cao nhất kể cả dưới ngưỡng', () {
      final output = [
        for (var i = 0; i < 4; i++) [0.0, 0.0],
        [0.10, 0.20], // nhãn 0
        [0.05, 0.34], // nhãn 1
      ];
      final top = TfliteVisionRepositoryImpl.topCandidate(output, 2)!;
      expect(top.$1, 1);
      expect(top.$2, closeTo(0.34, 1e-9));
      expect(
        TfliteVisionRepositoryImpl.decodeDetections(output, ['A', 'B']),
        isEmpty,
      );
    });
  });

  group('aiDiagnosticVerdict', () {
    test('mô hình lỗi', () {
      expect(
        aiDiagnosticVerdict(
          const AiDiagnostics(
            modelStatus: VisionModelStatus.failed,
            modelError: 'bad model',
          ),
        ),
        contains('bad model'),
      );
    });

    test('chưa nhận khung hình nào', () {
      expect(
        aiDiagnosticVerdict(
          const AiDiagnostics(modelStatus: VisionModelStatus.loaded),
        ),
        contains('Chưa nhận được khung hình'),
      );
    });

    test('ảnh nằm ngang thì cảnh báo xoay', () {
      expect(
        aiDiagnosticVerdict(
          const AiDiagnostics(
            modelStatus: VisionModelStatus.loaded,
            framesReceived: 3,
            framesAnalyzed: 3,
            last: VisionAnalysis(
              topLabel: 'Bàn',
              topScore: 0.1,
              topThreshold: 0.5,
              frameWidth: 1920,
              frameHeight: 1080,
            ),
          ),
        ),
        contains('nằm ngang'),
      );
    });

    test('dưới ngưỡng thì nói rõ điểm và ngưỡng', () {
      final verdict = aiDiagnosticVerdict(
        const AiDiagnostics(
          modelStatus: VisionModelStatus.loaded,
          framesReceived: 3,
          framesAnalyzed: 3,
          last: VisionAnalysis(
            topLabel: 'Ghế',
            topScore: 0.34,
            topThreshold: 0.5,
            frameWidth: 1080,
            frameHeight: 1920,
          ),
        ),
      );
      expect(verdict, contains('Ghế 34,0%'));
      expect(verdict, contains('ngưỡng 50,0%'));
    });

    test('đạt ngưỡng thì không có cảnh báo', () {
      expect(
        aiDiagnosticVerdict(
          const AiDiagnostics(
            modelStatus: VisionModelStatus.loaded,
            framesReceived: 1,
            framesAnalyzed: 1,
            last: _chair,
          ),
        ),
        isNull,
      );
    });
  });

  group('ScannerController đếm khung cho chẩn đoán', () {
    late _FakeVision vision;
    late ProviderContainer container;

    setUp(() {
      vision = _FakeVision();
      container = ProviderContainer(
        overrides: [visionAiRepositoryProvider.overrideWithValue(vision)],
      );
      addTearDown(container.dispose);
    });

    test('mô hình nạp xong vẫn được dùng cho các khung sau', () async {
      // Lỗi cũ: provider tự huỷ nên mô hình nạp vào một bản rồi bị đóng,
      // khung hình đi tới bản mới chưa nạp ("Chưa nạp" trên máy thật).
      final created = <_FakeVision>[];
      final c = ProviderContainer(
        overrides: [
          visionAiRepositoryProvider.overrideWith((ref) {
            final v = _FakeVision();
            created.add(v);
            return v;
          }),
        ],
      );
      addTearDown(c.dispose);
      c.listen(scannerControllerProvider, (_, _) {});
      final notifier = c.read(scannerControllerProvider.notifier);

      await c.read(visionAiRepositoryProvider).loadModel();
      for (var i = 0; i < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await notifier.processCameraFrame(
          BarcodeCapture(image: Uint8List.fromList([1])),
        );
      }

      expect(created, hasLength(1));
      expect(created.single.loadCalls, 1);
      expect(created.single.calls, 2);
    });

    test('rời màn Quét khi AI đang xử lý một khung không gây lỗi', () async {
      final v = _FakeVision()..pending = Completer<VisionAnalysis>();
      final c = ProviderContainer(
        overrides: [
          visionAiRepositoryProvider.overrideWith((ref) {
            ref.onDispose(v.close);
            return v;
          }),
        ],
      );
      final sub = c.listen(scannerControllerProvider, (_, _) {});
      final frame = c
          .read(scannerControllerProvider.notifier)
          .processCameraFrame(BarcodeCapture(image: Uint8List.fromList([1])));
      await Future<void>.delayed(Duration.zero);

      // Bấm quay lại: màn Quét đóng, bộ AI được đóng.
      sub.close();
      await Future<void>.delayed(Duration.zero);
      expect(v.closed, isTrue);

      // Lượt phân tích xong sau đó không được ghi vào controller đã huỷ.
      v.pending!.complete(_chair);
      await expectLater(frame, completes);
      c.dispose();
    });

    test('khung không có ảnh được đếm riêng, không gọi AI', () async {
      final notifier = container.read(scannerControllerProvider.notifier);
      await notifier.processCameraFrame(const BarcodeCapture());

      final ai = container.read(scannerControllerProvider).ai;
      expect(ai.framesReceived, 1);
      expect(ai.framesWithoutImage, 1);
      expect(vision.calls, 0);
    });

    test('khung có ảnh: lưu kết quả và hiện nhãn đạt ngưỡng', () async {
      vision.next = _chair;
      final notifier = container.read(scannerControllerProvider.notifier);
      await notifier.processCameraFrame(
        BarcodeCapture(image: Uint8List.fromList([1, 2, 3])),
      );

      final state = container.read(scannerControllerProvider);
      expect(state.ai.framesAnalyzed, 1);
      expect(state.ai.last!.topLabel, 'Ghế');
      expect(state.detectedObjects, ['Ghế (93.4%)']);
    });
  });
}
