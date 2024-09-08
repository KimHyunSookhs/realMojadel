import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mojadel2/Config/ImagePathProvider.dart';
import 'package:mojadel2/Config/getUserInfo.dart';
import 'package:mojadel2/colors/colors.dart';
import 'package:mojadel2/mypage/signup/signup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'getboardcount/getBoardCount.dart';
import 'login/loginpage.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class MyPageSite extends StatefulWidget {
  const MyPageSite({Key? key}) : super(key: key);
  @override
  State<MyPageSite> createState() => _MyPageSiteState();
}

class _MyPageSiteState extends State<MyPageSite> {
  String? _nickname;
  File? _imageFile;
  String? _userEmail;
  String? _jwtToken;
  int? _userBoardCount;
  String? _profileImageUrl;
  ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('jwtToken');
    if (_jwtToken != null) {
      final userInfo = await UserInfoService.getUserInfo(_jwtToken!);
      setState(() {
        _nickname = userInfo['nickname'];
        _userEmail = userInfo['email'];
        _profileImageUrl = userInfo['profileImage'];
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');
    setState(() {
      _nickname = null;
      _jwtToken = null; // jwtToken 초기화
      _profileImageUrl = null;
    });
  }

  Future<void> _uploadImage(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null) {
      try {
        Map<String, String> headers = {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $jwtToken',
        };
        Uri url = Uri.parse('http://10.0.2.2:4000/api/v1/user/profile-image');
        http.Response response = await http.patch(
          url,
          headers: headers,
          body: jsonEncode({'profileImage': imageFile.path}),
        );
        if (response.statusCode == 200) {
          final imageUrl = jsonDecode(response.body)['imageFile'];
          setState(() {
            _imageFile = imageFile;
            _profileImageUrl = imageUrl;
          });
        } else {
          print('Failed to upload image: ${response.statusCode}');
        }
      } catch (e) {
        print('Failed to upload image: $e');
      }
    }
  }

  Future<void> getImage(ImageSource imageSource) async {
    final XFile? pickedFile = await picker.pickImage(source: imageSource);
    if (pickedFile != null) {
      String imagePath = await saveImagePermanently(File(pickedFile.path));
      setState(() {
        _imageFile = File(imagePath);  // 프로필 이미지 파일 설정
        _profileImageUrl = imagePath;  // 프로필 이미지 URL 설정
      });
        _uploadImage(File(imagePath));  // 이미지 업로드
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('마이페이지'),
        backgroundColor: AppColors.mintgreen,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black, // 테두리 선의 색상 설정
                        width: 1.0, // 테두리 선의 두께 설정
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white10,
                      backgroundImage: _profileImageUrl != null
                          ? (_profileImageUrl!.startsWith('http')
                          ? NetworkImage(_profileImageUrl!)
                          : FileImage(File(_profileImageUrl!)) as ImageProvider)
                          : null,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _nickname ?? '비회원',
                        style: TextStyle(fontSize: 23),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(
                            width: 30,
                          ),
                          Row(
                            children: [
                              Text('요모조모 '),
                              FutureBuilder<int?>(
                                future: getUserPostsCount(
                                    _userEmail ?? '', _jwtToken ?? '', _nickname), // getUserPostsCount 함수 사용
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Text('0');
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    final int? postsCount = snapshot.data;
                                    _userBoardCount = postsCount; // _userBoardCount에 postsCount 값 할당
                                    return Text(postsCount != null ? '$postsCount' : '0');
                                  }
                                },
                              ),
                              Text('개')
                            ],
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text('팔로잉 0명'),
                          SizedBox(
                            width: 10,
                          ),
                          Text('팔로워 0명'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(),
            TextButton(
              onPressed: () {
                getImage(ImageSource.gallery);
              },
              child: Text('프로필 사진 변경'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpPage()),
                );
              },
              child: Text('회원가입'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LogInPage()),
                ).then((jwtToken) {
                  if (jwtToken != null) {
                    _loadUserInfo();
                  }
                });
              },
              child: Text('로그인'),
            ),
            TextButton(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('로그아웃 완료'),
                  ),
                );
                await _logout();
              },
              child: Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
