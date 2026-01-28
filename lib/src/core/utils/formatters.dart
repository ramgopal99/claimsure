import 'package:intl/intl.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

final _dateFormat = DateFormat('dd MMM yyyy');

String formatCurrency(double amount) => _currencyFormat.format(amount);

String formatDate(DateTime date) => _dateFormat.format(date);
