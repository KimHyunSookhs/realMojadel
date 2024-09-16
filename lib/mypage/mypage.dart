import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mojadel2/Config/ImagePathProvider.dart';
import 'package:mojadel2/Config/getUserInfo.dart';
import 'package:mojadel2/colors/colors.dart';
import 'package:mojadel2/mypage/getboardcount/showBoardCounts.dart';
import 'package:mojadel2/mypage/tabBar/TabBarList.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'optionMenu/optionMenu.dart';

class MyPageSite extends StatefulWidget {
  const MyPageSite({Key? key}) : super(key: key);
  @override
  State<MyPageSite> createState() => _MyPageSiteState();
}

class _MyPageSiteState extends State<MyPageSite>
    with SingleTickerProviderStateMixin {
  String? _nickname;
  File? _imageFile;
  String? _userEmail;
  String? _jwtToken;
  String? _profileImageUrl;
  ImagePicker picker = ImagePicker();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    _tabController =
        TabController(length: 3, vsync: this);
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
        _imageFile = File(imagePath);
        _profileImageUrl = imagePath;
      });
        _uploadImage(File(imagePath));
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
    setState(() {
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
            uploadImage: _uploadImage, // 이미지 업로드 함수 전달
            profileImageUrl: _profileImageUrl,
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
                        child: ShowBoardCounts(
                          userEmail: _userEmail,
                          jwtToken: _jwtToken,
                          nickname: _nickname,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(),
            Container(
              height: 400,  // Provide a fixed height or adjust according to your layout
              child: TabBarUsingController2(),
            ),
          ],
        ),
      ),
    );
  }
}
