import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  String? _jwtToken;

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
      print('JWT 토큰: $jwtToken');
      return jwtToken;
    } else {
      print('로그인 실패');
      print('응답 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');
      return null;
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
                  labelText: '이메일',
                ),
              ),
              SizedBox(height: 16.0),
              // 비밀번호 입력 필드
              TextField(
                controller: _passwordController,
                obscureText: true, // 비밀번호를 숨깁니다.
                decoration: InputDecoration(
                  labelText: '비밀번호',
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  // 사용자 정보 수집
                  String email = _emailController.text;
                  String password = _passwordController.text;
                  String? jwtToken = await _getJwtToken(email, password);
                  print("email: ${email}");
                  if (jwtToken != null) {
                    // 로그인 성공 시 처리
                    print('로그인 성공');
                    final prefs = await SharedPreferences.getInstance();
                    prefs.setString('jwtToken', jwtToken);
                    prefs.setString('userEmail', email);
                    Navigator.pop(context, jwtToken);
                  }
                     else {
                      // 로그인 실패 시 처리
                      print('로그인 실패');
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
