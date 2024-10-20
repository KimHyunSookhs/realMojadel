import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mojadel2/TradePage/DetailTradePage.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:mojadel2/TradePage/registar/registar_page.dart';
import 'package:mojadel2/colors/colors.dart';
import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http; // For HTTP requests
import 'dart:async';
import 'TradeBoardList/TradeBoardListItem.dart';

class MainhomePage extends StatefulWidget {
  const MainhomePage({Key? key}) : super(key: key);
  @override
  State<MainhomePage> createState() => _MainhomePageState();
}

class _MainhomePageState extends State<MainhomePage> {
  List<TradeBoardListItem> _messages = [];
  late StreamController<List<TradeBoardListItem>> _messageStreamController;
  bool _isMounted = false;
  String? _jwtToken;
  bool _isSearching = false;
  String? chatRoomId;
  TextEditingController _searchController = TextEditingController();
  Map<int, bool> _tradeCompletionStatus = {};

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _messageStreamController = StreamController<List<TradeBoardListItem>>();
    fetchtradeBoard();
  }

  @override
  void dispose() {
    _isMounted = false;
    _messageStreamController.close();
    super.dispose();
  }

  String formatDatetime(String datetime) {
    if (datetime != null && datetime.isNotEmpty) {
      DateTime parsedDatetime = DateTime.parse(datetime).toUtc();
      return DateFormat('MM/dd').format(parsedDatetime);
    } else {
      return '';
    }
  }
  Future<void> checkTradeCompletionStatus(int tradeId) async {
    final tradeRef = FirebaseFirestore.instance.collection('trades').doc(tradeId.toString());
    final tradeSnapshot = await tradeRef.get();
    if (tradeSnapshot.exists) {
      final data = tradeSnapshot.data();
      bool isCompleted = data?['completed'] ?? false;
      if (_isMounted) {
        setState(() {
          _tradeCompletionStatus[tradeId] = isCompleted;
        });
      }
    }
  }

  Future<void> fetchtradeBoard() async {
    final String uri = 'http://13.125.228.152:4000/api/v1/trade/trade-board/latest-list';
    try {
      http.Response response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        if (_isMounted && responseData['tradelatestList'] != null) {
          if (responseData['tradelatestList'] is List) {
            final List<dynamic> messageList = responseData['tradelatestList'];
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
                  data['boardNumber'] ?? 0,
                  data['title'] ?? '',
                  data['content'] ?? '',
                  boardTitleImageList,
                  data['favoriteCount'] ?? 0,
                  data['commentCount'] ?? 0,
                  data['viewCount'] ?? 0,
                  data['writeDatetime'] ?? '',
                  data['tradeLocation'] ?? '',
                  data['price'] ?? '0',
                  data['writerNickname'] ?? '',
                  data['writerProfileImage'] ?? '',
                ),
              );
              await checkTradeCompletionStatus(data['boardNumber']);
            }
            messages.sort((a, b) {
              bool aCompleted = _tradeCompletionStatus[a.boardNumber] ?? false;
              bool bCompleted = _tradeCompletionStatus[b.boardNumber] ?? false;
              if (aCompleted && !bCompleted) return 1;
              if (!aCompleted && bCompleted) return -1;
              return 0;
            });
            if (_isMounted) {
              setState(() {
                _messages = messages;
                _messageStreamController.add(messages);
              });
            }
          }
        }
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
      fetchtradeBoard();
    });
  }

  Future<void> _performSearch(String searchWord) async {
    final String uri = 'http://13.125.228.152:4000/api/v1/trade/trade-board/search-list/$searchWord';
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
                data['tradeLocation']?? '',
                data['price']?? '',
                data['writerNickname'],
                data['writerProfileImage']?? '',
              ),
            );
          }
          setState(() {
            _messages = searchResults;
          });
          _messageStreamController.add(searchResults);
        } else {
          print('No search results found');
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
            : Text('중고거래'),
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
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: StreamBuilder<List<TradeBoardListItem>>(
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
                  return GestureDetector(
                    onTap: () async {
                      final success = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailTradePage(
                            tradeId: message.boardNumber,
                            chatRoomId: chatRoomId ?? '',
                          ),
                        ),
                      );
                      if (success != null && success) {
                        fetchtradeBoard(); // 새로운 게시글이 등록되었으므로 게시글 목록을 다시 불러옴
                        setState(() {});
                      }
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            children: [
                              Container(
                                width: 100,
                                height: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black, width: 0.5),
                                  image: DecorationImage(
                                    image: message.boardTitleImage.isNotEmpty
                                        ? (message.boardTitleImage[0].startsWith('http')
                                        ? NetworkImage(message.boardTitleImage[0]) as ImageProvider<Object>
                                        : FileImage(File(message.boardTitleImage[0])) as ImageProvider<Object>)
                                        : AssetImage('assets/placeholder_image.png') as ImageProvider<Object>, // Use a placeholder if no image
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 5,),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          message.title,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          softWrap: true,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (_tradeCompletionStatus[message.boardNumber] == true) ...[
                                          Text(
                                            '거래완료',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.red,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    SizedBox(
                                      child: Text('${message.tradeLocation}',
                                        style: TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(formatDatetime('${message.writeDatetime}')),
                                    Text('${message.price}원', style: TextStyle(fontSize: 15, color: Colors.green)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(Icons.favorite),
                                        SizedBox(width: 4),
                                        Text(
                                          '${message.favoriteCount}',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.comment),
                                        SizedBox(width: 4),
                                        Text(
                                          '${message.commentCount}',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (index != messages.length - 1) Divider(),
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
            context, MaterialPageRoute(builder: (context) => RegistarPage()),);
          if (success != null && success) {
            fetchtradeBoard();
            setState(() {});
          }
        },
      ),
    );
  }
}
