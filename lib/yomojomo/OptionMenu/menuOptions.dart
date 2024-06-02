import 'package:flutter/material.dart';
import 'deletePost.dart';
import '../detailboard.dart';
import 'editPost.dart';

Future<void> handleMenuSelection(BuildContext context, String value, String? userEmail, String writerEmail, int postId, String jwtToken, String title, String content, Function setState, List<String> parsedBoardImageList) async {
  switch (value) {
    case 'edit':
      if (userEmail != null && userEmail == writerEmail) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditPost(
              postId: postId,
              initialTitle: title,
              initialContent: content,
              boardImageList: parsedBoardImageList, // Pass the image URL
            ),
          ),
        );
        if (result == true){
          setState(() {
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('작성자만 수정할 수 있습니다.'),
          ),
        );
      }
      break;
    case 'delete':
      if (userEmail != null && userEmail == writerEmail) {
        confirmDelete(context, postId, jwtToken);
        setState(() {
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('작성자만 삭제할 수 있습니다.'),
          ),
        );
      }
      break;
  }
}