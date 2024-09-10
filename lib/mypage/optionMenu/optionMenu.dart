import 'package:flutter/material.dart';
import '../login/loginpage.dart';
import '../signup/signup.dart';

class OptionMenu extends StatelessWidget {
  final String? userEmail;
  final String? jwtToken;
  final Function() loadUserInfo;
  final Function(String?) updateJwtToken;
  final Function() logoutCallback;

  OptionMenu({
    required this.userEmail,
    required this.jwtToken,
    required this.loadUserInfo,
    required this.updateJwtToken,
    required this.logoutCallback,
  });

  Future<void> handleMenuSelection(BuildContext context, String value) async {
    if (jwtToken == null) {
      if (value == 'login') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => LogInPage()))
            .then((jwtToken) {
          if (jwtToken != null) {
            updateJwtToken(jwtToken);
            loadUserInfo();
          }
        });
      } else if (value == 'signup') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpPage()));
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('로그인이 필요합니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('확인'),
                ),
              ],
            );
          },
        );
      }
    } else {
      switch (value) {
        case 'logout':
          logoutCallback();
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (String value) {
        handleMenuSelection(context, value);
      },
      itemBuilder: (BuildContext context) {
        return (jwtToken == null ? {'signup', 'login'} : {'logout'}).map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Text(
              choice == 'signup' ? '회원가입' : choice == 'login' ? '로그인' : '로그아웃',
            ),
          );
        }).toList();
      },
    );
  }
}
