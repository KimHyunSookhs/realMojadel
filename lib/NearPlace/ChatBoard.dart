import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mojadel2/colors/colors.dart';
import '../homepage/ChattingPage.dart';

class ChatBoardPage extends StatefulWidget {
  final String sellerNickname;
  const ChatBoardPage({Key? key, required this.sellerNickname}) : super(key: key);

  @override
  _ChatBoardPageState createState() => _ChatBoardPageState();
}

class _ChatBoardPageState extends State<ChatBoardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Rooms'),
        backgroundColor: AppColors.mintgreen,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chatRooms')
            .where('participants.seller', isEqualTo: widget.sellerNickname)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No chat rooms found.'));
          }

          var chatRooms = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              var chatRoom = chatRooms[index];
              return ListTile(
                title: Text(chatRoom['title']),
                subtitle: Text('Buyer: ${chatRoom['participants']['buyer']}'),
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
      ),
    );
  }
}
