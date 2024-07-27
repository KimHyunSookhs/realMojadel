import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mojadel2/firebase_options.dart';
import 'homepage/home_detail.dart';
import 'mypage/login/loginpage.dart';
import 'mypage/mypage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform),
      builder: (context, snapshot) {
        return MaterialApp(
          title: 'mojadel',
          debugShowCheckedModeBanner: false,
          routes: {
            '/login': (context) => LogInPage(),
            '/mypagesite': (context) => MyPageSite(),
          },
          home: HomePage(),
        );
      },
    );
  }
}
