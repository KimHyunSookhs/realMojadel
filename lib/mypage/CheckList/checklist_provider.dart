// 카테고리와 체크리스트 아이템의 상태를 관리하는 ChangeNotifier 클래스
// 앱 전체에서 카테고리와 할 일 목록을 관리하는 두뇌 역할
// 새로운 카테고리 추가, 할 일 목록에 아이템 추가, 아이템의 상태 변경
// Provider : 공급자

import 'package:flutter/foundation.dart';
import 'models/category.dart';
import 'models/checklist_item.dart';



class ChecklistProvider with ChangeNotifier {
  // 날짜별로 카테고리와 체크리스트를 저장하는 맵
  Map<DateTime, List<CustomCategory>> _categoriesByDate = {};

  // 날짜를 기준으로 시간 정보를 제거한 날짜를 생성
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // 특정 날짜의 카테고리 리스트를 가져오기
  List<CustomCategory> getCategoriesForDate(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    return _categoriesByDate[normalizedDate] ?? [];
  }

  // 특정 날짜에 카테고리 추가
  void addCategoryForDate(DateTime date, String name) {
    final normalizedDate = _normalizeDate(date);
    if (_categoriesByDate[normalizedDate] == null) {
      _categoriesByDate[normalizedDate] = [];
    }
    _categoriesByDate[normalizedDate]?.add(CustomCategory(name: name));
    notifyListeners();
  }

  // 특정 날짜의 카테고리에 체크리스트 아이템 추가
  void addItemToCategoryForDate(DateTime date, CustomCategory category, String title) {
    final normalizedDate = _normalizeDate(date);
    category.items.add(ChecklistItem(title: title));
    notifyListeners();
  }

  // 체크리스트 아이템의 체크 상태를 토글하는 메서드
  void toggleItemChecked(CustomCategory category, ChecklistItem item) {
    item.isChecked = !item.isChecked;  // 체크 상태를 반전
    notifyListeners();  // UI에 상태 변경 알림
  }

  // 특정 날짜에 존재하는 모든 카테고리의 아이템 개수를 반환하는 메서드 추가
  int getItemCountForDate(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    final categories = _categoriesByDate[normalizedDate] ?? [];
    int itemCount = 0;

    for (var category in categories) {
      itemCount += category.items.length;
    }

    return itemCount;
  }
}
