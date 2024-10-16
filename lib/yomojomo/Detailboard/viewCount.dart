import 'package:http/http.dart' as http;

Future<void> increaseViewCount(int postId, String jwtToken) async {
  final String uri = 'http://43.203.205.218:4000/api/v1/community/board/$postId/increase-view-count';
  try {
    http.Response response = await http.get(Uri.parse(uri), headers: {
      'Authorization': 'Bearer $jwtToken', // 인증 헤더 추가
    });
    if (response.statusCode != 200) {
      print('Failed to increase view count: ${response.statusCode}');
    }
  } catch (error) {
    print('Failed to increase view count: $error');
  }
}
