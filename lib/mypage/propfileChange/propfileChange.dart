import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mojadel2/Config/ImagePathProvider.dart';
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
  final ImagePicker _picker = ImagePicker();

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
    }
  }

  Future<void> saveAndGoBack() async {
    if (_imageFile != null) {
      await widget.uploadImage(_imageFile!);
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지를 선택해주세요.')),
      );
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
    final XFile? pickedFile = await _picker.pickImage(source: imageSource);
    if (pickedFile != null) {
      String imagePath = await saveImagePermanently(File(pickedFile.path));
      setState(() {
        _imageFile = File(imagePath);
        _profileImageUrl = imagePath;
      });
      _uploadImage(File(imagePath));
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
