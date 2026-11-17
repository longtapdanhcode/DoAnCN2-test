import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:field_inventory_edge_ai/features/damage_assessment/data/repair_rate_repository.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/data/sample_repair_rates.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/damage_calculator.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/damage_measurer.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/damage_enums.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/repair_rate.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/surface_assessment.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/presentation/audit_labels.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/presentation/damage_format.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/presentation/surface_assessment_draft.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/repositories/isar_audit_repository_impl.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/domain/repositories/audit_repository.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_records_provider.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/screens/audit_form_screen.dart';

class _Repo implements AuditRepository {
  final records = <AuditRecordModel>[];
  @override
  Future<void> saveRecord(AuditRecordModel r) async => records.add(r);
  @override
  Future<List<AuditRecordModel>> getAllRecords() async => records;
  @override
  Future<void> deleteRecord(int id) async {}
  @override
  Future<Uint8List> exportPdfReport() async => Uint8List(0);
}

const _table = RepairRateTable(
  sampleRepairRates,
  source: RepairRateSource.sample,
);

const _measurement = FrameMeasurement(
  measurements: [
    DamageMeasurement(
      type: DamageType.waterMold,
      quantity: 1.5,
      confidence: 0.88,
    ),
  ],
  scale: MarkerScale(cmPerPixel: 0.05, markerSidePx: 200),
  capturedAreaM2: 0.12,
);

void main() {
  group('Định dạng số', () {
    test('Phẩy thập phân, chấm hàng nghìn', () {
      expect(formatDecimal(1.5), '1,5');
      expect(formatDecimal(2), '2');
      expect(formatDecimal(0.125), '0,13');
      expect(formatVnd(1250000), '1.250.000 đ');
      expect(formatVnd(0), '0 đ');
      expect(parseDecimal('2,5'), 2.5);
      expect(parseDecimal('abc'), isNull);
    });
  });

  test(
    'Danh sách phiếu: phiếu đánh giá hiện chi phí, phiếu thường hiện số lượng',
    () {
      final plain = AuditRecordModel(1)..quantity = 3;
      expect(auditAmountLabel(plain), '3 thiết bị');
      final assessed = AuditRecordModel(2)
        ..applyAssessment(
          const DamageCalculator(_table).assess(
            material: SurfaceMaterial.paintedWall,
            surfaceAreaM2: 10,
            measurements: const [
              DamageMeasurement(type: DamageType.waterMold, quantity: 1),
            ],
          ),
        );
      expect(auditAmountLabel(assessed), '220.000 đ');
    },
  );

  group('SurfaceAssessmentDraft', () {
    test('Chưa nhập gì: không bắt lỗi, không có đánh giá', () {
      final d = SurfaceAssessmentDraft();
      expect(d.isUsed, isFalse);
      expect(d.validate(), isNull);
      expect(d.assess(const DamageCalculator(_table)), isNull);
    });

    test('Có hư hỏng mà thiếu diện tích hoặc số đo: báo lỗi', () {
      final d = SurfaceAssessmentDraft()..addRow(DamageType.rust);
      expect(d.validate(), contains('diện tích bề mặt'));
      d.setSurfaceArea('4');
      expect(d.validate(), contains('Gỉ sét'));
      d.updateRow(d.rows.single, quantity: '0,5');
      expect(d.validate(), isNull);
    });

    test('Số AI đo bị sửa thì ghi nguồn là "edited"', () {
      final d = SurfaceAssessmentDraft()..loadMeasurement(_measurement);
      expect(d.rows.single.quantityText, '1,5');
      expect(d.measurements.single.source, MeasurementSource.ai);
      d.updateRow(d.rows.single, quantity: '2');
      expect(d.measurements.single.source, MeasurementSource.edited);
      expect(d.measuredWithMarker, isTrue);
    });

    test('Không có thước đo: dòng để trống chờ nhập', () {
      final d = SurfaceAssessmentDraft()
        ..loadMeasurement(
          const FrameMeasurement(
            measurements: [
              DamageMeasurement(type: DamageType.crack, quantity: 0),
            ],
          ),
        );
      expect(d.rows.single.quantityText, '');
      expect(d.rows.single.source, MeasurementSource.manual);
    });

    test('Mở lại đánh giá đã lưu', () {
      final saved = const DamageCalculator(_table).assess(
        material: SurfaceMaterial.metal,
        surfaceAreaM2: 3.5,
        measurements: const [
          DamageMeasurement(type: DamageType.rust, quantity: 0.4),
        ],
      );
      final d = SurfaceAssessmentDraft()..loadAssessment(saved);
      expect(d.material, SurfaceMaterial.metal);
      expect(d.surfaceAreaText, '3,5');
      expect(d.assess(const DamageCalculator(_table)), saved);
    });

    test('Không ghi đè diện tích người dùng đã nhập', () {
      final d = SurfaceAssessmentDraft()..setSurfaceArea('9');
      d.suggestSurfaceArea(20);
      expect(d.surfaceAreaText, '9');
    });
  });

  group('Phiếu kiểm kê có đánh giá hư hỏng', () {
    late _Repo repo;

    setUp(() => repo = _Repo());

    Widget app({FrameMeasurement? measurement}) {
      final router = GoRouter(
        initialLocation: '/audit-form',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SizedBox()),
          GoRoute(
            path: '/audit-form',
            builder: (_, _) => Scaffold(
              body: AuditFormScreen(
                initialScanCode: 'P-A101-TT',
                initialAiLabel: 'Tường trái',
                initialMeasurement: measurement,
              ),
            ),
          ),
        ],
      );
      return ProviderScope(
        overrides: [
          isarAuditRepositoryProvider.overrideWithValue(repo),
          auditRecordsProvider.overrideWith((ref) => Stream.value(const [])),
          repairRateTableProvider.overrideWith((ref) async => _table),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    void desktop(WidgetTester tester) {
      tester.view.physicalSize = const Size(1440, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets(
      'Kết quả đo từ màn Quét hiện trên phiếu, nhập diện tích ra tiền',
      (tester) async {
        desktop(tester);
        await tester.pumpWidget(app(measurement: _measurement));
        await tester.pumpAndSettle();

        expect(find.text('Đánh giá hư hỏng bề mặt'), findsOneWidget);
        // Phiếu đánh giá bề mặt không dùng số lượng.
        expect(find.text('Số lượng thực tế'), findsNothing);
        expect(find.text('1,5'), findsOneWidget);
        expect(find.text('AI 88%'), findsOneWidget);
        expect(find.textContaining('Vùng chụp ≈ 0,12 m²'), findsOneWidget);
        expect(find.byKey(const Key('assessment-error')), findsOneWidget);

        await tester.enterText(find.byKey(const Key('surface-area')), '10');
        await tester.pumpAndSettle();

        // 1,5 / 10 = 15% => Vừa: 1,5 m² × 220.000 đ.
        expect(find.byKey(const Key('assessment-error')), findsNothing);
        expect(find.text('Vừa · 15'), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(const Key('assessment-total'))).data,
          '330.000 đ',
        );
        expect(find.textContaining('bảng giá minh hoạ'), findsOneWidget);
      },
    );

    testWidgets('Lưu bản nháp ghi đánh giá và tình trạng theo mức hư hỏng', (
      tester,
    ) async {
      desktop(tester);
      await tester.pumpWidget(app(measurement: _measurement));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('surface-area')), '5');
      await tester.pumpAndSettle();

      final save = find.text('Lưu bản nháp');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      final r = repo.records.single;
      // 1,5 / 5 = 30% => Nặng: 1,5 × 380.000.
      expect(r.estimatedCost, 570000);
      expect(r.damageIndex, closeTo(30, 1e-9));
      expect(r.condition, 'damaged');
      final a = r.surfaceAssessment!;
      expect(a.surfaceAreaM2, 5);
      expect(a.measurements.single.source, MeasurementSource.ai);
    });

    testWidgets('Thiếu diện tích thì không lưu, báo cần nhập', (tester) async {
      desktop(tester);
      await tester.pumpWidget(app(measurement: _measurement));
      await tester.pumpAndSettle();

      final save = find.text('Lưu bản nháp');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(repo.records, isEmpty);
      expect(find.textContaining('Nhập diện tích bề mặt'), findsWidgets);
    });

    testWidgets('Phiếu không đánh giá vẫn lưu như trước', (tester) async {
      desktop(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Số lượng thực tế'), findsOneWidget);

      final save = find.text('Lưu bản nháp');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      final r = repo.records.single;
      expect(r.damageAssessmentJson, isNull);
      expect(r.estimatedCost, isNull);
    });
  });
}
