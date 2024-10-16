import 'package:intl/intl.dart';

String formatDatetime(String datetime) {
  DateTime parsedDatetime = DateTime.parse(datetime).toUtc();
  return DateFormat('MM/dd HH:mm').format(parsedDatetime);
}
