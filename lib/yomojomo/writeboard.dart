import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mojadel2/colors/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final String uri = 'http://13.125.228.152:4000/api/v1/community/board';

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_jwtToken',
    };
    Map<String, dynamic> postData = {
      'title': title,
      'content': content,
      'boardImageList': _boardImageList,
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
      print('Error: $error');
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
          return responseBody.body;
        }
      } else {
        throw Exception('이미지 업로드 실패');
      }
    } catch (error) {
      return null;
    }
  }

  // 이미지 선택 후 업로드 처리
  Future<void> getImage(ImageSource imageSource) async {
    final XFile? pickedFile = await picker.pickImage(source: imageSource);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      // 이미지를 서버로 업로드하고 URL 받기
      String? imageUrl = await fileUploadRequest(imageFile);

      if (imageUrl != null) {
        setState(() {
          _boardImageList.add(imageUrl);  // URL을 리스트에 추가
        });
      }
    } else {
      print('이미지 선택 안됨.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                  minimumSize: Size(50, 50),
                  side: BorderSide(color: Colors.black, width: 1.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _boardImageList
                    .map((imageUrl) => Image.network(
                  imageUrl,
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover, // Optional: adjust how the image fits
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
