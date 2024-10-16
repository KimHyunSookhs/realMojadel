import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'calendar_utils.dart';
import 'TransactionPage/show_transaction_page.dart';
import 'day_widget.dart';
import 'sum_of_week_transaction.dart';
import 'TransactionPage/show_pie_transaction.dart';
import 'package:fl_chart/fl_chart.dart';

class CalendarWidget extends StatefulWidget {
  @override
  _CalendarWidgetState createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  List<Map<String, dynamic>> days = [];
  final List<String> week = ["일", "월", "화", "수", "목", "금", "토"];
  int year = DateTime
      .now()
      .year;
  int month = DateTime
      .now()
      .month;
  String? _jwtToken;
  int? totalExpense;
  int? totalIncome;
  List<Map<String, dynamic>> accountLogItemList = [];

  // 날짜별 수입과 지출 데이터를 저장할 Map (타입 변경)
  Map<DateTime, List<Map<String, dynamic>>> transactions = {};

  // 전체 수입/지출을 저장하는 변수
  Map<DateTime, Map<String, int>> totalTransactions = {};
  Map<String, Map<String, int>> categorySums = {};

  @override
  void initState() {
    super.initState();
    days = insertDays(year, month);
    fetchCalendarData();
    fetchMonthTransactions().then((_) {
      setState(() {}); // Ensure the UI updates after fetching transactions
    });
    _loadUserInfo().then((_) {});
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('jwtToken');
  }
  Future<void> authenticateUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('https://your-api-url.com/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      String token = jsonResponse['token'];
      // JWT를 저장하거나 사용
    } else {
      throw Exception('Failed to authenticate user');
    }
  }

  Future<void> fetchCalendarData() async {
    final String date = '${year.toString()}-${month.toString().padLeft(
        2, '0')}';
    final String uri = 'http://43.203.121.121:4000/api/v1/account-log/calender?datetime=$date';

    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');

    try {
      final response = await http.get(
        Uri.parse(uri),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> calendarData = List<
            Map<String, dynamic>>.from(data['calender']);

        for (var dayData in calendarData) {
          DateTime date = DateTime(year, month, dayData['day']);
          int totalIncome = dayData['totalIncome'] ?? 0;
          int totalExpense = dayData['totalExpense'] ?? 0;

          totalTransactions[date] = {
            'income': totalIncome,
            'expense': totalExpense,
          };
        }
        setState(() {});
      }
    } catch (e) {}
  }

  Future<void> fetchMonthTransactions() async {
    Map<String, Map<String, int>> categorySums = {}; // category별 금액 합계를 저장할 맵

    // 해당 월의 모든 날짜를 가져옴
    for (int day = 1; day <= DateTime(year, month + 1, 0).day; day++) {
      DateTime selectedDate = DateTime(year, month, day);
      final String formattedDateTime = DateFormat('yyyy-MM-dd').format(
          selectedDate);
      final String uri = 'http://43.203.121.121:4000/api/v1/account-log/day?datetime=$formattedDateTime';

      try {
        final response = await http.get(Uri.parse(uri), headers: {
          'Authorization': 'Bearer $_jwtToken',
        });
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(
              utf8.decode(response.bodyBytes));
          List<Map<String,
              dynamic>> dailyLogs = (responseData['accountLogItemList'] as List<
              dynamic>? ?? []).map((item) {
            return {
              'accountLogNumber': item['accountLogNumber'],
              'category': item['customTypeName'] ?? 'Unknown',
              'description': item['content'] ?? 'No Description',
              'amount': item['money'] ?? 0,
              'type': item['type'] == 0 ? 'income' : 'expense',
            };
          }).toList();
          // 각 날짜의 accountLogItemList를 누적하여 저장
          setState(() {
            accountLogItemList.addAll(dailyLogs);
            this.categorySums = categorySums;
          });

          // category별 amount 합계 계산
          for (var log in dailyLogs) {
            String category = log['category'];
            int amount = (log['amount'] as int);
            String type = log['type'];

            // Update categorySums with category and type
            if (!categorySums.containsKey(category)) {
              categorySums[category] = {};
            }
            categorySums[category]![type] =
                (categorySums[category]![type] ?? 0) + amount;
          }
        }
      } catch (e) {
        print('Error fetching transactions for $formattedDateTime: $e');
      }
    }
  }

  List<PieChartSectionData> getPieChartSections(
      Map<String, Map<String, int>> categorySums, String type) {
    // Define a list of brighter colors
    List<Color> colors = [
      Colors.yellowAccent,
      Colors.lightGreen,
      Colors.orangeAccent,
      Colors.lightBlue,
      Colors.pinkAccent,
      Colors.redAccent,
      Colors.blueAccent,
      Colors.tealAccent,
    ];

    return categorySums.entries.map((entry) {
      final category = entry.key;
      final amount = entry.value[type] ?? 0;

      return PieChartSectionData(
        color: colors[categorySums.keys.toList().indexOf(category) %
            colors.length], // Use bright colors
        value: amount.toDouble(),
        title: '$category\n$amount',
        radius: 80, // Increase the radius for a bigger pie chart section
      );
    }).toList();
  }

  Widget buildWeekRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: week.map((day) {
        return Expanded(
          child: Container(
            padding: EdgeInsets.all(8.0),
            alignment: Alignment.center,
            child: Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: day == "일" ? Colors.red : (day == "토"
                    ? Colors.blue
                    : Colors.black),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 트랜잭션 추가 함수
  void _addTransaction(DateTime date, String category, String description,
      int amount, String type) {
    setState(() {
      transactions[date] ??= [];
      transactions[date]!.add({
        'category': category,
        'description': description,
        'amount': amount,
        'type': type,
      });
    });
  }

// GridView로 날짜를 표시하는 함수
  Widget buildDaysGrid(int weekIndex, List<Map<String, int>> weeklySums) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GridView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemCount: 7,
          itemBuilder: (context, dayIndex) {
            int index = weekIndex * 7 + dayIndex;
            if (index >= days.length) return Container();
            var day = days[index];
            DateTime currentDay = DateTime(
                day['year'], day['month'], day['day']);
            var transaction = transactions[currentDay];

            int totalIncome = totalTransactions[currentDay]?['income'] ?? 0;
            int totalExpense = totalTransactions[currentDay]?['expense'] ?? 0;

            return DayWidget(
              day: day,
              transaction: transaction,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ShowTransactionPage(
                          selectedDate: currentDay,
                          allTransactions: transactions[currentDay] ?? [],
                          onTransactionAdded: (String category,
                              String description, int amount, String type) {
                            _addTransaction(
                                currentDay, category, description, amount,
                                type);
                          },
                        ),
                  ),
                );
                fetchCalendarData();
                fetchMonthTransactions();
              },
              onUpdate: (int income, int expense) {
                setState(() {
                  totalIncome = income;
                  totalExpense = expense;
                });
              },
              totalIncome: totalTransactions[currentDay]?['income'] ?? 0,
              // Using pre-calculated totals
              totalExpense: totalTransactions[currentDay]?['expense'] ?? 0,
            );
          },
        ),
        SumOfWeekTransaction(weeklySum: weeklySums[weekIndex]),
      ],
    );
  }

// 주마다 수입과 지출을 계산하는 함수
  List<Map<String, int>> calculateWeeklySums() {
    List<Map<String, int>> weeklySums = [];
    int incomeSum = 0;
    int expenseSum = 0;

    for (int i = 0; i < days.length; i++) {
      DateTime currentDay = DateTime(
          days[i]['year'], days[i]['month'], days[i]['day']);

      // Get total income and expense directly from totalTransactions
      incomeSum += totalTransactions[currentDay]?['income'] ?? 0;
      expenseSum += totalTransactions[currentDay]?['expense'] ?? 0;

      // One week ends or last day of the month
      if ((i + 1) % 7 == 0 || i == days.length - 1) {
        weeklySums.add({
          'weekIncome': incomeSum,
          'weekExpense': expenseSum,
        });

        // Reset sums for the next week
        incomeSum = 0;
        expenseSum = 0;
      }
    }

    return weeklySums;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, int>> weeklySums = calculateWeeklySums(); // 주별 수입/지출 합계 계산
    bool hasIncomeData = categorySums.isNotEmpty &&
        categorySums.values.any((sum) => sum['income'] != null &&
            sum['income']! > 0);
    bool hasExpenseData = categorySums.isNotEmpty &&
        categorySums.values.any((sum) => sum['expense'] != null &&
            sum['expense']! > 0);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('$year년 $month월'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              if (month == 1) {
                year -= 1;
                month = 12;
              } else {
                month -= 1;
              }
              days = insertDays(year, month);
            });
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: () {
              setState(() {
                if (month == 12) {
                  year += 1;
                  month = 1;
                } else {
                  month += 1;
                }
                days = insertDays(year, month);
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            buildWeekRow(), // 요일을 보여주는 위젯 호출
            ListView.builder(
              shrinkWrap: true, // ListView 높이를 내용에 맞게 설정
              physics: NeverScrollableScrollPhysics(), // ListView의 스크롤 비활성화
              itemCount: (days.length / 7).ceil(), // 7일 단위로 나누어 주 수 계산
              itemBuilder: (context, weekIndex) {
                return buildDaysGrid(weekIndex, weeklySums); // 분리된 함수 호출
              },
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text("소득 비율", style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 300, child: hasIncomeData
                      ? PieChart(
                    PieChartData(
                      sections: getPieChartSections(categorySums, 'income'),
                      borderData: FlBorderData(show: false),
                      centerSpaceRadius: 40,
                    ),
                  )
                      : Center(
                    child: Text(
                      "소득 없음",
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                  )),
                  SizedBox(height: 20),
                  Text("지출 비율", style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 300, child: hasExpenseData
                      ? PieChart(
                    PieChartData(
                      sections: getPieChartSections(categorySums, 'expense'),
                      borderData: FlBorderData(show: false),
                      centerSpaceRadius: 40,
                    ),
                  )
                      : Center(
                    child: Text(
                      "지출 없음",
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CalendarWidget(),
  ));
}