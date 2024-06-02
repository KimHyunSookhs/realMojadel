import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mojadel2/colors/colors.dart';

import '../../config/user_model.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _telNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _addressDetailController =
  TextEditingController();
  bool _agreedPersonal = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: AppColors.mintgreen,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: '이메일',
                  hintText: 'howse@naver.com',
                ),
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                ),
                obscureText: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요.';
                  } else if (value.length < 8) {
                    return '비밀번호는 8자 이상이어야 합니다.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: '닉네임',
                ),
              ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: _telNumberController,
                decoration: InputDecoration(
                  labelText: '휴대폰 번호',
                ),
              ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: '주소',
                ),
              ),
              SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: _addressDetailController,
                decoration: InputDecoration(
                  labelText: '상세 주소',
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Text('개인정보 동의'),
                  Checkbox(
                    value: _agreedPersonal,
                    onChanged: (newValue) {
                      setState(() {
                        _agreedPersonal = newValue!;
                      });
                    },
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () async {
                  User user = User(
                    email: _emailController.text,
                    password: _passwordController.text,
                    nickname: _nicknameController.text,
                    telNumber: _telNumberController.text,
                    address: _addressController.text,
                    addressDetail: _addressDetailController.text,
                    agreedPersonal: _agreedPersonal,
                  );
                  String requestBody = json.encode(user.toJson());

                  String uri = 'http://10.0.2.2:4000/api/v1/auth/sign-up';
                  try {
                    final response = await http.post(Uri.parse(uri),
                      headers: <String, String>{
                        'Content-Type': 'application/json; charset=UTF-8',
                      },
                      body: requestBody,);

                    if (response.statusCode == 200) {
                      // 서버로부터 성공적으로 응답 받음
                      print('회원가입 성공');
                      Navigator.pushReplacementNamed(context, '/login');
                    } else {
                      // 서버로부터 오류 응답 받음
                      print('회원가입 실패: ${response.body}');
                    }
                  } catch (e) {
                    print('회원가입 요청 실패: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('회원가입 요청에 실패했습니다.'),
                      ),
                    );
                  }
                },
                child: Text('회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}