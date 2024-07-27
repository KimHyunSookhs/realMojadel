import 'package:flutter/material.dart';
import 'package:mojadel2/colors/colors.dart';

class ChatBoard extends StatefulWidget {
  const ChatBoard({super.key});@override
  State<ChatBoard> createState() => _ChatBoardState();
}

class _ChatBoardState extends State<ChatBoard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('채팅방'),
        backgroundColor: AppColors.mintgreen,
      ),
      body: Center(child: Text('채팅방')),
    );
  }
}
