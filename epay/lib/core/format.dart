import 'package:intl/intl.dart';

final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
final _inrCompact = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

String money(num? v, {bool decimals = true}) {
  final n = v ?? 0;
  return decimals ? _inr.format(n) : _inrCompact.format(n);
}

/// Drops trailing zeros: 240.80 -> ₹240.8, 100.00 -> ₹100
String moneyTrim(num? v) {
  final n = (v ?? 0).toDouble();
  if (n == n.roundToDouble()) return _inrCompact.format(n);
  var s = n.toStringAsFixed(2);
  if (s.endsWith('0')) s = s.substring(0, s.length - 1);
  return '₹$s';
}

String compact(num? v) {
  final n = (v ?? 0).toDouble();
  if (n >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)}Cr';
  if (n >= 100000) return '₹${(n / 100000).toStringAsFixed(2)}L';
  if (n >= 1000) return '₹${(n / 1000).toStringAsFixed(1)}K';
  return moneyTrim(n);
}

String dateTimeLabel(DateTime? d) =>
    d == null ? '-' : DateFormat('yyyy-MM-dd HH:mm:ss').format(d.toLocal());

String dateLabel(DateTime? d) =>
    d == null ? '-' : DateFormat('yyyy-MM-dd').format(d.toLocal());

String maskPhone(String? p) {
  if (p == null || p.length < 6) return p ?? '';
  return '${p.substring(0, 2)}****${p.substring(p.length - 2)}';
}
