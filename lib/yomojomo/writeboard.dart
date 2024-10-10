import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mojadel2/colors/colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import '../Config/ImagePathProvider.dart';

class WriteBoard extends StatefulWidget {
  @override
  State<WriteBoard> createState() => _WriteBoardState();
}

class _WriteBoardState extends State<WriteBoard> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _userEmail; // 로그인한 사용자의 이메일
  String? _jwtToken;
  final picker = ImagePicker();
  List<String> _boardImageList = [];

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('userEmail');
      _jwtToken = prefs.getString('jwtToken');
    });
  }

  Future<void> _savePost(BuildContext context) async {
    String title = _titleController.text;
    String content = _contentController.text;
    final String uri = 'http://52.79.217.191:4000/api/v1/community/board';

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_jwtToken',
    };
    Map<String, dynamic> postData = {
      'title': title,
      'content': content,
      'boardImageList': _boardImageList, // Use the updated boardImageList
    };
    String requestBody = json.encode(postData);
    try {
      http.Response response = await http.post(
        Uri.parse(uri),
        headers: headers,
        body: requestBody,
      );
      if (response.statusCode == 200) {
        if (context.mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (error) {
    }
  }
  Future<void> getImage(ImageSource imageSource) async {
    final XFile? pickedFile = await picker.pickImage(source: imageSource);
    if (pickedFile != null) {
      setState(() {
        _boardImageList.add(pickedFile.path); // Just add the local path to the list
      });
    } else {
      print('No image selected.');
    }
  }

  // Future<void> getImage(ImageSource imageSource) async {
  //   final XFile? pickedFile = await picker.pickImage(source: imageSource);
  //   if (pickedFile != null) {
  //     String imagePath = await saveImagePermanently(File(pickedFile.path));
  //     setState(() {
  //       _boardImageList.add(imagePath);
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:true,
      appBar: AppBar(
        title: Text('게시글 작성'),
        backgroundColor: AppColors.mintgreen,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 3,
                  ),
                  Text(
                    '제목',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: '제목을 입력해주세요',
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 1)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 1),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 3,
                  ),
                  Text(
                    '내용',
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                    hintText: '내용을 입력해주세요',
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 1)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 1),
                    )),
                maxLines: 6,
              ),
              SizedBox(height: 24),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(50, 50), // 버튼 크기 설정
                  side: BorderSide(color: Colors.black, width: 1.0), // 외곽선 설정
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // 둥근 모서리 설정
                  ),
                ),
                onPressed: () {
                  getImage(ImageSource.gallery);
                },
                child: Icon(Icons.camera_alt, color: Colors.black),
              ),
              SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          // insetPadding: const EdgeInsets.fromLTRB(80, 80, 80, 80),
                          content: const SingleChildScrollView(
                            child: ListBody(
                              children: <Widget>[
                                Text(
                                  '게시글을 올리시겠습니까?',
                                  style: TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  _savePost(context);
                                  Navigator.pop(context, true);
                                },
                                child: Text(
                                  '완료',
                                  style: TextStyle(color: Colors.black),
                                )),
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('취소',
                                    style: TextStyle(color: Colors.black)))
                          ],
                        );
                      });
                },
                child: Text(
                  '등록',
                  style: TextStyle(color: Colors.black),
                ),
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.greenAccent)),
              ),
              SizedBox(height: 24),
              // Display selected images
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _boardImageList
                    .map((imagePath) => Image.file(
                          File(imagePath),
                          width: 150,
                          height: 150,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
