import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mojadel2/Config/getUserInfo.dart';
import 'package:http/http.dart' as http;
import 'package:mojadel2/yomojomo/YomoJomoBoardList/BoardListItem.dart';
import 'package:mojadel2/yomojomo/detailboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Myboardcontents extends StatefulWidget {
  const Myboardcontents({super.key});

  @override
  State<Myboardcontents> createState() => _MyboardcontentsState();
}

class _MyboardcontentsState extends State<Myboardcontents> {
  List<TradeBoardListItem> _messages = [];
  late StreamController<List<TradeBoardListItem>> _messageStreamController;
  String? _jwtToken;
  String? userEmail;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _messageStreamController = StreamController<List<TradeBoardListItem>>();
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
        'http://192.168.219.109:4000/api/v1/community/board/user-board-list/$userEmail';
    try {
      http.Response response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            json.decode(utf8.decode(response.bodyBytes));
        if (responseData['userBoardList'] != null &&
            responseData['userBoardList'] is List) {
          final List<dynamic> messageList = responseData['userBoardList'];
          List<TradeBoardListItem> messages = [];
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
            messages.add(
              TradeBoardListItem(
                data['boardNumber'],
                data['title'],
                data['content'],
                boardTitleImageList,
                data['favoriteCount'] ?? 0,
                data['commentCount'] ?? 0,
                data['viewCount'] ?? 0,
                data['writeDatetime'] ?? '',
                data['writerNickname'] ?? '',
                data['writerProfileImage'],
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
    return StreamBuilder<List<TradeBoardListItem>>(
      stream: _messageStreamController.stream,
      builder: (context, snapshot) {
        if (!_isLoggedIn) {
          return Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Center(child: Text('로그인 후 이용 가능합니다')),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else {
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSansKR',
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  message.content,
                                  style: TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.favorite),
                                  SizedBox(width: 4),
                                  Text(
                                    '${message.favoriteCount}',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.comment),
                                  SizedBox(width: 4),
                                  Text(
                                    '${message.commentCount}',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.remove_red_eye),
                                  SizedBox(width: 4),
                                  Text(
                                    '${message.viewCount}',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () async {
                            final success = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailBoard(
                                  postId: message.boardNumber,
                                  initialCommentCount: message.commentCount,
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
