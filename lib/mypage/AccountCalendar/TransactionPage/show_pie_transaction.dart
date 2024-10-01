import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ShowPieTransaction extends StatelessWidget {
  final Map<DateTime, List<Map<String, dynamic>>> allTransactions;
  final DateTime selectedDate;

  ShowPieTransaction({
    required this.selectedDate,
    required this.allTransactions,
  });

  Map<String, double> calculateCategorySums(int type) {
    Map<String, double> categorySums = {};
    allTransactions.forEach((transactionDate, transactions) {
      if (transactionDate.year == selectedDate.year &&
          transactionDate.month == selectedDate.month) {
        for (var transaction in transactions) {
          int transactionType = transaction['type']; // Ensure this is an int
          String category = transaction['category'];
          double amount = (transaction['amount'] as int).toDouble(); // Use double for amounts

          print('Checking Transaction: $transaction'); // Debugging

          if (transactionType == type) {
            categorySums[category] = (categorySums[category] ?? 0) + amount;
            print('Adding to Category Sums: $category, Amount: $amount'); // Log added amounts
          }
        }
      } else {
        print('Date Mismatch: $transactionDate'); // Log if date doesn't match
      }
    });
    return categorySums;
  }

  double calculateTotal(Map<String, double> categorySums) {
    return categorySums.values.fold(0.0, (sum, amount) => sum + amount);
  }

  List<PieChartSectionData> buildPieChartSections(Map<String, double> categorySums, List<Color> colors, String noDataTitle) {
    int colorIndex = 0;
    double total = calculateTotal(categorySums);

    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey,
          value: 100,
          title: noDataTitle,
          radius: 100,
          titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ];
    }

    return categorySums.entries.map((entry) {
      final category = entry.key;
      final amount = entry.value;
      final percentage = (amount / total) * 100; // Calculate the percentage
      final color = colors[colorIndex % colors.length]; // Cycle through the colors

      colorIndex++;

      return PieChartSectionData(
        color: color,
        value: amount,
        title: '$category: ${percentage.toStringAsFixed(1)}%', // Display the percentage
        radius: 100,
        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double> incomeSums = calculateCategorySums(0); // Income
    Map<String, double> expenseSums = calculateCategorySums(1); // Expenses
    return Column(
      children: [
        Text(
          '수입 비율',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: buildPieChartSections(incomeSums, [
                Colors.blue,
                Colors.green,
                Colors.cyan,
                Colors.indigo,
                Colors.purple,
              ], '수입 없음'), // No data title for income
            ),
          ),
        ),
        SizedBox(height: 10),
        Text(
          '지출 비율',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: buildPieChartSections(expenseSums, [
                Colors.red,
                Colors.orange,
                Colors.yellow,
                Colors.pink,
                Colors.deepOrange,
              ], '지출 없음'), // No data title for expenses
            ),
          ),
        ),
      ],
    );
  }
}
