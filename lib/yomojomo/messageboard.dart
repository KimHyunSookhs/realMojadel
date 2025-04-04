import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mojadel2/colors/colors.dart';
import 'package:mojadel2/yomojomo/detailboard.dart';
import 'package:mojadel2/yomojomo/writeboard.dart';
import 'package:http/http.dart' as http;

import 'YomoJomoBoardList/BoardListItem.dart';

class MessageBoard extends StatefulWidget {
  const MessageBoard({Key? key}) : super(key: key);
  @override
  State<MessageBoard> createState() => _MessageBoardState();
}

class _MessageBoardState extends State<MessageBoard> {
  List<TradeBoardListItem> _messages = [];
  late StreamController<List<TradeBoardListItem>> _messageStreamController;
  bool _isMounted = false;
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  String? _jwtToken;
  @override
  void initState() {
    super.initState();
    _messageStreamController = StreamController<List<TradeBoardListItem>>();
    _fetchMessages(); // Fetch messages when the widget initializes
  }

  Future<void> _fetchMessages() async {
    final String uri = 'http://10.0.2.2:4000/api/v1/community/board/latest-list';
    try {
      http.Response response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        if (_isMounted && responseData['latestList'] != null) {
          if (responseData['latestList'] is List) {
            final List<dynamic> messageList = responseData['latestList'];
            List<TradeBoardListItem> messages = [];
            for (var data in messageList) {
              List<String> boardTitleImageList = [];
              if (data['boardTitleImage'] != null) {
              if (data['boardTitleImage'] is String) {
              boardTitleImageList = [data['boardTitleImage']];
              } else if (data['boardTitleImage'] is List) {
              boardTitleImageList = List<String>.from(data['boardTitleImage']);
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
                  data['writerProfileImage'] ?? '',
                ),
              );
            }
            if (_isMounted) {
              _messages = messages;
              _messageStreamController.add(messages); // 스트림에 데이터 푸시
            }
          } else {
            print('latestList is not a list');
          }
        } else {
          print('No messages found');
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

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _fetchMessages();
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isMounted) {
      _isMounted = true;
    }
  }

  @override
  void dispose() {
    _messageStreamController.close(); // StreamController 닫기
    _isMounted = false;
    super.dispose();
  }

  Future<void> _performSearch(String searchWord) async {
    final String uri = 'http://10.0.2.2:4000/api/v1/community/board/search-list/$searchWord';
    try {
      http.Response response = await http.get(Uri.parse(uri), headers: {
        'Authorization': 'Bearer $_jwtToken', // 인증 헤더 추가
      });
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        if (responseData['searchList'] != null) {
          final List<dynamic> searchList = responseData['searchList'];
          List<TradeBoardListItem> searchResults = [];
          for (var data in searchList) {
            List<String> boardTitleImageList = [];
            if (data['boardTitleImage'] != null) {
              if (data['boardTitleImage'] is String) {
                boardTitleImageList = [data['boardTitleImage']];
              } else {
                boardTitleImageList = List<String>.from(data['boardTitleImage']);
              }
            }
            searchResults.add(
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
                data['writerProfileImage']?? '',
              ),
            );
          }
          setState(() {
            _messages = searchResults;
          });
          _messageStreamController.add(searchResults); // 스트림에 데이터 푸시
        }
      } else {
        print('Failed to perform search: ${response.statusCode}');
      }
    } catch (error) {
      print('Failed to perform search: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '검색어를 입력하세요...',
              border: InputBorder.none,
            ),
            onSubmitted: (value) {
              _performSearch(value);
            },
          )
              : Text('요모조모'),
          backgroundColor: AppColors.mintgreen,
          actions: _isSearching
              ? [
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: _stopSearch,
            ),
          ]
              : [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: _startSearch,
            ),
          ],
        ),
        body: StreamBuilder<List<TradeBoardListItem>>(
          stream: _messageStreamController.stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final messages = snapshot.data ?? [];
              return messages.isEmpty
                  ? Center(child: Text('게시글이 없습니다.'))
                  : ListView.builder(
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
                                style: TextStyle(fontSize: 12),
                                maxLines: 1, // 최대 1줄로 제한
                                overflow: TextOverflow.ellipsis, // 글자수가 초과되면 "..."으로 축약
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.favorite,size: 18),
                                SizedBox(width: 2),
                                Text(
                                  '${message.favoriteCount}',
                                  style: TextStyle(fontSize: 11),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.comment,size: 18),
                                SizedBox(width: 2),
                                Text(
                                  '${message.commentCount}',
                                  style: TextStyle(fontSize: 11),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.remove_red_eye,size: 18),
                                SizedBox(width: 2),
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
                              builder: (context) => DetailBoard(
                                postId: message.boardNumber,
                                initialCommentCount: message.commentCount,
                              ),
                            ),
                          );
                          if (success != null && success) {
                            await _fetchMessages();
                            setState(() {});
                          }
                        },
                      ),
                      if (index != messages.length - 1) Divider(),
                    ],
                  );
                },
              );
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final success = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WriteBoard()),
            );
            if (success != null && success) {
              _fetchMessages(); // 새로운 게시글이 등록되었으므로 게시글 목록을 다시 불러옴
              setState(() {});
            }
          },
          backgroundColor: AppColors.mintgreen,
          child: Icon(Icons.mode_edit_outline_sharp),
        ));
  }
}