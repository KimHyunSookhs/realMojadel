import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mojadel2/Config/getUserInfo.dart';
import 'package:mojadel2/colors/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ChattingPage.dart';

class ChatBoardPage extends StatefulWidget {
  @override
  _ChatBoardPageState createState() => _ChatBoardPageState();
}

class _ChatBoardPageState extends State<ChatBoardPage> {
  String? currentUserNickname;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwtToken');
    if (jwtToken != null) {
      try {
        final userInfo = await UserInfoService.getUserInfo(jwtToken);
        setState(() {
          currentUserNickname = userInfo['nickname'];
        });
      } catch (e) {
        print('Failed to load user info: $e');
      }
    }
  }

  Future<List<DocumentSnapshot>> getUserChatRooms(String userNickname) async {
    QuerySnapshot sellerChats = await FirebaseFirestore.instance
        .collection('chatRooms')
        .where('participants.seller', isEqualTo: userNickname)
        .get();

    QuerySnapshot buyerChats = await FirebaseFirestore.instance
        .collection('chatRooms')
        .where('participants.buyer', isEqualTo: userNickname)
        .get();

    return [...sellerChats.docs, ...buyerChats.docs];
  }

  Future<String> getLastMessageContent(String chatRoomId) async {
    try {
      QuerySnapshot messagesSnapshot = await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (messagesSnapshot.docs.isNotEmpty) {
        return messagesSnapshot.docs.first['text'] ?? 'No messages';
      }
    } catch (e) {
      print('Failed to get last message: $e');
    }
    return 'No messages';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('채팅방', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22)),
        backgroundColor: AppColors.mintgreen,
      ),
      body: currentUserNickname == null
          ? Center(child:Text('로그인 후 이용가능 합니다'))
          : FutureBuilder<List<DocumentSnapshot>>(
        future: getUserChatRooms(currentUserNickname!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('채팅내역이 없습니다'));
          }

          var chatRooms = snapshot.data!;

          return ListView.separated(
            itemCount: chatRooms.length,
            separatorBuilder: (context, index) => Divider(),
            itemBuilder: (context, index) {
              var chatRoom = chatRooms[index];
              return FutureBuilder<String>(
                future: getLastMessageContent(chatRoom['title']),
                builder: (context, lastMessageSnapshot) {
                  String lastMessage = lastMessageSnapshot.data ?? '';
                  return ListTile(
                    title: Text(chatRoom['title'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),),
                    subtitle: Text(lastMessage),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChattingPage(
                            title: chatRoom['title'],
                            writerNickname: chatRoom['participants']['seller'],
                            price: chatRoom['price'],
                            boardImageList: chatRoom['boardImageList'],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}