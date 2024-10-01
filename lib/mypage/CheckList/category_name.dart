// 특정 카테고리를 선택했을 때 나타나는 화면. 선택한 카테고리의 할 일 목록을 보여줌
// ChecklistProvider를 사용하여 할 일 목록을 가져오고, 추가, 삭제, 수정 가능
// 일단 안씀

import 'package:flutter/material.dart';
import 'package:mojadel2/mypage/CheckList/widgets/checklist_item_tile.dart';
import 'package:provider/provider.dart';

import 'checklist_provider.dart';
import 'models/category.dart';

class ChecklistScreen extends StatelessWidget {
  final CustomCategory category;
  final DateTime date;

  ChecklistScreen({required this.category, required this.date});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAddItemDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<ChecklistProvider>(
        builder: (context, provider, child) {
          // 날짜 정규화 (시간 정보만 제거)
          final normalizedDate = DateTime(date.year, date.month, date.day);

          // 정규화된 날짜에 대한 카테고리를 가져옴
          final updateCategory = provider
              .getCategoriesForDate(normalizedDate)
              .firstWhere((cat) => cat.name == category.name);

          return ListView.builder(
            itemCount: updateCategory.items.length,
            itemBuilder: (context, index) {
              return ChecklistItemTile(
                  category: updateCategory, item: updateCategory.items[index]);
            },
          );
        },
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Checklist Item'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Checklist Item'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                String itemName = controller.text.trim();
                if (itemName.isNotEmpty) {
                  // 정규화된 날짜와 카테고리로 아이템을 추가
                  final normalizedDate = DateTime(date.year, date.month, date.day);
                  Provider.of<ChecklistProvider>(context, listen: false)
                      .addItemToCategoryForDate(normalizedDate, category, itemName);
                  Navigator.of(context).pop();
                  FocusScope.of(context).unfocus();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
