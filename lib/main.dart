import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mojadel2/yomojomo/messageboard.dart';
import 'homepage/home_detail.dart';
import 'mypage/login/loginpage.dart';
import 'mypage/mypage.dart';

void main() {
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp ({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mojadel',
      debugShowCheckedModeBanner: false,
      routes: {
        '/login' : (context) => LogInPage(),
        '/mypagesite' : (context) => MyPageSite(),
      },
      home: HomePage(),
    );
  }
}
