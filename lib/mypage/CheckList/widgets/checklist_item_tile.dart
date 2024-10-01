// 체크리스트 아이템을 표시하는 커스텀 위젯
// ChecklistScreen에서 사용, 할 일의 내용과 완료 여부를 한 줄로 표시
// ChecklistScreen이 checklist_item_tile.dart를 사용하여 각 할 일을 화면에 표시

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../checklist_provider.dart';
import '../models/category.dart';
import '../models/checklist_item.dart';

class ChecklistItemTile extends StatelessWidget {
  final CustomCategory category;
  final ChecklistItem item;

  ChecklistItemTile({required this.category, required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        item.title,
        style: TextStyle(
          decoration: item.isChecked ? TextDecoration.lineThrough : null,
        ),
      ),
      leading: Checkbox(
        value: item.isChecked,
        onChanged: (value) {
          Provider.of<ChecklistProvider>(context, listen: false)
              .toggleItemChecked(category, item);
        },
      ),
    );
  }
}