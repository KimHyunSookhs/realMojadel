import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mojadel2/colors/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_transaction_page.dart';
import 'editTransactionPage.dart'; // 새로 추가한 페이지 임포트

class ShowTransactionPage extends StatefulWidget {
  final DateTime selectedDate;
  final List<Map<String, dynamic>> allTransactions;
  final Function(String, String, int, String) onTransactionAdded;

  ShowTransactionPage({
    required this.selectedDate,
    required this.allTransactions,
    required this.onTransactionAdded,
  });

  @override
  _ShowTransactionPageState createState() => _ShowTransactionPageState();
}

class _ShowTransactionPageState extends State<ShowTransactionPage> {
  late DateTime _selectedDate;
  int totalIncome = 0;
  int totalExpense = 0;
  List<Map<String, dynamic>> accountLogItemList = [];
  String? _jwtToken;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _loadUserInfo().then((_) {
      fetchTransactions(_selectedDate);
    });
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('jwtToken');
  }

  void onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    fetchTransactions(date);
  }
  Future<void> fetchTransactions(DateTime selectedDate) async {
    final String formattedDateTime = DateFormat('yyyy-MM-dd').format(selectedDate);
    final String uri = 'http://13.125.228.152:4000/api/v1/account-log/day?datetime=$formattedDateTime';
    try {
      final response = await http.get(Uri.parse(uri), headers: {
        'Authorization': 'Bearer $_jwtToken',
      });
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            totalIncome = responseData['totalIncome'] ?? 0;
            totalExpense = responseData['totalExpense'] ?? 0;
            accountLogItemList = (responseData['accountLogItemList'] as List<dynamic>? ?? []).map((item) {
              return {
                'accountLogNumber': item['accountLogNumber'],
                'category': item['customTypeName'] ?? 'Unknown',
                'description': item['content'] ?? 'No Description',
                'amount': item['money'] ?? 0,
                'type': item['type'] == 0 ? 'income' : 'expense',
              };
            }).toList();
          });
        }
      }
      else {
        print('Error: ${response.statusCode} - ${response.body}');
        print("Formatted Date Time: $accountLogItemList");
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      print("Formatted Date Time: $accountLogItemList");
    }
  }

  Widget buildTransactionSection(String title, int total, Color color, List<Map<String, dynamic>> filteredItems) {
    List<Widget> transactionWidgets = filteredItems.map((item) => _buildTransactionRow(item)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('$total 원', style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 10),
        ...transactionWidgets,
      ],
    );
  }
  Widget _buildTransactionRow(Map<String, dynamic> item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('${item['category']}', style: TextStyle(fontSize: 16)),
        Text('${item['description']}', style: TextStyle(fontSize: 16)),
        Text('${item['amount']} 원', style: TextStyle(fontSize: 16, color: item['type'] == 'income' ? Colors.blue : Colors.red)),
        PopupMenuButton<String>(
          onSelected: (String value) {
            if (value == 'edit') {
              _editTransaction(item);
            } else if (value == 'delete') {
              _confirmDelete(item['accountLogNumber'].toString()); // Convert to string
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(value: 'edit', child: Text('수정')),
            PopupMenuItem(value: 'delete', child: Text('삭제')),
          ],
          icon: Icon(Icons.more_vert),
        ),
      ],
    );
  }
  void _editTransaction(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionPage(
          accountLogNumber: item['accountLogNumber'],
          category: item['category'],
          description: item['description'],
          amount: item['amount'],
          type: item['type'] == 'income' ? 0 : 1,
          onTransactionUpdated: (String category, String description, int amount, int type) {
            _updateTransaction(item['accountLogNumber'].toString(), category, description, amount, type);
          },
        ),
      ),
    );
  }

  Future<void> _updateTransaction(String accountLogNumber, String category, String description, int amount, int type) async {
    final String uri = 'http://13.125.228.152:4000/api/v1/account-log/$accountLogNumber';
    final body = json.encode({
      "content": description,
      "type": type,
      "moneyCustomTypeNumber": category,
      "money": amount,
      "datetime": DateTime.now().toIso8601String(),
    });

    try {
      final response = await http.patch(
        Uri.parse(uri),
        headers: {
          'Authorization': 'Bearer $_jwtToken',
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (response.statusCode == 200) {
        print('Transaction updated successfully');
      }
    } catch (e) {
      print('Error updating transaction: $e');
    }
  }

  Future<void> _confirmDelete(String accountLogNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('삭제 확인'),
          content: Text('이 거래를 정말 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // User confirmed deletion
              child: Text('삭제'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // User canceled
              child: Text('취소'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      _deleteTransaction(accountLogNumber);
    }
  }

  Future<void> _deleteTransaction(String accountLogNumber) async {
    final String uri = 'http://13.125.228.152:4000/api/v1/account-log/$accountLogNumber';
    try {
      final response = await http.delete(
        Uri.parse(uri),
        headers: {
          'Authorization': 'Bearer $_jwtToken',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          accountLogItemList.removeWhere((item) => item['accountLogNumber'].toString() == accountLogNumber);
          totalIncome = accountLogItemList.where((item) => item['type'] == 'income').fold(0, (sum, item) => sum + (item['amount'] as int));
          totalExpense = accountLogItemList.where((item) => item['type'] == 'expense').fold(0, (sum, item) => sum + (item['amount'] as int));
        });
      }
    } catch (e) {
      print('Error deleting transaction: $e');
    }
  }

  void _selectDate(BuildContext context) {
    DateTime tempSelectedDate = _selectedDate;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 300,
          child: Column(
            children: [
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: _selectedDate,
                  mode: CupertinoDatePickerMode.date,
                  onDateTimeChanged: (DateTime newDate) {
                    tempSelectedDate = newDate;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = tempSelectedDate;
                      fetchTransactions(_selectedDate); // Fetch transactions for the selected date
                    });
                    Navigator.pop(context);
                  },
                  child: Text('확인'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> incomeItems = accountLogItemList.where((item) => item['type'] == 'income').toList();
    List<Map<String, dynamic>> expenseItems = accountLogItemList.where((item) => item['type'] == 'expense').toList();

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => _selectDate(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일'),
              Icon(Icons.calendar_today, size: 20),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildTransactionSection('총 수입', totalIncome, Colors.blue, incomeItems),
            Divider(),
            SizedBox(height: 10),
            buildTransactionSection('총 지출', totalExpense, Colors.red, expenseItems),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.mintgreen,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionPage(
                onTransactionAdded: (String category, String description, int amount, String type, DateTime datetime) async {
                  setState(() {
                    accountLogItemList.add({
                      'category': category,
                      'description': description,
                      'amount': amount,
                      'type': type,
                    });
                    // Update totals locally
                    if (type == 'income') {
                      totalIncome += amount;
                    } else {
                      totalExpense += amount;
                    }
                  });
                },
                selectedDate: _selectedDate,
              ),
            ),
          );
             fetchTransactions(_selectedDate);
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
