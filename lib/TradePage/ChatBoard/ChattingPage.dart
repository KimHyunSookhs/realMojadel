import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mojadel2/Config/ParseBoardImage.dart';
import 'package:mojadel2/colors/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Config/getUserInfo.dart';

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
  CollectionReference? messagesCollection;
  late Future<void> _chatRoomFuture;
  String? currentUserNickname;
  String? _jwtToken;
  bool isSeller = false;

  @override
  void initState() {
    super.initState();
    _chatRoomFuture = _loadUserInfo().then((_) {
      imageUrls = parseBoardImageList(widget.boardImageList);
      return createOrJoinChatRoom();
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
          isSeller = currentUserNickname == widget.writerNickname;
        });
      } catch (e) {
      }
    }
  }

  Future<void> createOrJoinChatRoom() async {
    String chatRoomId = widget.title;
    try {
      DocumentReference chatRoomRef = FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId);
      DocumentSnapshot chatRoomSnapshot = await chatRoomRef.get();

      // Check if chat room exists
      if (chatRoomSnapshot.exists) {
        // Check if the current user is a participant
        Map<String, dynamic>? data = chatRoomSnapshot.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('participants')) {
          Map<String, String> participantsMap = Map<String, String>.from(data['participants']);

          // If the user is not a participant, add them
          if (!participantsMap.containsValue(currentUserNickname!)) {
            participantsMap['buyer'] = currentUserNickname!;
            await chatRoomRef.update({'participants': participantsMap});
          }
        }
      } else {
        // If chat room does not exist, create it
        await chatRoomRef.set({
          'chatRoomId': chatRoomId,
          'writerNickname': widget.writerNickname,
          'title': widget.title,
          'price': widget.price,
          'boardImageList': widget.boardImageList,
          'participants': {
            'buyer': currentUserNickname!,
            'seller': widget.writerNickname,
          }
        });
      }
      setState(() {
        messagesCollection = chatRoomRef.collection('messages');
      });
    } catch (e) {
      print('Failed to create or join chat room: $e');
    }
  }


  Future<bool> _isUserParticipant() async {
    if (currentUserNickname == null) return false;

    String chatRoomId = widget.title;

    DocumentReference chatRoomRef = FirebaseFirestore.instance.collection('chatRooms').doc(chatRoomId);
    DocumentSnapshot chatRoomSnapshot = await chatRoomRef.get();

    if (chatRoomSnapshot.exists) {
      Map<String, dynamic>? data = chatRoomSnapshot.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('participants')) {
        Map<String, String> participantsMap = Map<String, String>.from(data['participants']);
        return participantsMap.containsValue(currentUserNickname);
      }
    }
    return false;
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate().toLocal().add(Duration(hours: 9));
    return "${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty || currentUserNickname == null) {
      return;
    }
    if (messagesCollection != null) {
      try {
        await messagesCollection!.add({
          'text': _messageController.text.trim(),
          'sender': currentUserNickname,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _messageController.clear();
      } catch (e) {
        print('Failed to send message: $e');
      }
    } else {
      print('Messages collection is not initialized.');
    }
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle;
    if (currentUserNickname == null) {
      appBarTitle = 'Chat';
    } else if (currentUserNickname == widget.writerNickname) {
      appBarTitle = '${widget.writerNickname}';
    } else {
      appBarTitle = '${currentUserNickname}';
    }
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
            appBarTitle, style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
                } else {
                  return FutureBuilder<bool>(
                    future: _isUserParticipant(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasData && !snapshot.data!) {
                        return Center(child: Text('You are not a participant of this chat.'));
                      } else {
                        return StreamBuilder<QuerySnapshot>(
                          stream: messagesCollection?.orderBy('timestamp', descending: true).snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (!snapshot.hasData) {
                              return Center(child: Text('No messages yet.'));
                            }
                            var messages = snapshot.data!.docs;
                            return ListView.builder(
                              reverse: true,
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                var message = messages[index];
                                bool isCurrentUser = message['sender'] == currentUserNickname;
                                return Row(
                                  mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                      padding: EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: isCurrentUser ? AppColors.mintgreen : Colors.grey.shade300,
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
                                              color: isCurrentUser ? Colors.white : Colors.black54,
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
                  );
                }
              },
            ),
          ),
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