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
import 'mapcreate.dart';
import 'package:mojadel2/Config/ImagePathProvider.dart';

class RegistarPage extends StatefulWidget {
  @override
  State<RegistarPage> createState() => _RegistarPageState();
}

class _RegistarPageState extends State<RegistarPage> {
  XFile? _image;
  ImagePicker picker = ImagePicker();
  List<String> _boardImageList = [];
  String _selectedPlaceName = '';
  String? _userEmail; // 로그인한 사용자의 이메일
  String? _jwtToken;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

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
    String tradeLocation = _locationController.text;
    String price = _priceController.text;
    final String uri = 'http://10.0.2.2:4000/api/v1/trade/trade-board';

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_jwtToken',
    };
    Map<String, dynamic> postData = {
      'title': title,
      'content': content,
      'boardImageList': _boardImageList,
      'tradeLocation' : tradeLocation,
      'price' : price,
    };
    String requestBody = json.encode(postData);
    try {
      http.Response response = await http.post(
        Uri.parse(uri),
        headers: headers,
        body: requestBody,
      );
      if (response.statusCode == 200) {
        print('The tradepost has been successfully submitted.');
        Navigator.of(context).pop(true);
      } else {
        print('Failed to submit the post. Error code: ${response.statusCode}');
      }
    } catch (error) {
      print('An error occurred while submitting the post: $error');
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
    return _image != null
        ? Container(
      width: 140,
      height: 120,
      child: Image.file(File(_image!.path)),
    )
        : Container(
      width: 140,
      height: 120,
      color: Colors.white38,
      child: Icon(Icons.photo, size: 50, color: Colors.grey), // Placeholder icon
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
              '제품 등록',
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
                      '제목',
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                        hintText: '제목을 입력하세요',
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
                  Align(
                    alignment: AlignmentDirectional(0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        FloatingActionButton(
                          heroTag: 'gallery_button',
                          onPressed: () {
                            getImage(ImageSource.gallery);
                          },
                          child: Icon(Icons.photo),
                        ),
                        SizedBox(
                          height: 10,
                          width: 10,
                        ),
                        _buildPhotoArea(),
                      ],
                    ),
                  ),
                  SizedBox(height: 20,),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(10, 0, 10, 0),
                    child: TextField(
                      autofocus: false,
                      obscureText: false,
                      controller: _priceController,
                      onChanged: (value) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        labelStyle: Theme.of(context).textTheme.labelMedium,
                        hintText: '가격을 입력해주세요',
                        hintStyle: Theme.of(context).textTheme.labelMedium,
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
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(10, 20, 0, 0),
                    child: Text(
                      '제품 설명',
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
                        hintText: '제품의 상세한 설명을 적어주세요.',
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
                      maxLines: 6,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(10, 10, 0, 0),
                    child: Text('거래 희망 장소', style: TextStyle(fontWeight: FontWeight.w300, fontSize: 16)),),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                    child: FloatingActionButton(
                      heroTag: 'map_button',
                      onPressed: () async {
                        final selectedPlaceName = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(builder: (context) => MapCreate()),
                        );
                        // Navigator.pop()에서 전달받은 장소명을 설정합니다.
                        if (selectedPlaceName != null) {
                          setState(() {
                            _selectedPlaceName = selectedPlaceName;
                            _locationController.text = _selectedPlaceName;
                          });
                        }
                      },
                      tooltip: '위치지정',
                      child: Icon(Icons.location_searching),
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 3, 10, 0),
                    child: TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelStyle: Theme.of(context).textTheme.labelMedium,
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