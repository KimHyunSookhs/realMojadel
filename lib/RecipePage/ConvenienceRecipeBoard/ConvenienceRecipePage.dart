import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mojadel2/RecipePage/RecipeBoardList/RecipeBoardListItem.dart';
import 'package:mojadel2/RecipePage/RecipeRegistar.dart';
import 'package:mojadel2/colors/colors.dart';

class ConvenienceRecipePage extends StatefulWidget {
  const ConvenienceRecipePage({super.key});

  @override
  State<ConvenienceRecipePage> createState() => _ConvenienceRecipePageState();
}

class _ConvenienceRecipePageState extends State<ConvenienceRecipePage> {
  List<RecipeBoardItem> _messages = [];
  late StreamController<List<RecipeBoardItem>> _messageStreamController;
  bool _isMounted = false;
  String? _jwtToken;
  int type = 0 | 1;
  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _messageStreamController = StreamController<List<RecipeBoardItem>>();
    fetchRecipeBoard();
  }

  @override
  void dispose() {
    _isMounted = false;
    _messageStreamController.close();
    super.dispose();
  }

  String formatDatetime(String datetime) {
    if (datetime != null && datetime.isNotEmpty) { // Add null check here
      DateTime parsedDatetime = DateTime.parse(datetime).toUtc();
      return DateFormat('MM/dd').format(parsedDatetime);
    } else {
      return ''; // Return empty string if datetime is null or empty
    }
  }

  Future<void> fetchRecipeBoard() async {
    final String uri = 'http://10.0.2.2:4000/api/v1/recipe/recipe-board/latest-list/1';
    try {
      http.Response response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        if (_isMounted && responseData['recipelatestList'] != null) {
          print('${responseData}');
          if (responseData['recipelatestList'] is List) {
            final List<dynamic> messageList = responseData['recipelatestList'];
            List<RecipeBoardItem> messages = [];
            for (var data in messageList) {
              List<String> boardTitleImageList = [];
              List<String> writerProfileImage = [];
              if (data['boardTitleImage'] != null) {
                if (data['boardTitleImage'] is String) {
                  boardTitleImageList = [data['boardTitleImage']];
                } else {
                  boardTitleImageList = List<String>.from(data['boardTitleImage']);
                }
              }
              if (data['writerProfileImage'] != null) {
                if (data['writerProfileImage'] is String) {
                  writerProfileImage = [data['writerProfileImage']];
                } else {
                  writerProfileImage = List<String>.from(data['writerProfileImage']);
                }
              }
              messages.add(
                RecipeBoardItem(
                    data['boardNumber'],
                    data['title'],
                    data['content'],
                    boardTitleImageList,
                    data['favoriteCount'] ?? 0,
                    data['commentCount'] ?? 0,
                    data['viewCount'] ?? 0,
                    data['writeDatetime'] ?? '',
                    data['writerNickname'],
                    writerProfileImage
                ),
              );
            }
            if (_isMounted) {
              setState(() {
                _messages = messages;
                _messageStreamController.add(messages); // 스트림에 데이터 푸시
              });
            }
          } else {
            print('latestList is not a list');
          }
        } else {
          print('recipelatestList is null');
        }
      } else {
        print('Failed to fetch messages: ${response.statusCode}');
      }
    } catch (error) {
      if (_isMounted) {
        print('Failed to fetch messages: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        title: Text('편의점레시피'),
        backgroundColor: AppColors.mintgreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: StreamBuilder<List<RecipeBoardItem>>(
          stream: _messageStreamController.stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _messages.isEmpty) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('게시글이 없습니다.'));
            } else {
              final messages = snapshot.data ?? [];
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return GestureDetector(
                    onTap: () async {
                      // Handle item tap, e.g., navigate to detail page
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 0.5),
                            image: DecorationImage(
                              image: FileImage(File(message.boardTitleImage[0])),
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          message.title,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.mintgreen,
        shape: CircleBorder(side: BorderSide(color: AppColors.mintgreen)),
        child: Icon(Icons.add),
        onPressed: () async {
          final success = await Navigator.push(
            context, MaterialPageRoute(builder: (context) => RecipeRegistar()),);
          if (success != null && success) {
            fetchRecipeBoard();
            setState(() {});
          }
        },
      ),
    );
  }
}