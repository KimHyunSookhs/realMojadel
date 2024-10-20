import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mojadel2/Config/getUserInfo.dart';
import 'package:http/http.dart' as http;
import 'package:mojadel2/RecipePage/DetailRecipePage.dart';
import 'package:mojadel2/RecipePage/RecipeBoardList/RecipeBoardListItem.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyRecipecontents extends StatefulWidget {
  final VoidCallback onRefresh;
  const MyRecipecontents({
    Key? key,
    required this.onRefresh,
  }) : super(key: key);
  @override
  State<MyRecipecontents> createState() => _MyRecipecontentsState();
}

class _MyRecipecontentsState extends State<MyRecipecontents> {
  List<RecipeBoardListItem> _messages = [];
  late StreamController<List<RecipeBoardListItem>> _messageStreamController;
  String? _jwtToken;
  String? userEmail;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _messageStreamController = StreamController<List<RecipeBoardListItem>>();
    _loadUserInfo().then((_) {
      if (_isLoggedIn) {
        _fetchMyBoards();
      } else {
        _messageStreamController.add([]);
      }
    });
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('jwtToken');
    if (_jwtToken != null) {
      final userInfo = await UserInfoService.getUserInfo(_jwtToken!);
      setState(() {
        userEmail = userInfo['email'];
        _isLoggedIn = true;
      });
    } else {
      setState(() {
        _isLoggedIn = false;
      });
    }
  }

  Future<void> _fetchMyBoards() async {
    final String uri =
        'http://13.125.228.152:4000/api/v1/recipe/recipe-board/user-board-list/$userEmail';
    try {
      http.Response response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            json.decode(utf8.decode(response.bodyBytes));
        if (responseData['userBoardList'] != null &&
            responseData['userBoardList'] is List) {
          final List<dynamic> messageList = responseData['userBoardList'];
          List<RecipeBoardListItem> messages = [];
          for (var data in messageList) {
            List<String> boardTitleImageList = [];
            if (data['boardTitleImage'] != null) {
              if (data['boardTitleImage'] is String) {
                boardTitleImageList = [data['boardTitleImage']];
              } else {
                boardTitleImageList =
                    List<String>.from(data['boardTitleImage']);
              }
            }
            if (data['writerProfileImage'] != null) {
              if (data['writerProfileImage'] is String) {
                boardTitleImageList = [data['writerProfileImage']];
              } else {
                boardTitleImageList =
                    List<String>.from(data['writerProfileImage']);
              }
            }
            messages.add(
              RecipeBoardListItem(
                boardNumber: data['boardNumber'],
                title: data['title'],
                content: data['content'],
                boardTitleImage: boardTitleImageList,
                favoriteCount: data['favoriteCount'] ?? 0,
                commentCount: data['commentCount'] ?? 0,
                viewCount: data['viewCount'] ?? 0,
                writeDatetime: data['writeDatetime'] ?? '',
                writerNickname: data['writerNickname'],
                writerProfileImage: data['writerProfileImage']?? '',
                type: data['type'],
                cookingTime: data['cookingTime'],
                step1_content: data['step1_content'] ?? '',
                step2_content: data['step2_content'] ?? '',
                step3_content: data['step3_content'] ?? '',
                step4_content: data['step4_content'] ?? '',
                step5_content: data['step5_content'] ?? '',
                step6_content: data['step6_content'] ?? '',
                step7_content: data['step7_content'] ?? '',
                step8_content: data['step8_content'] ?? '',
                step1_image: data['step1_image'] ?? '',
                step2_image: data['step2_image'] ?? '',
                step3_image: data['step3_image'] ?? '',
                step4_image: data['step4_image'] ?? '',
                step5_image: data['step5_image'] ?? '',
                step6_image: data['step6_image'] ?? '',
                step7_image: data['step7_image'] ?? '',
                step8_image: data['step8_image'] ?? '',
              ),
            );
          }
          _messages = messages.toSet().toList();
          _messageStreamController.add(_messages);
        }
      }
    } catch (error) {
      print('Failed to fetch messages: $error');
    }
  }

  @override
  void dispose() {
    _messageStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RecipeBoardListItem>>(
      stream: _messageStreamController.stream,
      builder: (context, snapshot) {
        if (!_isLoggedIn) {
          return Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Center(child: Text('로그인 후 이용 가능합니다.')),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
      else {
          final messages = snapshot.data!;
          return messages.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Center(child: Text('게시글이 없습니다')),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            message.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSansKR',
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  message.content,
                                  style: TextStyle(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.favorite, size: 20,),
                                  SizedBox(width: 2),
                                  Text(
                                    '${message.favoriteCount}',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.comment, size: 20),
                                  SizedBox(width: 4),
                                  Text(
                                    '${message.commentCount}',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.remove_red_eye, size: 20),
                                  SizedBox(width: 4),
                                  Text(
                                    '${message.viewCount}',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () async {
                            final success = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailRecipePage(
                                  recipeId: message.boardNumber,
                                ),
                              ),
                            );
                            _fetchMyBoards();
                          },
                        ),
                        if (index != messages.length - 1) Divider(),
                      ],
                    );
                  },
                );
        }
      },
    );
  }
}
