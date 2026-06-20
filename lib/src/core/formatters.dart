import 'package:intl/intl.dart';

import '../services/locale_service.dart';

/// Returns a locale-aware money formatter.
///
/// Vietnamese → ₫ (VND), English → $ (USD, 1 VND ≈ 0.000039 USD, but
/// for display purposes we keep VND value and switch symbol/format).
NumberFormat _moneyFormat() {
  final langCode = LocaleService.instance.locale.languageCode;
  if (langCode == 'en') {
    return NumberFormat.currency(locale: 'en_US', symbol: '₫');
  }
  return NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');
}

DateFormat _dateFormat() {
  final langCode = LocaleService.instance.locale.languageCode;
  return langCode == 'en'
      ? DateFormat('MM/dd/yyyy')
      : DateFormat('dd/MM/yyyy');
}

DateFormat _timeFormat() => DateFormat('HH:mm');

DateFormat _dateTimeFormat() {
  final langCode = LocaleService.instance.locale.languageCode;
  return langCode == 'en'
      ? DateFormat('MM/dd/yyyy HH:mm')
      : DateFormat('dd/MM/yyyy HH:mm');
}

String money(int value) => _moneyFormat().format(value);

String shortDate(DateTime value) => _dateFormat().format(value);

String shortTime(DateTime value) => _timeFormat().format(value);

String fullDateTime(DateTime value) => _dateTimeFormat().format(value);

String compactId(DateTime value) =>
    value.microsecondsSinceEpoch.toString().substring(8);
