import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mojadel2/colors/colors.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditTransactionPage extends StatefulWidget {
  final int accountLogNumber;
  final String category;
  final String description;
  final int amount;
  final int type;
  final Function(String, String, int, int) onTransactionUpdated; // Change here

  EditTransactionPage({
    required this.accountLogNumber,
    required this.category,
    required this.description,
    required this.amount,
    required this.type,
    required this.onTransactionUpdated,
  });

  @override
  _EditTransactionPageState createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  String? _jwtToken;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.category);
    _descriptionController = TextEditingController(text: widget.description);
    _amountController = TextEditingController(text: widget.amount.toString());
    loadUserInfo();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }
  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('jwtToken');

  }
  Future<void> _updateTransaction() async {
    String category = _categoryController.text;
    String description = _descriptionController.text;
    int amount = int.tryParse(_amountController.text) ?? 0;
    int type = widget.type; // 이미 정수로 되어있으므로 변환 불필요

    // 서버에 PATCH 요청 보내기
    try {
      final url = Uri.parse('http://43.203.230.194:4000/api/v1/account-log/${widget.accountLogNumber}');

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_jwtToken',
        },
        body: jsonEncode({
          'category': category,
          'description': description,
          'amount': amount,
          'type': type,
        }),
      );
      if (response.statusCode == 200) {
        widget.onTransactionUpdated(category, description, amount, type);
        Navigator.pop(context);
      }
      else{
        print('${response.body}');
        print('${description}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('가계부 수정'),
        backgroundColor: AppColors.mintgreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(labelText: '분류'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: '내용'),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '금액'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateTransaction,
              child: Text('업데이트',
                style: TextStyle(color: Colors.black),),
            ),
          ],
        ),
      ),
    );
  }
}