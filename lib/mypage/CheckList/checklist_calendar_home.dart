import 'package:flutter/material.dart';
import 'package:mojadel2/mypage/CheckList/widgets/checklist_item_tile.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // intl 패키지 추가
import 'checklist_provider.dart';
import 'models/category.dart';

class ChecklistCalendar extends StatefulWidget {
  @override
  _ChecklistCalendarState createState() => _ChecklistCalendarState();
}

class _ChecklistCalendarState extends State<ChecklistCalendar> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 캘린더 부분
            TableCalendar(
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay, // 필수 인자
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay; // 유지
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                // 텍스트 스타일을 고정하여 셀 크기 변동 방지
                todayTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
                selectedTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return Align(
                    alignment: Alignment.bottomCenter, // 하단 정렬
                    child: Text(
                      '${day.day}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                },
              ),
            ),

            // 체크리스트 부분
            Consumer<ChecklistProvider>(
              builder: (context, provider, child) {
                final categories = provider.getCategoriesForDate(_selectedDay);
                return ListView.builder(
                  physics: NeverScrollableScrollPhysics(), // 내장 스크롤 제거
                  shrinkWrap: true,  // ListView의 높이를 자식의 높이에 맞춤
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return ExpansionTile(
                      initiallyExpanded: true,
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(categories[index].name),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () {
                              _showAddChecklistItemDialog(
                                context,
                                categories[index],
                              );
                            },
                          ),
                        ],
                      ),
                      children: categories[index].items.map((item) {
                        return ChecklistItemTile(
                          category: categories[index],
                          item: item,
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      // FloatingActionButton 추가
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCategoryDialog(context);
        },
        child: Icon(Icons.add),
        tooltip: 'Add Category',
      ),
    );
  }

  // 카테고리 추가 다이얼로그
  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    // DateFormat 클래스를 사용하여 날짜 포맷
    final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$formattedDate\n카테고리 등록'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: '카테고리 이름'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('추가'),
              onPressed: () {
                String categoryName = controller.text.trim();
                if (categoryName.isNotEmpty) {
                  Provider.of<ChecklistProvider>(context, listen: false)
                      .addCategoryForDate(_selectedDay, categoryName);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // 체크리스트 아이템 추가 다이얼로그
  void _showAddChecklistItemDialog(
      BuildContext context, CustomCategory category) {
    final TextEditingController controller = TextEditingController();

    // DateFormat 클래스를 사용하여 날짜 포맷
    final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$formattedDate\n할 일 등록'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: '할 일'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('추가'),
              onPressed: () {
                String itemName = controller.text.trim();
                if (itemName.isNotEmpty) {
                  Provider.of<ChecklistProvider>(context, listen: false)
                      .addItemToCategoryForDate(
                      _selectedDay, category, itemName);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}