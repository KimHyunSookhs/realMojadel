import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mojadel2/Comment/commentList.dart';

Future<void> postComment(int postId, String content, String jwtToken) async {
  final String uri = 'http://52.79.217.191:4000/api/v1/community/board/$postId/comment';
  try {
    final Map<String, dynamic> requestBody = {
      'content': content,
    };
    http.Response response = await http.post(
      Uri.parse(uri),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
      if (responseData['commentList'] != null && responseData['commentList'] is List) {
        List<CommentListItem> fetchedComments = [];
        for (var commentData in responseData['commentList']) {
          CommentListItem comment = CommentListItem.fromJson(commentData);
          fetchedComments.add(comment);
        }
      } else {
        print('Comments data is not in the expected format');
      }
    } else {
      print('Failed to fetch comments: ${response.statusCode}');
    }
  } catch (error) {
    print('Failed to fetch comments: $error');
  }
}

Future<void> fetchComments(int postId, String jwtToken) async {
  final String uri = 'http://52.79.217.191:4000/api/v1/community/board/$postId/comment-list';
  try {
    http.Response response = await http.get(Uri.parse(uri), headers: {
      'Authorization': 'Bearer $jwtToken',
    });
    if (response.statusCode == 200) {
      fetchComments(postId, jwtToken); // Fetch post details again to update the UI
    } else {
      print('Failed to post comment: ${response.statusCode}');
    }
  } catch (error) {
    print('Failed to post comment: $error');
  }
}