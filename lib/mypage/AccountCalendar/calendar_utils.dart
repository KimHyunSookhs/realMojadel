List<Map<String, dynamic>> insertDays(int year, int month) {
  List<Map<String, dynamic>> days = [];

  // 이번 달의 마지막 날 계산
  int lastDay = DateTime(year, month + 1, 0).day;

  // 이번 달의 날짜 추가
  for (var i = 1; i <= lastDay; i++) {
    days.add({
      "year": year,
      "month": month,
      "day": i,
      "inMonth": true, // 이번 달에 속하는지 여부
    });
  }

  // 이번 달의 첫날이 무슨 요일인지 계산하고 이전 달 날짜 추가
  int firstWeekday = DateTime(year, month, 1).weekday; // 1: 월요일, 7: 일요일

  // 요일을 일요일을 기준으로 변경 (일요일을 0으로 처리)
  firstWeekday = firstWeekday == 7 ? 0 : firstWeekday;

  // 첫 날이 일요일이 아니면 이전 달 날짜 추가
  if (firstWeekday != 0) {
    List<Map<String, dynamic>> temp = [];
    int prevYear = month == 1 ? year - 1 : year;
    int prevMonth = month == 1 ? 12 : month - 1;
    int prevLastDay = DateTime(prevYear, prevMonth + 1, 0).day;

    for (var i = firstWeekday; i > 0; i--) {
      temp.add({
        "year": prevYear,
        "month": prevMonth,
        "day": prevLastDay - i + 1,
        "inMonth": false, // 이번 달에 속하지 않는 날짜
      });
    }
    days = [...temp, ...days];
  }

  // 다음 달 날짜 추가 (총 5주 또는 6주로 채우기)
  int remainingCells = 35 - days.length;
  if (remainingCells < 0) remainingCells = 42 - days.length; // 6주일 경우 처리
  List<Map<String, dynamic>> temp = [];
  int nextYear = month == 12 ? year + 1 : year;
  int nextMonth = month == 12 ? 1 : month + 1;

  for (var i = 1; i <= remainingCells; i++) {
    temp.add({
      "year": nextYear,
      "month": nextMonth,
      "day": i,
      "inMonth": false, // 이번 달에 속하지 않는 날짜
    });
  }
  days = [...days, ...temp];

  return days;
}
