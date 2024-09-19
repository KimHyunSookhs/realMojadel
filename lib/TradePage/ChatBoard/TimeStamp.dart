import 'package:cloud_firestore/cloud_firestore.dart';

String formatTimestamp(Timestamp timestamp) {
  DateTime date = timestamp.toDate().toLocal().add(Duration(hours: 9));
  return "${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
}
