// 재사용 가능한 작은 조각(위젯)
// HomeScreen에서 사용, 각 카테고리의 이름을 한 줄로 표시, 사용자가 누르면 해당 카테고리의 할 일 목록을 보여줌
// HomeScreen이 category_list_tile.dart를 사용하여 각 카테고리를 화면에 표시

import 'package:flutter/material.dart';
import '../category_name.dart';
import '../models/category.dart';

class CategoryListTile extends StatelessWidget {
  final CustomCategory category;
  final DateTime date;  // 날짜도 인자로 받음

  CategoryListTile({required this.category, required this.date});  // 날짜를 받도록 수정

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(category.name),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChecklistScreen(
              category: category,
              date: date,  // 전달받은 날짜를 ChecklistScreen으로 전달
            ),
          ),
        );
      },
    );
  }
}