import 'package:flutter/material.dart';

class DayWidget extends StatelessWidget {
  final Map<String, dynamic> day;
  final List<Map<String, dynamic>>? transaction;
  final VoidCallback onTap;
  final Function(int, int) onUpdate;
  final int totalIncome;
  final int totalExpense;

  DayWidget({
    required this.day,
    required this.onTap,
    required this.onUpdate,
    required this.totalIncome,
    required this.totalExpense,
    this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    DateTime currentDay = DateTime(day['year'], day['month'], day['day']);

    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
        margin: EdgeInsets.all(1.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day['day']}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            Text(
              '$totalIncome',
              style: TextStyle(color: Colors.indigoAccent, fontSize: 8,fontWeight:FontWeight.w600),
            ),
            Text(
              '$totalExpense',
              style: TextStyle(color: Colors.red, fontSize: 8,fontWeight:FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
