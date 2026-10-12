import 'package:flutter_test/flutter_test.dart';
import 'package:field_inventory_edge_ai/features/edge_vision/domain/entities/scan_result.dart';
import 'package:field_inventory_edge_ai/features/edge_vision/domain/usecases/process_scan_result_usecase.dart';

void main() {
  group('ProcessScanResultUseCase', () {
    const useCase = ProcessScanResultUseCase();

    test('executeFromRaw returns null when raw string is empty or whitespace',
        () {
      expect(useCase.executeFromRaw(''), isNull);
      expect(useCase.executeFromRaw('   \n  '), isNull);
    });

    test('executeFromRaw returns formatted ScanResult when input is valid', () {
      final result = useCase.executeFromRaw(
        '  INV-2026-ITEM-001  ',
        type: ScanCodeType.qrCode,
      );

      expect(result, isNotNull);
      expect(result!.rawValue, 'INV-2026-ITEM-001');
      expect(result.displayValue, 'INV-2026-ITEM-001');
      expect(result.type, ScanCodeType.qrCode);
      expect(result.scannedAt, isNotNull);
    });
  });
}
