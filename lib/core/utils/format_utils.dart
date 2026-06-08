import 'package:intl/intl.dart';

class FormatUtils {
  static final vnCurrency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'VND',
    decimalDigits: 0,
  );
}
