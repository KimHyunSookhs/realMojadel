// 카테고리를 정의하는 데이터 모델, 설계도
// 카테고리 이름, 각 카테고리에 해당하는 체크리스트 아이템

import 'checklist_item.dart';

class CustomCategory {
  String name;
  List<ChecklistItem> items;

  CustomCategory({required this.name, List<ChecklistItem> ? items}) : items = items ?? [];
}