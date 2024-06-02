import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<void> confirmDelete(BuildContext context, int postId, String jwtToken) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('게시글 삭제'),
        content: Text('정말로 이 게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            child: Text('취소'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('삭제'),
            onPressed: () {
              Navigator.of(context).pop();
              _deletePost(context, postId, jwtToken);
            },
          ),
        ],
      );
    },
  );
}

Future<void> _deletePost(BuildContext context, int postId, String jwtToken) async {
  final String uri = 'http://10.0.2.2:4000/api/v1/board/$postId';
  try {
    http.Response response = await http.delete(
      Uri.parse(uri),
      headers: {
        'Authorization': 'Bearer $jwtToken', // 인증 헤더 추가
      },
    );
    if (response.statusCode == 200) {
      Navigator.pop(context, true); // 게시글 목록으로 돌아가기
    } else {
      print('Failed to delete post: ${response.statusCode}');
    }
  } catch (error) {
    print('Failed to delete post: $error');
  }
}