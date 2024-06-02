import 'package:intl/intl.dart';

String formatDatetime(String datetime) {
  DateTime parsedDatetime = DateTime.parse(datetime).toUtc();
  DateTime adjustedDatetime = parsedDatetime.subtract(Duration(hours: 9));
  return DateFormat('MM/dd HH:mm').format(adjustedDatetime);
}
