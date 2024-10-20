import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mojadel2/colors/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../Config/getUserInfo.dart';

class ProfileChangePage extends StatefulWidget {
  final Function(File imageFile) uploadImage;
  final String? profileImageUrl;

  const ProfileChangePage({
    Key? key,
    required this.uploadImage,
    required this.profileImageUrl,
  }) : super(key: key);

  @override
  State<ProfileChangePage> createState() => _ProfileChangePageState();
}

class _ProfileChangePageState extends State<ProfileChangePage> {
  File? _imageFile;
  String? _jwtToken;
  String? _profileImageUrl;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _profileImageUrl = widget.profileImageUrl;
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('jwtToken');
    if (_jwtToken != null) {
      final userInfo = await UserInfoService.getUserInfo(_jwtToken!);
      setState(() {
        _profileImageUrl = userInfo['profileImage'] ?? widget.profileImageUrl;
      });
      print('${_profileImageUrl}');
    }
  }

  Future<void> saveAndGoBack() async {
    if (_imageFile != null) {
      // 서버로 이미지 업로드
      await widget.uploadImage(_imageFile!);
      // 서버에서 새로운 프로필 이미지 URL 확인
      final updatedUserInfo = await UserInfoService.getUserInfo(_jwtToken!);
      if (updatedUserInfo != null && updatedUserInfo['profileImage'] != null) {
        setState(() {
          _profileImageUrl = updatedUserInfo['profileImage']; // 업데이트된 URL 사용
        });
      }
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지를 선택해주세요.')),
      );
    }
  }


  Future<String?> fileUploadRequest(File file) async {
    final url = Uri.parse("http://13.125.228.152:4000/file/upload");
    final request = http.MultipartRequest('POST', url);

    // 이미지 파일을 Multipart로 추가
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    // JWT 토큰이 있을 경우 헤더에 추가
    if (_jwtToken != null) {
      request.headers['Authorization'] = 'Bearer $_jwtToken';
    }

    try {
      // 서버에 요청 보내기
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await http.Response.fromStream(response);
        try {
          final jsonResponse = json.decode(responseBody.body);
          return jsonResponse['url'];
        } catch (e) {
          return responseBody.body; // This will be a string (URL)
        }
      } else {
        throw Exception('이미지 업로드 실패');
      }
    } catch (error) {
      print('Error: $error');
      return null;
    }
  }

  Future<void> getImage(ImageSource imageSource) async {
    final XFile? pickedFile = await picker.pickImage(source: imageSource);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String? imageUrl = await fileUploadRequest(imageFile);

      setState(() {
        _imageFile = imageFile;

      });

      if (imageUrl != null) {
        setState(() {
          _profileImageUrl = imageUrl.trim();
        });
        print('${_profileImageUrl}');
      }
    } else {
      print('이미지 선택 안됨.');
    }
  }

  Widget _buildPhotoArea() {
    return Container(
      width: 250 ,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          fit: BoxFit.cover,
          image: _imageFile != null
              ? FileImage(_imageFile!)
              : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
              ? (_profileImageUrl!.startsWith('http')
              ? NetworkImage(_profileImageUrl!)
              : FileImage(File(_profileImageUrl!))) as ImageProvider
              : AssetImage('assets/images/placeholder.png'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프로필 설정'),
        backgroundColor: AppColors.mintgreen,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPhotoArea(),
          SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                style: ButtonStyle(
                    shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          side: BorderSide(
                              color: Colors.black87,
                              width: 0.5
                          ),
                        )
                    )
                ),
                onPressed: () {
                  getImage(ImageSource.gallery);
                },
                child: Text('이미지 선택'),
              ),
              TextButton(
                style: ButtonStyle(
                    shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          side: BorderSide(
                              color: Colors.black87,
                              width: 0.5
                          ),
                        )
                    )
                ),
                onPressed: () {
                  saveAndGoBack();
                },
                child: Text('변경하기'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
