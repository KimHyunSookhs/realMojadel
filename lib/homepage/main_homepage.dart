import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mojadel2/homepage/DetailPage.dart';
import 'package:mojadel2/registar/registar_page.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mojadel2/colors/colors.dart';
import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http; // For HTTP requests
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class TradeBoardListItem {
  final int boardNumber;
  final String title;
  final String content;
  final List<String> boardTitleImage;
  final int favoriteCount; // 추가된 favoriteCount
  final int commentCount; // 추가된 commentCount
  final int viewCount; // 추가된 viewCount
  final String writeDatetime; // 추가된 writeDatetime
  final String tradeLocation;
  final String writerNickname;
  final String price;
  final List<String> writerProfileImage;

  TradeBoardListItem(
      this.boardNumber,
      this.title,
      this.content,
      this.boardTitleImage,
      this.favoriteCount,
      this.commentCount,
      this.viewCount,
      this.writeDatetime,
      this.tradeLocation,
      this.writerNickname,
      this.price,
      this.writerProfileImage,
      );
}

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

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _messageStreamController = StreamController<List<TradeBoardListItem>>();
    fetchtradeBoard(); // Fetch messages when the widget initializes
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

  Future<void> fetchtradeBoard() async {
    final String uri = 'http://10.0.2.2:4000/api/v1/trade-board/latest-list';
    try {
      http.Response response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        if (_isMounted && responseData['tradeBoardListItemList'] != null) {
          if (responseData['tradeBoardListItemList'] is List) {
            final List<dynamic> messageList = responseData['tradeBoardListItemList'];
            List<TradeBoardListItem> messages = [];
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
                  data['tradeLocation']?? '',
                  data['writerNickname'],
                  data['price']?? '',
                  writerProfileImage,
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
          print('tradeBoardListItemList is null');
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
        title: Text(
          '화정동',
          style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w300,
              color: Colors.black),
        ),
        backgroundColor: AppColors.mintgreen,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search),
            color: Colors.black,
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications),
            color: Colors.black,
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.menu),
            color: Colors.black,
          )
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
                          builder: (context) => DetailPage(
                            tradeId: message.boardNumber,
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
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black, width: 0.5), // 실선 테두리 추가
                                  image: DecorationImage(
                                    image: FileImage(File(message.boardTitleImage[0])), // Use FileImage for local images
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(message.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                    SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Text('${message.tradeLocation}'),
                                        SizedBox(width: 8),
                                        Text(formatDatetime('${message.writeDatetime}')),
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    Text('${message.price}원', style: TextStyle(fontSize: 15, color: Colors.green)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(Icons.favorite),
                                        SizedBox(width: 4),
                                        Text(
                                          '${message.favoriteCount}',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.comment),
                                        SizedBox(width: 4),
                                        Text(
                                          '${message.commentCount}',
                                          style: TextStyle(fontSize: 14),
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
            fetchtradeBoard(); // 새로운 게시글이 등록되었으므로 게시글 목록을 다시 불러옴
            setState(() {});
          }
        },
      ),
    );
  }
}
