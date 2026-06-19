import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final _currency = NumberFormat('#,##0', 'fr_FR');
  static final _dateTime = DateFormat('dd MMM yyyy - HH:mm', 'fr_FR');
  static final _date = DateFormat('dd MMM yyyy', 'fr_FR');
  static final _time = DateFormat('HH:mm', 'fr_FR');

  static String currency(int amount, {String suffix = ' FCFA'}) {
    return '${_currency.format(amount)}$suffix';
  }

  static String dateTime(DateTime? date) {
    if (date == null) return '—';
    return _dateTime.format(date);
  }

  static String date(DateTime? date) {
    if (date == null) return '—';
    return _date.format(date);
  }

  static String time(DateTime? date) {
    if (date == null) return '—';
    return _time.format(date);
  }

  static String etaMinutes(int minutes) {
    if (minutes <= 0) return 'Arrivée imminente';
    if (minutes == 1) return '1 min';
    return '$minutes min';
  }

  static String distanceKm(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }
}
