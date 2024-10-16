import 'package:http/http.dart' as http;
import 'dart:convert';

Future<int?> getUserRecipePostsCount(String userEmail, String jwtToken, String? nickname) async {
  final String uri = 'http://43.203.121.121:4000/api/v1/recipe/recipe-board/user-board-list/$userEmail';
  final Map<String, String> headers = {
    'Authorization': 'Bearer $jwtToken',
  };

  try {
    final response = await http.get(
      Uri.parse(uri),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> userBoardList = responseData['userBoardList'] != null
          ? (responseData['userBoardList'] as List<dynamic>)
          .where((board) => board['writerNickname'] == nickname)
          .toList()
          : [];
      final int userBoardCount = userBoardList.length;
      return userBoardCount;
    } else {

      return null;
    }
  } catch (error) {
    print('Failed to get user posts count: $error');
    return null;
  }
}
