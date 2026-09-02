import 'package:intl/intl.dart';

/// Türkçe (tr_TR) yerelinde tarih/saat biçimlendirme yardımcıları.
class DateFormatters {
  DateFormatters._();

  static final DateFormat _dayMonthYear = DateFormat('dd.MM.yyyy', 'tr_TR');
  static final DateFormat _dayMonthYearTime =
      DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');
  static final DateFormat _time = DateFormat('HH:mm', 'tr_TR');
  static final DateFormat _dayMonthLong = DateFormat('d MMMM yyyy', 'tr_TR');
  static final DateFormat _weekdayDayMonth = DateFormat('EEEE, d MMMM', 'tr_TR');
  static final DateFormat _dayMonth = DateFormat('d MMMM', 'tr_TR');

  static String formatDate(DateTime date) => _dayMonthYear.format(date);

  static String formatDateTime(DateTime date) => _dayMonthYearTime.format(date);

  static String formatTime(DateTime date) => _time.format(date);

  static String formatDateLong(DateTime date) => _dayMonthLong.format(date);

  static String formatWeekdayDate(DateTime date) => _weekdayDayMonth.format(date);

  /// "12 Eylül" gibi yıl olmadan gün+ay - ana sayfadaki "Yaklaşanlar" kartları
  /// için (yıl bilgisi bu bağlamda gereksiz kalabalık yaratır).
  static String formatDayMonth(DateTime date) => _dayMonth.format(date);

  /// İki tarihin takvim günü olarak aynı olup olmadığını kontrol eder.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  /// [date]'in bugünden itibaren [days] gün içinde (bugün dahil) olup olmadığını döner.
  static bool isWithinNextDays(DateTime date, int days, {DateTime? from}) {
    final now = from ?? DateTime.now();
    final start = startOfDay(now);
    final end = startOfDay(now).add(Duration(days: days));
    final target = startOfDay(date);
    return !target.isBefore(start) && !target.isAfter(end);
  }

  static bool isToday(DateTime date, {DateTime? from}) {
    final now = from ?? DateTime.now();
    return isSameDay(date, now);
  }
}
