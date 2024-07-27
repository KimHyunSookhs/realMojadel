import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mojadel2/colors/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../yomojomo/Detailboard/getUserInfo.dart'; // Firebase Auth 패키지 추가

class ChattingPage extends StatefulWidget {
  final String writerNickname;
  final String title;
  final String price;
  final String boardImageList;

  const ChattingPage({
    Key? key,
    required this.writerNickname,
    required this.title,
    required this.price,
    required this.boardImageList,
  }) : super(key: key);
  @override
  _ChattingPageState createState() => _ChattingPageState();
}

class _ChattingPageState extends State<ChattingPage> {
  List<String> imageUrls = [];
  final TextEditingController _messageController = TextEditingController();
  late CollectionReference messagesCollection;
  late Future<void> _chatRoomFuture;
  String? currentUserNickname;
  String? _jwtToken;

  @override
  void initState() {
    super.initState();
    _chatRoomFuture = _loadUserInfo().then((_) {
      imageUrls = parseBoardImageList(widget.boardImageList);
      return createChatRoom();
    });
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('jwtToken');
    if (_jwtToken != null) {
      try {
        final userInfo = await UserInfoService.getUserInfo(_jwtToken!);
        setState(() {
          currentUserNickname = userInfo['nickname'];
        });
        print("현재 사용자 ${currentUserNickname}");
      } catch (e) {
        print('Failed to load user info: $e');
      }
    } else {
      print('JWT Token is null');
    }
  }

  List<String> parseBoardImageList(String jsonString) {
    try {
      if (jsonString.isEmpty) {
        return []; // Return an empty list if the string is empty
      }
      List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<String>();
    } catch (e) {
      print('Error parsing boardImageList: $e');
      return [];
    }
  }

  Future<void> createChatRoom() async {
    String chatRoomId = widget.title;
    await FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId).set({
      'chatRoomId': chatRoomId,
      'writerNickname': widget.writerNickname,
      'title': widget.title,
      'price': widget.price,
      'boardImageList': widget.boardImageList,
    });
    messagesCollection = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages');
  }
  String formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate().toLocal().add(Duration(hours: 9)); // UTC+9
    return "${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (currentUserNickname != null) {
      await messagesCollection.add({
        'text': _messageController.text.trim(),
        'sender': currentUserNickname,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Message sent by $currentUserNickname');
      _messageController.clear();
    } else {
      print('User nickname is not available');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.writerNickname),
        backgroundColor: AppColors.mintgreen,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrls.isNotEmpty)
            Container(
              margin: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageUrls[0].startsWith('http')
                            ? NetworkImage(imageUrls[0])
                            : FileImage(File(imageUrls[0])) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.price + '원',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Divider(),
          Expanded(
            child: FutureBuilder<void>(
              future: _chatRoomFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return StreamBuilder<QuerySnapshot>(
                    stream: messagesCollection
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }
                      var messages = snapshot.data!.docs;
                      return ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          var message = messages[index];
                          bool isCurrentUser = message['sender'] == currentUserNickname;
                          return Row(
                            mainAxisAlignment: isCurrentUser
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                padding: EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: isCurrentUser ? Colors.blue : Colors.grey.shade300,
                                  borderRadius: isCurrentUser
                                      ? BorderRadius.only(
                                    topLeft: Radius.circular(12.0),
                                    topRight: Radius.circular(12.0),
                                    bottomLeft: Radius.circular(12.0),
                                  )
                                      : BorderRadius.only(
                                    topLeft: Radius.circular(12.0),
                                    topRight: Radius.circular(12.0),
                                    bottomRight: Radius.circular(12.0),
                                  ),
                                ),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                                ),
                                child: Column(
                                  crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message['text'],
                                      style: TextStyle(
                                        color: isCurrentUser ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4.0),
                                    Text(
                                      message['timestamp'] != null
                                          ? formatTimestamp(message['timestamp'] as Timestamp)
                                          : '전송중...',
                                      style: TextStyle(
                                        color: isCurrentUser ? Colors.white70 : Colors.black54,
                                        fontSize: 10.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
          // Input Field Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '메세지를 입력해 주세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
