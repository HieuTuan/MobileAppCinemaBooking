import 'package:intl/intl.dart';

final _moneyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');
final _dateFormat = DateFormat('dd/MM/yyyy');
final _timeFormat = DateFormat('HH:mm');
final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

String money(int value) => _moneyFormat.format(value);

String shortDate(DateTime value) => _dateFormat.format(value);

String shortTime(DateTime value) => _timeFormat.format(value);

String fullDateTime(DateTime value) => _dateTimeFormat.format(value);

String compactId(DateTime value) =>
    value.microsecondsSinceEpoch.toString().substring(8);
