import 'package:flutter/material.dart';
import 'package:mojadel2/colors/colors.dart';

class EditTransactionPage extends StatefulWidget {
  final String accountLogNumber;
  final String category;
  final String description;
  final int amount;
  final int type; // Assuming this is still a String (e.g., 'income' or 'expense')
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

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.category);
    _descriptionController = TextEditingController(text: widget.description);
    _amountController = TextEditingController(text: widget.amount.toString());
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateTransaction() {
    String category = _categoryController.text;
    String description = _descriptionController.text;
    int amount = int.tryParse(_amountController.text) ?? 0;

    int type = widget.type == 'income' ? 0 : 1; // Convert to int for PATCH request

    // Call the onTransactionUpdated callback with the new values
    widget.onTransactionUpdated(category, description, amount, type);
    Navigator.pop(context); // Close the edit page
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
