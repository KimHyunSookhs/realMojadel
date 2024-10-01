import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mojadel2/Config/getUserInfo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddTransactionPage extends StatefulWidget {
  final Function(String, String, int, String, DateTime) onTransactionAdded;
  final String? initialCategory; // 초기 카테고리 값
  final String? initialDescription; // 초기 설명 값
  final int? initialAmount; // 초기 금액 값
  final String? initialType; // 초기 수입/지출 값 ('income' 또는 'expense')
  final DateTime selectedDate; //
  AddTransactionPage({
    required this.onTransactionAdded,
    this.initialCategory, // 수정할 때 사용
    this.initialDescription, // 수정할 때 사용
    this.initialAmount, // 수정할 때 사용
    this.initialType, // 수정할 때 사용
    required this.selectedDate
  });
  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  bool isIncomeSelected = true; // 수입/지출 선택 상태
  String? selectedCategory;
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  List<String> categories = [];
  String? _nickname;
  String? _userEmail;
  String? _jwtToken;
  String? selectedDate;
  int? customTypeNumber;
  String? customTypeName;
  Map<String, int> categoryMap = {};
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    _loadCategories();
    // 수정 모드에서 초기값 설정
    if (widget.initialType != null) {
      isIncomeSelected = widget.initialType == 'income';
    }
    selectedCategory = widget.initialCategory;
    descriptionController.text = widget.initialDescription ?? '';
    if (widget.initialAmount != null) {
      amountController.text = widget.initialAmount.toString();
    }
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('jwtToken');
    if (_jwtToken != null) {
      final userInfo = await UserInfoService.getUserInfo(_jwtToken!);
      setState(() {
        _nickname = userInfo['nickname'];
        _userEmail = userInfo['email'];
      });
    }
  }
  Future<void> _loadCategories() async {
    setState(() {
      isLoadingCategories = true;
    });
    final String uri = 'http://10.0.2.2:4000/api/v1/account-log/custom-type';
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    try {
      http.Response response = await http.get(
        Uri.parse(uri),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> customTypeList = responseData['moneyCustomTypeEntityList'];
        setState(() {
          categoryMap.clear();
          categories.clear();
          customTypeList.forEach((item) {
            final customTypeName = item['customTypeName'];
            final customTypeNumber = item['customTypeNumber'];
            categories.add(customTypeName);
            categoryMap[customTypeName] = customTypeNumber;
          });
        });
      }
    } catch (e) {
    } finally {
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  // 카테고리 저장 함수
  Future<void> _saveCategoryToServer(String categoryName) async {
    try {
      final url = Uri.parse('http://10.0.2.2:4000/api/v1/account-log/custom-type');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_jwtToken',
        },
        body: json.encode({
          'customTypeName': categoryName,
        }),
      );
    } catch (e) {    }
  }

  // 새로운 카테고리 추가 함수
  void _addCategory() {
    TextEditingController newCategoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('새 분류 추가'),
          content: TextField(
            controller: newCategoryController,
            decoration: InputDecoration(hintText: '새 분류 이름 입력'),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (newCategoryController.text.isNotEmpty &&
                    !categories.contains(newCategoryController.text)) {
                  String newCategory = newCategoryController.text;
                  setState(() {
                    categories.add(newCategory);
                    categoryMap[newCategory] = categories.length;
                  });
                  await _saveCategoryToServer(newCategory);
                  await _loadCategories();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('이미 존재하는 분류입니다.')),
                  );
                }
              },
              child: Text('추가'),
            ),
          ],
        );
      },
    );
  }

  // 카테고리 삭제 함수
  Future<void> _deleteCategory(String categoryName) async {
    final customTypeNumber = categoryMap[categoryName]; // 선택된 카테고리의 번호를 가져옴
    if (customTypeNumber != null) {
      try {
        final url = Uri.parse('http://10.0.2.2:4000/api/v1/account-log/custom-type/$customTypeNumber');
        final response = await http.delete(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_jwtToken',
          },
        );
        if (response.statusCode == 200) {
          setState(() {
            categories.remove(categoryName);
            categoryMap.remove(categoryName);
          });
          // 카테고리 삭제 후 새로 로드
          await _loadCategories();
        }
      } catch (e) {
        print('카테고리 삭제 중 오류 발생: $e');
      }
    }
  }
  Future<void> _saveTransaction() async {
    if (selectedCategory != null &&
        amountController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty) {
      int amount = int.parse(amountController.text);
      int type = isIncomeSelected ? 0 : 1; // 0 수입, 1 지출

      final String uri = 'http://10.0.2.2:4000/api/v1/account-log';
      try {
        final response = await http.post(
          Uri.parse(uri),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_jwtToken',
          },
          body: json.encode({
            'content': descriptionController.text,
            'type': type,
            'moneyCustomTypeNumber': categoryMap[selectedCategory],
            'money': amount,
            'datetime' : widget.selectedDate.toIso8601String()
          }),
        );
        if (response.statusCode == 200) {
          await _loadCategories();
          Navigator.of(context).pop();
        }
      } catch (e) {      }
    }
  }

  void _showDeleteCategoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('분류 삭제'),
          content: categoryMap.isEmpty
              ? Text('삭제할 분류가 없습니다.')
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: categoryMap.keys.map((category) {
              return ListTile(
                title: Text(category),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _deleteCategory(category); // 선택된 카테고리 삭제
                    Navigator.of(context).pop(); // 다이얼로그 닫기
                    _loadCategories();
                  },
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('닫기'),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('수입/지출 추가'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.menu), // 햄버거 메뉴 아이콘
            onSelected: (String result) {
              if (result == 'add') {
                _addCategory(); // 분류 추가 함수 호출
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'add',
                child: Text('분류 추가'),
              ),
              PopupMenuItem(
                enabled: categories.isNotEmpty,
                child: Text('분류 삭제'),
                onTap: () async {
                  await Future.delayed(Duration.zero); // 메뉴가 닫힌 후 동작
                  _showDeleteCategoryDialog();
                },
              ),
            ],
          ),
        ],
      ),
      resizeToAvoidBottomInset: true, // 이 속성을 추가하여 키보드에 의해 화면이 가려지지 않도록 함
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 수입/지출 선택
            ToggleButtons(
              borderColor: Colors.grey, // 버튼 테두리 색상
              fillColor: Colors.blueAccent.withOpacity(0.2), // 선택된 버튼의 배경색
              borderRadius: BorderRadius.circular(10), // 둥근 모서리
              selectedBorderColor: Colors.blueAccent, // 선택된 버튼의 테두리 색상
              selectedColor: Colors.blue, // 선택된 버튼의 텍스트 색상
              color: Colors.black, // 기본 버튼 텍스트 색상
              textStyle: TextStyle(
                fontWeight: FontWeight.bold, // 버튼 텍스트 굵게
                fontSize: 16, // 텍스트 크기
              ),
              isSelected: [isIncomeSelected, !isIncomeSelected],
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('수입'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('지출'),
                ),
              ],
              onPressed: (int index) {
                setState(() {
                  isIncomeSelected = index == 0;
                });
              },
            ),
            SizedBox(height: 20),

            // 분류 선택 (DropdownButton)
            DropdownButton<String>(
              hint: Text('분류 선택'),
              value: selectedCategory,
              items: categories.isNotEmpty // Check if categories is not empty
                  ? categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList()
                  : [], // If empty, show no options
              onChanged: categories.isNotEmpty // Disable interaction if categories is empty
                  ? (String? newValue) {
                setState(() {
                  selectedCategory = newValue;
                });
              }
                  : null,
            ),
            SizedBox(height: 10),

            // 금액 입력
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: '금액 (원)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),

            // 내용 입력
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: '내용'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveTransaction, // Call the new function to save the transaction
        child: Icon(Icons.check),
      ),
    );
  }
}