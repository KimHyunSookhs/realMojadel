import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http; // For HTTP requests

class UserInfoService {
  static Future<Map<String, dynamic>> getUserInfo(String jwtToken) async {
    final String uri = 'http://10.0.2.2:4000/api/v1/user/';
    final Map<String, String> headers = {
      'Authorization': 'Bearer $jwtToken',
    };
    try {
      final response = await http.get(
        Uri.parse(uri),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
        json.decode(utf8.decode(response.bodyBytes));
        return {
          'nickname': responseData['nickname'],
          'email': responseData['email'], // 사용자 이메일 반환
          'profileImage': responseData['profileImage'],
        };
      } else {
        return {};
      }
    } catch (error) {
      return {};
    }
  }
}
