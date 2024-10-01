// 체크리스트 아이템을 정의하는 데이터 모델
// 할 일의 내용과완료 여부 저장

class ChecklistItem {
  String title;
  bool isChecked;

  ChecklistItem({required this.title, this.isChecked = false});
}