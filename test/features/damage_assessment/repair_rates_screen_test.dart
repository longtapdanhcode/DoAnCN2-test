import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/features/auth/domain/app_user.dart';
import 'package:field_inventory_edge_ai/features/auth/presentation/auth_providers.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/data/repair_rate_repository.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/data/sample_repair_rates.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/damage_calculator.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/damage_enums.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/repair_rate.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/surface_assessment.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/repair_cost_summary.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/presentation/repair_cost_card.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/presentation/repair_rates_screen.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/data/models/audit_record_model.dart';

class _Writer implements RepairRateWriter {
  final upserts = <RepairRate>[];
  final deletes = <RepairRate>[];

  @override
  Future<void> upsert(RepairRate rate) async => upserts.add(rate);

  @override
  Future<void> delete(RepairRate rate) async => deletes.add(rate);
}

const _remote = RepairRateTable([
  RepairRate(
    damageType: DamageType.rust,
    severity: DamageSeverity.light,
    unitPrice: 90000,
    method: 'Đánh gỉ',
  ),
], source: RepairRateSource.remote);

AppUser _user(UserRole role) =>
    AppUser(id: 'u1', email: 'a@truong.test', role: role);

Widget _app({
  required RepairRateTable table,
  required UserRole role,
  required _Writer writer,
}) => ProviderScope(
  overrides: [
    repairRateTableProvider.overrideWith((ref) async => table),
    signedInUserProvider.overrideWithValue(_user(role)),
    repairRateWriterProvider.overrideWithValue(writer),
  ],
  child: const MaterialApp(home: Scaffold(body: RepairRatesScreen())),
);

void desktop(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('Kiểm kê viên chỉ xem, không có nút sửa', (tester) async {
    desktop(tester);
    final writer = _Writer();
    await tester.pumpWidget(
      _app(table: _remote, role: UserRole.auditor, writer: writer),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chỉ quản trị viên được sửa đơn giá.'), findsOneWidget);
    expect(find.text('90.000 đ/m²'), findsOneWidget);
    expect(find.byKey(const Key('add-rate')), findsNothing);
    // Loại chưa có giá được báo rõ.
    expect(find.textContaining('Chưa có đơn giá'), findsNWidgets(3));

    await tester.tap(find.text('90.000 đ/m²'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Admin sửa giá: ghi lên máy chủ và bỏ cờ minh hoạ', (
    tester,
  ) async {
    desktop(tester);
    final writer = _Writer();
    await tester.pumpWidget(
      _app(table: _remote, role: UserRole.admin, writer: writer),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('90.000 đ/m²'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('rate-price')), '120000');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    final saved = writer.upserts.single;
    expect(saved.unitPrice, 120000);
    expect(saved.damageType, DamageType.rust);
    expect(saved.isSample, isFalse);
    expect(writer.deletes, isEmpty);
    expect(find.text('Đã lưu đơn giá.'), findsOneWidget);
  });

  testWidgets('Admin xoá đơn giá', (tester) async {
    desktop(tester);
    final writer = _Writer();
    await tester.pumpWidget(
      _app(table: _remote, role: UserRole.admin, writer: writer),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('90.000 đ/m²'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá'));
    await tester.pumpAndSettle();
    expect(writer.deletes.single.damageType, DamageType.rust);
  });

  testWidgets('Đang dùng giá minh hoạ: báo rõ, admin chưa sửa được', (
    tester,
  ) async {
    desktop(tester);
    await tester.pumpWidget(
      _app(
        table: const RepairRateTable(
          sampleRepairRates,
          source: RepairRateSource.sample,
        ),
        role: UserRole.admin,
        writer: _Writer(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('đang dùng giá minh hoạ'), findsOneWidget);
    expect(find.text('Cần kết nối máy chủ để sửa đơn giá.'), findsOneWidget);
    expect(find.byKey(const Key('add-rate')), findsNothing);
    expect(find.text('Minh hoạ'), findsNWidgets(12));
  });

  testWidgets('Thẻ chi phí: tổng tiền, điểm và phòng ưu tiên', (tester) async {
    const calc = DamageCalculator(
      RepairRateTable(sampleRepairRates, source: RepairRateSource.sample),
    );
    AuditRecordModel r(int id, String room, double water) =>
        AuditRecordModel(id, signatureBytes: Uint8List(1))
          ..scanCode = 'S$id'
          ..area = 'Nhà A'
          ..location = room
          ..timestamp = DateTime(2026, 11, id)
          ..applyAssessment(
            calc.assess(
              material: SurfaceMaterial.paintedWall,
              surfaceAreaM2: 10,
              measurements: [
                DamageMeasurement(type: DamageType.waterMold, quantity: water),
              ],
            ),
          );
    final summary = RepairCostSummary.fromRecords([
      r(1, 'A101', 1),
      r(2, 'A102', 3),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: RepairCostCard(summary: summary)),
        ),
      ),
    );
    // 1 × 220.000 + 3 × 380.000
    expect(
      tester.widget<Text>(find.byKey(const Key('repair-total'))).data,
      '1.360.000 đ',
    );
    expect(find.text('80/100'), findsOneWidget);
    expect(find.text('Nặng: 1'), findsOneWidget);
    // A102 (Nặng) đứng trước A101.
    final a102 = tester.getTopLeft(find.text('A102')).dy;
    final a101 = tester.getTopLeft(find.text('A101')).dy;
    expect(a102, lessThan(a101));
    expect(find.textContaining('bảng giá minh hoạ'), findsOneWidget);
  });

  testWidgets('Thẻ chi phí khi chưa có phiếu đánh giá', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepairCostCard(
            summary: RepairCostSummary.fromRecords(const []),
          ),
        ),
      ),
    );
    expect(find.textContaining('Chưa có phiếu nào'), findsOneWidget);
  });
}
