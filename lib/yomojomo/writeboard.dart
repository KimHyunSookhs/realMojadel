import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mojadel2/colors/colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

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
    _loadUserEmail(); // 사용자 이메일 불러오기
    _loadToken();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userEmail = prefs.getString('userEmail');
    });
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _jwtToken = prefs.getString('jwtToken');
    });
  }

  Future<void> _savePost(BuildContext context) async {
    String title = _titleController.text;
    String content = _contentController.text;
    final String uri = 'http://10.0.2.2:4000/api/v1/board';

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
        print('The post has been successfully submitted.');
        Navigator.of(context).pop(true);
      } else {
        print('Failed to submit the post. Error code: ${response.statusCode}');
      }
    } catch (error) {
      print('An error occurred while submitting the post: $error');
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('jwtToken');

    if (jwtToken != null) {
      try {
        Map<String, String> headers = {
          'Authorization': 'Bearer $jwtToken',
        };
        Uri url = Uri.parse('http://10.0.2.2:4000/api/v1/board');
        var request = http.MultipartRequest('POST', url)
          ..headers.addAll(headers)
          ..files.add(await http.MultipartFile.fromPath(
            'image',
            imageFile.path,
            contentType:
                MediaType('image', 'jpeg'), // Update with the actual type
          ));
        request.headers['Content-Type'] = 'multipart/form-data;charset=UTF-8';
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final imageUrl = jsonDecode(response.body)['imageUrl'];
          return imageUrl;
        } else {
          print('이미지 업로드 실패. 오류 코드: ${response.statusCode}');
          print('응답 내용: ${response.body}');
          return null;
        }
      } catch (e) {
        print('이미지 업로드 중 오류 발생: $e');
        return null;
      }
    }
  }

  Future<void> getImage(ImageSource imageSource) async {
    final XFile? pickedFile = await picker.pickImage(source: imageSource);
    if (pickedFile != null) {
      // Save the image file path permanently and add it to the boardImageList
      String imagePath = await _saveImagePermanently(File(pickedFile.path));
      setState(() {
        _boardImageList.add(imagePath);
      });
    }
  }

  Future<String> _saveImagePermanently(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final String path = directory.path;
    final String fileName = basename(imageFile.path);
    final File permanentFile = await imageFile.copy('$path/$fileName');
    return '$path/$fileName'; // Return the file path
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
