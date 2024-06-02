import 'package:flutter/material.dart';
import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http; // For HTTP requests
import 'package:image_picker/image_picker.dart'; // For picking images
import 'dart:io'; // For File
import 'package:shared_preferences/shared_preferences.dart';

import '../../colors/colors.dart';

class EditPost extends StatefulWidget {
  final int postId;
  final String initialTitle;
  final String initialContent;
  final List<String>? boardImageList;

  const EditPost({
    Key? key,
    required this.postId,
    required this.initialTitle,
    required this.initialContent,
    required this.boardImageList,
  }) : super(key: key);

  @override
  _EditPostState createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  List<String>? _boardImageList;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    if (widget.boardImageList != null) {
      _boardImageList = List.from(widget.boardImageList!); // Initialize if not null
    }
  }

  Future<void> _patchPost() async {
    final String uri = 'http://10.0.2.2:4000/api/v1/board/${widget.postId}';
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      final response = await http.patch(
        Uri.parse(uri),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': _titleController.text,
          'content': _contentController.text,
          'boardImageList': _boardImageList, // Include the image URL
        }),
      );
      if (response.statusCode == 200) {
        Navigator.pop(context, true); // Return true to indicate success
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update post')),
        );
        print('${response.statusCode}');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _boardImageList?.add(pickedFile.path); // Add the selected image to the list
      });
    }
  }

  void _removeImage(String imagePath) {
    setState(() {
      _boardImageList?.remove(imagePath); // Remove the selected image from the list
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시글 수정'),
        backgroundColor: AppColors.mintgreen,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '제목',
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 1)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 1),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: '내용',
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.black,
                          width: 1
                      )
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.black,
                        width: 1
                    ),
                  ),
                ),
                maxLines: 8,
              ),
              SizedBox(height: 10),
              _buildImageSection(),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _patchPost,
                child: Text('수정',),
                style:ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.greenAccent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '이미지',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        if (_boardImageList != null && _boardImageList!.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _boardImageList!.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Image.file(
                    File(_boardImageList![index]),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () => _removeImage(_boardImageList![index]),
                      child: Icon(
                        Icons.remove_circle,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _pickImage,
          child: Text('이미지 추가'),
          style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(AppColors.mintgreen)),
        ),
      ],
    );
  }
}
