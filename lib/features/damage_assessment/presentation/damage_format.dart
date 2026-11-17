import '../domain/entities/damage_enums.dart';

/// Số kiểu Việt Nam: phẩy thập phân, tối đa [decimals] chữ số, bỏ số 0 thừa.
String formatDecimal(double value, {int decimals = 2}) {
  var text = value.toStringAsFixed(decimals);
  if (text.contains('.')) {
    text = text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
  return text.replaceAll('.', ',');
}

/// Khối lượng kèm đơn vị, ví dụ "0,32 m²" hoặc "1,2 m".
String formatQuantity(double value, MeasureUnit unit) =>
    '${formatDecimal(value)} ${unit.symbol}';

/// Tiền VND, ví dụ "1.250.000 đ".
String formatVnd(double value) {
  final digits = value.round().abs().toString();
  final buf = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return '$buf đ';
}

/// Đọc số người dùng nhập, chấp nhận cả phẩy và chấm thập phân.
double? parseDecimal(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));
