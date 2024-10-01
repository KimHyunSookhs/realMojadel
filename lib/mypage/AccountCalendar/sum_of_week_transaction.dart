import 'package:flutter/material.dart';

// 주마다 수입 및 지출 합계 위젯
class SumOfWeekTransaction extends StatelessWidget {
  final Map<String, int> weeklySum;

  SumOfWeekTransaction({required this.weeklySum});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '₩${weeklySum['weekIncome']}    ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.indigoAccent,
            ),
          ),
          Text(
            '₩${weeklySum['weekExpense']}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
        ],
      ),
    );
  }
}