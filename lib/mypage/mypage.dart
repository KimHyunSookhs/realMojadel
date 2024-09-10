import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mojadel2/Config/ImagePathProvider.dart';
import 'package:mojadel2/Config/getUserInfo.dart';
import 'package:mojadel2/colors/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'getboardcount/getBoardCount.dart';
import 'getboardcount/getRecipeBoardCount.dart';
import 'getboardcount/getTradeBoardCount.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'optionMenu/optionMenu.dart';

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
  int? _userRecipeBoardCount;
  String? _profileImageUrl;
  ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwtToken');
    setState(() {
      _nickname = null;
      _jwtToken = null;
      _profileImageUrl = null;
    });
  }
  Future<void> updateJwtToken(String? jwtToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwtToken', jwtToken!);
    setState(() {
      _jwtToken = jwtToken;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('마이페이지'),
        backgroundColor: AppColors.mintgreen,
        actions: [
          OptionMenu(
            userEmail: _userEmail,
            jwtToken: _jwtToken,
            loadUserInfo: loadUserInfo,
            updateJwtToken: (String? jwtToken) => updateJwtToken(jwtToken),
            logoutCallback: logout,
          ),
        ],
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
                        color: Colors.black,
                        width: 1.0,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _nickname ?? '비회원',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6,),
                      Container(
                        padding: const EdgeInsets.all(5.0),
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: Colors.grey.shade300, // 테두리 색상
                            width: 1.0, // 테두리 두께
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              SizedBox(width: 5),
                              Row(
                                children: [
                                  Text('요모조모 '),
                                  FutureBuilder<int?>(
                                    future: getUserPostsCount(
                                        _userEmail ?? '', _jwtToken ?? '', _nickname),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Text('0');
                                      } else if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      } else {
                                        final int? postsCount = snapshot.data;
                                        _userBoardCount = postsCount;
                                        return Text(postsCount != null ? '$postsCount' : '0');
                                      }
                                    },
                                  ),
                                  Text('개'),
                                  VerticalDivider(
                                    width: 12,
                                    thickness: 0.6,
                                    color: Colors.black,
                                  ),
                                  Text('레시피 '),
                                  FutureBuilder<int?>(
                                    future: getUserRecipePostsCount(
                                        _userEmail ?? '', _jwtToken ?? '', _nickname),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Text('0');
                                      } else if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      } else {
                                        final int? postsCount = snapshot.data;
                                        _userBoardCount = postsCount;
                                        return Text(postsCount != null ? '$postsCount' : '0');
                                      }
                                    },
                                  ),
                                  Text('개'),
                                  VerticalDivider(
                                    width: 12,
                                    thickness: 0.6,
                                    color: Colors.black,
                                  ),
                                  Text('중고거래 '),
                                  FutureBuilder<int?>(
                                    future: getUserTradePostsCount(
                                        _userEmail ?? '', _jwtToken ?? '', _nickname),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Text('0');
                                      } else if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      } else {
                                        final int? postsCount = snapshot.data;
                                        _userBoardCount = postsCount;
                                        return Text(postsCount != null ? '$postsCount' : '0');
                                      }
                                    },
                                  ),
                                  Text('개'),
                                  SizedBox(width: 5),
                                ],
                              ),
                            ],
                          ),
                        ),
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
          ],
        ),
      ),
    );
  }
}
