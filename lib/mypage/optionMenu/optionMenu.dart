import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mojadel2/mypage/propfileChange/propfileChange.dart';
import 'package:mojadel2/mypage/tabBar/TabBarList.dart';
import '../login/loginpage.dart';
import '../signup/signup.dart';

class OptionMenu extends StatelessWidget {
  final String? userEmail;
  final String? jwtToken;
  final Function() loadUserInfo;
  final Function(String?) updateJwtToken;
  final Function() logoutCallback;
  final Function(File imageFile) uploadImage;
  final String? profileImageUrl;

  OptionMenu({
    required this.userEmail,
    required this.jwtToken,
    required this.loadUserInfo,
    required this.updateJwtToken,
    required this.logoutCallback,
    required this.uploadImage,
    this.profileImageUrl,
  });

  Future<void> handleMenuSelection(BuildContext context, String value) async {
    if (jwtToken == null) {
      if (value == 'login') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => LogInPage()))
            .then((jwtToken) {
          if (jwtToken != null) {
            updateJwtToken(jwtToken);
            loadUserInfo();
            TabBarUsingController2();
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
        case 'changeProfile':
       await   Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileChangePage(
                uploadImage: uploadImage,  
                profileImageUrl: profileImageUrl, 
              ),
            ),
          );
          loadUserInfo();  // user정보를 다시한번 불러와서 프로필 이미지 변경된것 바로 확인가능
          break;
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
        if (jwtToken == null) {
          return {'signup', 'login'}.map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(
                choice == 'signup' ? '회원가입' : '로그인',
              ),
            );
          }).toList();
        } else {
          return {'changeProfile', 'logout'}.map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(
                choice == 'changeProfile' ? '프로필 변경' : '로그아웃',
              ),
            );
          }).toList();
        }
      },
    );
  }
}



