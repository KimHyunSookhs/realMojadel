import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mojadel2/colors/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  List<String> _stepImageList = [];
  String? _userEmail;
  String? _jwtToken;
  String? _step1Image;
  String? _step2Image;
  String? _step3Image;
  String? _step4Image;
  String? _step5Image;
  String? _step6Image;
  String? _step7Image;
  String? _step8Image;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  RecipeType? _recipeType = RecipeType.Recipe;
  int? type;
  int? cookingTime;
  List<Map<String, String>> _ingredients = [
    {'name': '', 'amount': ''},
    {'name': '', 'amount': ''},
    {'name': '', 'amount': ''}
  ];

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
  List<Map<String, dynamic>> _steps = List.generate(4, (index) => {
    'text': TextEditingController(),
    'image': null,
  });

  Future<void> _savePost(BuildContext context) async {
    String title = _titleController.text;
    String mainContent = _contentController.text;
    type = _recipeType == RecipeType.Recipe ? 0 : 1;
    String content = '$mainContent\n\n재료:\n';
    List<String> stepContents = [];
    for (var ingredient in _ingredients) {
      if (ingredient['name']!.isNotEmpty && ingredient['amount']!.isNotEmpty) {
        content += '${ingredient['name']} - ${ingredient['amount']}';
      }
    }
      for (int i = 0; i < _steps.length; i++) {
        stepContents.add(_steps[i]['text'].text.trim());
      }
      final String uri = 'http://192.168.219.109:4000/api/v1/recipe/recipe-board';
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_jwtToken',
      };
      Map<String, dynamic> postData = {
        'title': title,
        'content': content,
        'boardImageList': _boardImageList,
        'type': type ?? 0,
        'cookingTime': cookingTime ?? 0,
        'step1_content': stepContents.length > 0 ? stepContents[0] : '',
        'step2_content': stepContents.length > 1 ? stepContents[1] : '',
        'step3_content': stepContents.length > 2 ? stepContents[2] : '',
        'step4_content': stepContents.length > 3 ? stepContents[3] : '',
        'step5_content': stepContents.length > 4 ? stepContents[4] : '',
        'step6_content': stepContents.length > 5 ? stepContents[5] : '',
        'step7_content': stepContents.length > 6 ? stepContents[6] : '',
        'step8_content': stepContents.length > 7 ? stepContents[7] : '',
        'step1_image': _step1Image ?? '',
        'step2_image': _step2Image ?? '',
        'step3_image': _step3Image ?? '',
        'step4_image': _step4Image ?? '',
        'step5_image': _step5Image ?? '',
        'step6_image': _step6Image ?? '',
        'step7_image': _step7Image ?? '',
        'step8_image': _step8Image ?? '',
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
          print(
              'Failed to submit the post. Error code: ${response.statusCode}');
          print('Response body: ${response.body}');
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
          _boardImageList.add(imagePath.trim());
          _image = pickedFile;
        });
      }
    }
    Future<void> getImageForStep(int index) async {
      final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.gallery);
      if (pickedFile != null) {
        String imagePath = await saveImagePermanently(File(pickedFile.path));
        setState(() {
          _steps[index]['image'] = File(pickedFile.path);
          switch (index) {
            case 0:
              _step1Image = imagePath.trim();
              break;
            case 1:
              _step2Image = imagePath.trim();
              break;
            case 2:
              _step3Image = imagePath.trim();
              break;
            case 3:
              _step4Image = imagePath.trim();
              break;
            case 4:
              _step5Image = imagePath.trim();
              break;
            case 5:
              _step6Image = imagePath.trim();
              break;
            case 6:
              _step7Image = imagePath.trim();
              break;
            case 7:
              _step8Image = imagePath.trim();
              break;
          }
        });
      }
    }

    void _addIngredient() {
      setState(() {
        _ingredients.add({'name': '', 'amount': ''});
      });
    }
    void _removeIngredient(int index) {
      setState(() {
        _ingredients.removeAt(index);
      });
    }
    void _addStep() {
      if (_steps.length < 8) {
        setState(() {
          _steps.add({'text': TextEditingController(), 'image': null});
        });
      }
    }

    Widget _buildStepField(int index) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 50,
            alignment: Alignment.center,
            child: Text('${index + 1}', style: TextStyle(fontSize: 20)),
          ),
          Expanded(
            flex: 4,
            child: TextField(
              controller: _steps[index]['text'],
              decoration: InputDecoration(hintText: '요리 순서를 입력하세요'),
              minLines: 1,
              maxLines: 2,
            ),
          ),
          SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              getImageForStep(index);
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _steps[index]['image'] != null
                  ? Image.file(_steps[index]['image'], fit: BoxFit.cover)  // Display the image
                  : Center(
                  child: Icon(Icons.add_a_photo, size: 24, color: Colors.grey)),
            ),
          ),
        ],
      );
    }

    Widget _buildIngredientField(int index) {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: TextField(
              decoration: InputDecoration(hintText: '예)돼지고기'),
              onChanged: (value) {
                setState(() {
                  _ingredients[index]['name'] = value;
                });
              },
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(hintText: '예)300g'),
              onChanged: (value) {
                setState(() {
                  _ingredients[index]['amount'] = value;
                });
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _removeIngredient(index);
            },
          ),
        ],
      );
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
                SizedBox(height: 10),
                Text(
                  "대표 이미지를 추가해주세요",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }
    Widget _buildCategoryAndCookingTimeField() {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
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
                const Text('일반레시피',style:TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
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
                const Text('편의점레시피',style:TextStyle(fontSize: 12)),
              ],
            ),
          ),
          SizedBox(width: 5,),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Flexible(
                  flex: 1,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 5.0, horizontal: 10.0),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        cookingTime = int.tryParse(value);
                      });
                    },
                  ),
                ),
                SizedBox(width: 5),
                Text(
                  '분',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      );
    }

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              backgroundColor: Colors.white24,
              title: Text(
                '레시피 등록',
                style: Theme
                    .of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                  fontFamily: 'Inter',
                  color: Colors.black,
                  fontSize: 25,
                ),
              ),
              actions: [
                TextButton(onPressed: () {
                  _savePost(context);
                }, child: Text('저장'))
              ],
            ),
            body: SafeArea(
              top: true,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10,),
                    Container(
                      color: AppColors.mintgreen,
                      width: double.infinity,
                      child: Text(
                          '  레시피제목',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          )
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(8, 10, 8, 20),
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
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodyMedium,
                        textAlign: TextAlign.start,
                        minLines: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _buildPhotoArea(),
                    ),
                    SizedBox(height: 10,),
                    Container(
                      color: AppColors.mintgreen,
                      width: double.infinity,
                      child: Text(
                          '  레시피설명',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          )
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(8, 12, 8, 0),
                      child: TextField(
                        obscureText: false,
                        controller: _contentController,
                        onChanged: (value) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          labelStyle: Theme
                              .of(context)
                              .textTheme
                              .labelMedium,
                          hintText: '레시피의 간략한 설명을 적어주세요.',
                          hintStyle:
                          Theme
                              .of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
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
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodyMedium,
                        maxLines: 2,
                      ),
                    ),
                    SizedBox(height: 15,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          color: AppColors.mintgreen,
                          width: double.infinity,
                          child: Text(
                              '  카테고리 및 요리 시간',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              )
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: _buildCategoryAndCookingTimeField(),
                        ),
                      ],
                    ),
                    SizedBox(height: 2,),
                    Container(
                      color: AppColors.mintgreen,
                      width: double.infinity,
                      child: Text(
                          '  재료',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          )
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                      child: Column(
                        children: _ingredients
                            .asMap()
                            .entries
                            .map((entry) => _buildIngredientField(entry.key))
                            .toList(),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          child: Icon(Icons.add),
                          onPressed: _addIngredient,
                        ),
                      ],
                    ),
                    SizedBox(height: 2,),
                    Container(
                      color: AppColors.mintgreen,
                      width: double.infinity,
                      child: Text(
                          '  요리순서',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          )
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 5.0),
                      child: Column(
                        children: _steps
                            .asMap()
                            .entries
                            .map((entry) =>
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 5.0),
                              child: _buildStepField(entry.key),
                            ))
                            .toList(),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _addStep,
                          child: Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ));
    }
  }