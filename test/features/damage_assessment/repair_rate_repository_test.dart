import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_inventory_edge_ai/features/damage_assessment/data/repair_rate_repository.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/data/sample_repair_rates.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/damage_enums.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/repair_rate.dart';
import 'package:field_inventory_edge_ai/features/damage_assessment/domain/entities/surface_assessment.dart';

class FakeRemote implements RepairRateRemoteSource {
  FakeRemote({this.rows = const [], this.error});

  List<Map<String, dynamic>> rows;
  Object? error;
  int calls = 0;

  @override
  Future<List<Map<String, dynamic>>> fetchRows() async {
    calls++;
    if (error != null) throw error!;
    return rows;
  }
}

class MemoryCache implements RepairRateCacheStore {
  Map<String, dynamic>? data;
  int writes = 0;

  @override
  Future<Map<String, dynamic>?> read() async => data;

  @override
  Future<void> write(Map<String, dynamic> json) async {
    writes++;
    data = json;
  }
}

Map<String, dynamic> row(String type, String severity, num price) => {
  'id': 'x',
  'material': null,
  'damage_type': type,
  'severity': severity,
  'unit': type == 'vet_nut' ? 'm' : 'm2',
  'unit_price': price,
  'method': 'Cách xử lý',
  'is_sample': false,
};

void main() {
  final fixedNow = DateTime.utc(2026, 11, 12, 8);

  test('Tải được từ máy chủ: dùng bảng máy chủ và lưu lại trên máy', () async {
    final remote = FakeRemote(rows: [row('gi_set', 'light', 99000)]);
    final cache = MemoryCache();
    final table = await RepairRateRepository(
      remote,
      cache,
      now: () => fixedNow,
    ).load();

    expect(table.source, RepairRateSource.remote);
    expect(table.fetchedAt, fixedNow);
    expect(table.rates.single.unitPrice, 99000);
    expect(table.hasSampleRates, isFalse);
    expect(cache.writes, 1);
  });

  test('Mất mạng: dùng bản đã lưu từ lần tải trước', () async {
    final cache = MemoryCache();
    await RepairRateRepository(
      FakeRemote(rows: [row('vet_nut', 'severe', 500000)]),
      cache,
      now: () => fixedNow,
    ).load();

    final offline = await RepairRateRepository(
      FakeRemote(error: const SocketException('offline')),
      cache,
    ).load();

    expect(offline.source, RepairRateSource.cache);
    expect(offline.fetchedAt, fixedNow.toLocal());
    expect(
      offline
          .lookup(
            SurfaceMaterial.concrete,
            DamageType.crack,
            DamageSeverity.severe,
          )!
          .unitPrice,
      500000,
    );
  });

  test('Chưa từng tải được: dùng bảng giá mẫu', () async {
    final table = await RepairRateRepository(
      FakeRemote(error: Exception('chưa cấu hình Supabase')),
      MemoryCache(),
    ).load();
    expect(table.source, RepairRateSource.sample);
    expect(table.rates, sampleRepairRates);
    expect(table.hasSampleRates, isTrue);
  });

  test('Máy chủ chưa có giá: không ghi đè bản đã lưu', () async {
    final cache = MemoryCache();
    final remote = FakeRemote(rows: [row('tham_moc', 'moderate', 1)]);
    final repo = RepairRateRepository(remote, cache, now: () => fixedNow);
    await repo.load();

    remote.rows = [];
    final table = await repo.load();
    expect(table.source, RepairRateSource.cache);
    expect(table.rates.single.unitPrice, 1);
    expect(cache.writes, 1);
  });

  test('Bỏ dòng sai mã từ máy chủ', () async {
    final table = await RepairRateRepository(
      FakeRemote(
        rows: [
          row('gi_set', 'light', 1),
          row('khong_ro', 'light', 1),
          {...row('gi_set', 'severe', 1), 'unit_price': null},
        ],
      ),
      MemoryCache(),
    ).load();
    expect(table.rates, hasLength(1));
  });

  test('Bản lưu trên máy hỏng: bỏ qua và dùng giá mẫu', () async {
    final cache = MemoryCache()..data = {'rates': 'không phải danh sách'};
    final table = await RepairRateRepository(
      FakeRemote(error: Exception('offline')),
      cache,
    ).load();
    expect(table.source, RepairRateSource.sample);
  });

  test('Máy chủ treo: hết thời gian chờ thì dùng bản dự phòng', () async {
    final table = await RepairRateRepository(
      _HangingRemote(),
      MemoryCache(),
      timeout: const Duration(milliseconds: 10),
    ).load();
    expect(table.source, RepairRateSource.sample);
  });

  test('Provider dựng DamageCalculator từ bảng đơn giá', () async {
    final container = ProviderContainer(
      overrides: [
        repairRateRemoteSourceProvider.overrideWithValue(
          FakeRemote(rows: [row('bong_son', 'light', 10)]),
        ),
        repairRateCacheStoreProvider.overrideWithValue(MemoryCache()),
      ],
    );
    addTearDown(container.dispose);

    final calc = await container.read(damageCalculatorProvider.future);
    final r = calc.assess(
      material: SurfaceMaterial.paintedWall,
      surfaceAreaM2: 100,
      measurements: const [
        DamageMeasurement(type: DamageType.peelingPaint, quantity: 2),
      ],
    );
    expect(r.totalCost, 20);
  });

  test('Bảng giá mẫu trong app trùng với file seed SQL', () {
    final sql = File('supabase/seed/repair_cost_rates_sample.sql')
        .readAsStringSync();
    final pattern = RegExp(
      r"\(null, '(\w+)', '(\w+)', '(m2?)', (\d+), '([^']*)', true\)",
    );
    final fromSql = [
      for (final m in pattern.allMatches(sql))
        RepairRate(
          damageType: DamageType.fromCode(m[1])!,
          severity: DamageSeverity.fromCode(m[2])!,
          unitPrice: double.parse(m[4]!),
          method: m[5]!,
          isSample: true,
        ),
    ];
    expect(fromSql, sampleRepairRates);
    // Cột unit trong SQL khớp đơn vị của loại hư hỏng.
    for (final m in pattern.allMatches(sql)) {
      expect(m[3], DamageType.fromCode(m[1])!.unit.code);
    }
  });
}

class _HangingRemote implements RepairRateRemoteSource {
  @override
  Future<List<Map<String, dynamic>>> fetchRows() =>
      Completer<List<Map<String, dynamic>>>().future;
}
