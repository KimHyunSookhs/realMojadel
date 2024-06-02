import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mojadel2/colors/colors.dart';
import 'package:mojadel2/registar/mapcreate.dart';

class RegistarPage extends StatefulWidget {
  final String selectedPlaceName;
  final TextEditingController textController;
  final TextEditingController textController2;
  final TextEditingController priceController;
  final XFile image;
  final String selectedOption;
  const RegistarPage({Key? key,
    required this.selectedPlaceName,
    required this.textController,
    required this.textController2,
    required this.priceController,
    required this.image,
    required this.selectedOption,})
      : super(key: key);
  @override
  State<RegistarPage> createState() => _RegistarPageState();
}

class _RegistarPageState extends State<RegistarPage> {
  XFile? _image;
  ImagePicker picker = ImagePicker();
  String? _selectedOption = '중고거래';
  String _selectedPlaceName = '';
  Future getImage(ImageSource imageSource) async {
    // 갤러리에서 이미지를 선택합니다.
    final XFile? pickedFile = await picker.pickImage(source: imageSource);
    if (pickedFile != null) {
      setState(() {
        _image = XFile(pickedFile.path);
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
            width: 10,
            height: 10,
            color: Colors.white38,
          );
  }
  TextEditingController textController = TextEditingController();
  TextEditingController textController2 = TextEditingController();
  TextEditingController priceController = TextEditingController();
  String textContet = "";

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        child: Scaffold(
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
                  controller: textController,
                  onChanged: (value) {
                    setState(() => textContet = textController.text);
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
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional(-1, -1),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(50, 10, 0, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            for (var option in ['중고거래', '운동모임', '배달음식'])
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Radio<String>(
                                    value: option,
                                    groupValue: _selectedOption,
                                    onChanged: (String? value) {
                                      setState(() {
                                        _selectedOption = value;
                                      });
                                    },
                                  ),
                                  Text(option),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(10, 0, 10, 0),
                child: TextField(
                  autofocus: false,
                  obscureText: false,
                  keyboardType: TextInputType.number,
                  controller: priceController,
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
                  controller: textController2,
                  onChanged: (value) {
                    setState(() => textContet = textController2.text);
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
                child: Text('거래 희망 장소',
                    style:
                        TextStyle(fontWeight: FontWeight.w300, fontSize: 16)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                child: FloatingActionButton(
                  onPressed: () async {
                    final selectedPlaceName = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(builder: (context) => MapCreate()),
                    );
                    // Navigator.pop()에서 전달받은 장소명을 설정합니다.
                    if (selectedPlaceName != null) {
                      setState(() {
                        _selectedPlaceName = selectedPlaceName;
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
                  controller: TextEditingController(text: _selectedPlaceName),
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
                        onPressed: () {},
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
