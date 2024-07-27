import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final String writerNickname;
  final String chatRoomId;

  ChatScreen({
    required this.writerNickname,
    required this.chatRoomId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _auth = FirebaseAuth.instance;
  User? loggedInUser;
  String? receiverEmail;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    fetchReceiverEmail(); // Fetch the receiver's email based on writerNickname
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          loggedInUser = user;
        });
        print('Logged in user email: ${loggedInUser!.email}');
      } else {
        print('No user is currently logged in');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchReceiverEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwtToken'); // 저장된 토큰 가져오기

    final response = await http.get(
      Uri.parse('http://10.0.2.2:4000/api/v1/users?nickname=${widget.writerNickname}'),
      headers: {
        'Authorization': 'Bearer $token', // 인증 헤더 추가
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        receiverEmail = data['email'];
      });
    } else {
      print('Failed to fetch receiver email');
    }
  }
  void _sendMessage() {
    _controller.text = _controller.text.trim();
    if (_controller.text.isNotEmpty && loggedInUser != null && receiverEmail != null) {
      FirebaseFirestore.instance.collection('chats').add({
        'text': _controller.text,
        'sender': loggedInUser!.email,
        'receiver': receiverEmail,
        'chatRoomId': widget.chatRoomId,
        'timestamp': Timestamp.now(),
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.writerNickname),
        backgroundColor: Colors.green, // 사용할 색상으로 변경하세요.
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              _auth.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('chatRoomId', isEqualTo: widget.chatRoomId) // Filter by chatRoomId
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final chatDocs = snapshot.data?.docs ?? [];
                return ListView.builder(
                  reverse: true,
                  itemCount: chatDocs.length,
                  itemBuilder: (ctx, index) {
                    final chatMessage = chatDocs[index];
                    final isMe = chatMessage['sender'] == loggedInUser?.email;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green[200] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          chatMessage['text'],
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
