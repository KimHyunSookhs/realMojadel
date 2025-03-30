import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mojadel2/colors/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditRecipePage extends StatefulWidget {
  final int recipeId;
  final String initialTitle;
  final String initialContent;
  final int initialType;
  final int initialCookingTime;
  final List<String>? boardImageList;
  final String step1_content;
  final String step2_content;
  final String step3_content;
  final String step4_content;
  final String step5_content;
  final String step6_content;
  final String  step7_content;
  final String step8_content;
  final String step1_image;
  final String step2_image;
  final String step3_image;
  final String step4_image;
  final String step5_image;
  final String step6_image;
  final String step7_image;
  final String step8_image;

  const EditRecipePage({
    Key? key,
    required this.recipeId,
    required this.initialTitle,
    required this.initialContent,
    required this.boardImageList,
    required this.initialType,
    required this.initialCookingTime,
    required this.step1_content,
    required this.step1_image,
    required this.step2_content,
    required this.step2_image,
    required this.step3_content,
    required this.step3_image,
    required this.step4_content,
    required this.step4_image,
    required this.step5_content,
    required this.step5_image,
    required this.step6_content,
    required this.step6_image,
    required this.step7_content,
    required this.step7_image,
    required this.step8_content,
    required this.step8_image,
  }) : super(key: key);

  @override
  _EditRecipePageState createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _cookingTimeController;
  late List<String> _boardImageList;
  String? _jwtToken;
  final ImagePicker picker = ImagePicker();
  List<Map<String, dynamic>> _steps = [];
  RecipeType? _recipeType;
  void _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _jwtToken = prefs.getString('jwtToken');
    });
  }
  @override
  void initState() {
    super.initState();
    _getToken();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    _cookingTimeController = TextEditingController(text: widget.initialCookingTime.toString());
    if (widget.boardImageList != null) {
      _boardImageList = List.from(widget.boardImageList!);
    }
    _recipeType = widget.initialType == 0 ? RecipeType.Recipe : RecipeType.ConvRecipe;
    _steps = List.generate(8, (index) {
      return {
        'text': TextEditingController(text: _getStepContent(index)),
        'image': _getStepImagePath(index),
      };
    });
  }

  String _getStepContent(int index) {
    switch (index) {
      case 0:
        return widget.step1_content;
      case 1:
        return widget.step2_content;
      case 2:
        return widget.step3_content;
      case 3:
        return widget.step4_content;
      case 4:
        return widget.step5_content;
      case 5:
        return widget.step6_content;
      case 6:
        return widget.step7_content;
      case 7:
        return widget.step8_content;
      default:
        return '';
    }
  }

  String _getStepImagePath(int index) {
    switch (index) {
      case 0:
        return widget.step1_image;
      case 1:
        return widget.step2_image;
      case 2:
        return widget.step3_image;
      case 3:
        return widget.step4_image;
      case 4:
        return widget.step5_image;
      case 5:
        return widget.step6_image;
      case 6:
        return widget.step7_image;
      case 7:
        return widget.step8_image;
      default:
        return '';
    }
  }

  Future<void> _updateRecipe(BuildContext context) async {
    String title = _titleController.text;
    String content = _contentController.text;
    int type = _recipeType == RecipeType.Recipe ? 0 : 1;
    List<String> stepContents = [];
    List<String> stepImages = [];

    for (var step in _steps) {
      stepContents.add(step['text'].text.trim());
      stepImages.add(step['image'] ?? '');
    }
    final String uri = 'http://43.203.230.194:4000/api/v1/recipe/recipe-board/${widget.recipeId}';

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_jwtToken',
    };
    Map<String, dynamic> postData = {
      'title': title,
      'content': content,
      'boardImageList': _boardImageList,
      'type': type,
      'cookingTime': int.tryParse(_cookingTimeController.text) ?? widget.initialCookingTime,
      'step1_content': stepContents.length > 0 ? stepContents[0] : '',
      'step2_content': stepContents.length > 1 ? stepContents[1] : '',
      'step3_content': stepContents.length > 2 ? stepContents[2] : '',
      'step4_content': stepContents.length > 3 ? stepContents[3] : '',
      'step5_content': stepContents.length > 4 ? stepContents[4] : '',
      'step6_content': stepContents.length > 5 ? stepContents[5] : '',
      'step7_content': stepContents.length > 6 ? stepContents[6] : '',
      'step8_content': stepContents.length > 7 ? stepContents[7] : '',
      'step1_image': stepImages.length > 0 ? stepImages[0] : '',
      'step2_image': stepImages.length > 1 ? stepImages[1] : '',
      'step3_image': stepImages.length > 2 ? stepImages[2] : '',
      'step4_image': stepImages.length > 3 ? stepImages[3] : '',
      'step5_image': stepImages.length > 4 ? stepImages[4] : '',
      'step6_image': stepImages.length > 5 ? stepImages[5] : '',
      'step7_image': stepImages.length > 6 ? stepImages[6] : '',
      'step8_image': stepImages.length > 7 ? stepImages[7] : '',
    };
    try {
      http.Response response = await http.patch(
        Uri.parse(uri),
        headers: headers,
        body: json.encode(postData),
      );
      if (response.statusCode == 200) {
        Navigator.of(context).pop(true);
        Navigator.of(context).pop(true);
        print('${postData}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('레시피 수정에 실패했습니다.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서버와의 통신에 실패했습니다.')),
      );
    }
  }

  Future<String?> fileUploadRequest(File file) async {
    final url = Uri.parse("http://43.203.230.194:4000/file/upload");
    final request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    if (_jwtToken != null) {
      request.headers['Authorization'] = 'Bearer $_jwtToken';
    }

    try {
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
        child: _boardImageList[0] != null && _boardImageList[0]!.isNotEmpty
            ? Container(
          width: double.infinity,
          height: double.infinity,
          child: _boardImageList[0]!.startsWith('http')  // 마지막 이미지
              ? Image.network(
            _boardImageList[0]!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: Icon(Icons.error, color: Colors.red),
              );
            },
          )
              : Image.file(
            File(_boardImageList[0]!),  // 로컬 파일일 경우
            fit: BoxFit.cover,
          ),
        )
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

  Future<void> getImage(ImageSource imageSource) async {
    final XFile? pickedFile = await picker.pickImage(source: imageSource);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      // 이미지를 서버로 업로드하고 URL 받기
      String? imageUrl = await fileUploadRequest(imageFile);
      if (imageUrl != null) {
        setState(() {
          _boardImageList[0]=(imageUrl);  // URL을 리스트에 추가
        });
      }
    } else {
      print('이미지 선택 안됨.');
    }
  }
  Future<void> getImageForStep(int index) async {
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String? imageUrl = await fileUploadRequest(imageFile);

      if (imageUrl != null) {
        setState(() {
          _steps[index]['image'] = imageUrl;  // Update the URL for the specific step
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 업로드에 실패했습니다.')),
        );
      }
    }
  }

  Widget _buildStepField(int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 50,
          alignment: Alignment.center,
          child: Text('${index + 1}', style: TextStyle(fontSize: 16)),
        ),
        Expanded(
          flex: 3,
          child: TextField(
            controller: _steps[index]['text'],
            decoration: InputDecoration(hintText: '요리 순서를 입력하세요'),
            minLines: 1,
            maxLines: 2,
            style: TextStyle(fontSize: 13),
          ),
        ),
        SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            getImageForStep(index); // Correctly call the image selector for each step
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _steps[index]['image'] != null && _steps[index]['image'].isNotEmpty
                ? Image.network(_steps[index]['image'], fit: BoxFit.cover) // Load image from URL
                : Center(child: Icon(Icons.add_a_photo, size: 24, color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('레시피 수정'),
        backgroundColor: AppColors.mintgreen,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              _updateRecipe(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildPhotoArea(),
            SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: '레시피 제목'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(labelText: '레시피 설명'),
              minLines: 3,
              maxLines: 5,
            ),
            TextField(
              controller: _cookingTimeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '조리 시간 (분)'),
            ),
            SizedBox(height: 16),
            Text('요리 단계', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300)),
            SizedBox(height: 8),
            ...List.generate(8, (index) => _buildStepField(index)),
          ],
        ),
      ),
    );
  }
}

enum RecipeType { Recipe, ConvRecipe }
