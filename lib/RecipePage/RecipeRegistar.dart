import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mojadel2/colors/colors.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

import '../Config/ImagePathProvider.dart';

class RecipeRegistar extends StatefulWidget {
  @override
  State<RecipeRegistar> createState() => _RecipeRegistar();
}

enum RecipeType  {Recipe, ConvRecipe}

class _RecipeRegistar extends State<RecipeRegistar> {
  XFile? _image;
  ImagePicker picker = ImagePicker();
  List<String> _boardImageList = [];
  String? _userEmail; // 로그인한 사용자의 이메일
  String? _jwtToken;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  RecipeType? _recipeType = RecipeType.Recipe;
  int? type;
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
    type = _recipeType == RecipeType.Recipe ? 0 : 1 ;
    final String uri = 'http://10.0.2.2:4000/api/v1/recipe/recipe-board';

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_jwtToken',
    };
    Map<String, dynamic> postData = {
      'title': title,
      'content': content,
      'boardImageList': _boardImageList,
      'type' : type,
    };
    String requestBody = json.encode(postData);
    try {
      http.Response response = await http.post(
        Uri.parse(uri),
        headers: headers,
        body: requestBody,
      );
      if (response.statusCode == 200) {
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
        Uri url = Uri.parse('http://10.0.2.2:4000/api/v1/recipe');
        var request = http.MultipartRequest('POST', url)
          ..headers.addAll(headers)
          ..files.add(await http.MultipartFile.fromPath(
            'image', imageFile.path,
            contentType:MediaType('image', 'jpeg'), // Update with the actual type
          ));
        request.headers['Content-Type'] = 'multipart/form-data;charset=UTF-8';
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 200) {
          final imageUrl = jsonDecode(response.body)['imageUrl'];
          return imageUrl;
        } else {
          print('이미지 업로드 실패. 오류 코드: ${response.statusCode}');
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
      String imagePath = await saveImagePermanently(File(pickedFile.path));
      setState(() {
        _boardImageList.add(imagePath);
        _image = pickedFile;
      });
    }
  }

  Widget _buildPhotoArea() {
    return GestureDetector(
      onTap: () {
        getImage(ImageSource.gallery);
      },
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _image != null
            ? Image.file(File(_image!.path), fit: BoxFit.fill)
            : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo, size: 50, color: Colors.grey),
              SizedBox(height: 10), // 간격을 추가
              Text(
                "대표 이미지를 추가해주세요",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ), // Placeholder icon과 텍스트 추가
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        child: Scaffold(
          resizeToAvoidBottomInset:true,
          appBar: AppBar(
            backgroundColor: AppColors.mintgreen,
            title: Text(
              '레시피 등록',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontFamily: 'Inter',
                color: Colors.black,
                fontSize: 25,
              ),
            ),
          ),
          body: SafeArea(
            top: true,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(10, 20, 0, 0),
                    child: Text(
                      '레시피 제목',
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(8, 5, 8, 20),
                    child: TextField(
                      controller: _titleController,
                      onChanged: (value) {
                        setState(() {});
                      },
                      autofocus: false,
                      obscureText: false,
                      decoration: InputDecoration(
                        hintText: '예) 제육볶음 만들기',
                        hintStyle: TextStyle(color: Colors.grey),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.black,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.black,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.start,
                      minLines: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: _buildPhotoArea(),
                  ),
                  SizedBox(height: 5,),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(10, 10, 0, 0),
                    child: Text(
                      '레시피 설명',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
                    child: TextField(
                      autofocus: false,
                      obscureText: false,
                      controller: _contentController,
                      onChanged: (value) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        labelStyle: Theme.of(context).textTheme.labelMedium,
                        hintText: '레시피의 간략한 설명을 적어주세요.',
                        hintStyle:
                        Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontFamily: 'Readex Pro',
                          color: Colors.grey,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 3,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // 좌측 정렬
                      children: <Widget>[
                        Text('카테고리', style: Theme.of(context).textTheme.bodyMedium,),
                        Row(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Radio<RecipeType>(
                                  value: RecipeType.Recipe,
                                  groupValue: _recipeType,
                                  onChanged: (RecipeType? value) {
                                    setState(() {
                                      _recipeType = value;
                                    });
                                  },
                                ),
                                const Text('일반레시피'),
                              ],
                            ),
                            Row(
                              children: [
                                Radio<RecipeType>(
                                  value: RecipeType.ConvRecipe,
                                  groupValue: _recipeType,
                                  onChanged: (RecipeType? value) {
                                    setState(() {
                                      _recipeType = value;
                                    });
                                  },
                                ),
                                const Text('편의점레시피'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10,5,10,0),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          _savePost(context);
                        },
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(AppColors.mintgreen),
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
                        child: Text(
                          '등록하기',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
  }
}