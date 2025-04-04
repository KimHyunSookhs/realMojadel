import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mojadel2/homepage/home_detail.dart';
import 'package:mojadel2/mypage/mypage.dart';
import 'package:mojadel2/mypage/tabBar/TabBarList.dart';
import 'package:mojadel2/mypage/tabBar/MyBoardContents.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../colors/colors.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({Key? key}) : super(key: key);
  @override
  _LogInPageState createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late TabController _tabController;

  String? _jwtToken;
  @override
  void initState() {
    super.initState();
  }
  Future<String?> _getJwtToken(String email, String password) async {
    final String uri = 'http://10.0.2.2:4000/api/v1/auth/sign-in';
    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };

    final Map<String, dynamic> body = {
      'email': email,
      'password': password,
    };

    final response = await http.post(
      Uri.parse(uri),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final String jwtToken = responseData['token']; // Assuming the token key is 'token'
      return jwtToken;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('로그인'),
        backgroundColor: AppColors.mintgreen,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // 이메일 입력 필드
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: '이메일',labelStyle: TextStyle(fontSize: 22)
                ),
              ),
              SizedBox(height: 16.0),
              // 비밀번호 입력 필드
              TextField(
                controller: _passwordController,
                obscureText: true, // 비밀번호를 숨깁니다.
                decoration: InputDecoration(
                  labelText: '비밀번호',labelStyle: TextStyle(fontSize: 22)
                ),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () async {
                  // 사용자 정보 수집
                  String email = _emailController.text;
                  String password = _passwordController.text;
                  String? jwtToken = await _getJwtToken(email, password);
                  if (jwtToken != null) {
                    final prefs = await SharedPreferences.getInstance();
                    prefs.setString('jwtToken', jwtToken);
                    prefs.setString('userEmail', email);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) {
                        // 기본으로 MyPageSite를 보여주도록 설정
                        return HomePage(selectedIndex: 4); // MyPage의 인덱스 번호
                      }),
                          (Route<dynamic> route) => false, // 모든 이전 페이지를 제거합니다.
                    );
                   }
                     else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('로그인에 실패했습니다.'),
                        ),
                      );
                  }
                },
                child: Text('로그인'),
              ),
              if (_jwtToken != null)
                Text(
                  'JWT 토큰: $_jwtToken',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
