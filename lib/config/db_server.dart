
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

// Future<void> saveUser(User user) async {
//   try {
//     final response = await http.post(
//       Uri.parse("http://10.0.2.2:4000/api/v1/auth/sign-up"),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//       },
//       body: jsonEncode(user.toJson()),
//     );
//     if (response.statusCode != 200) {
//       throw Exception("Failed to send data");
//     } else {
//       print("User Data sent successfully");
//       Get.to(const mypagesite());
//     }
//   } catch (e) {
//     print("Failed to send user data: ${e}");
//   }
// }

Future<void> fetchUserData(String userId) async {
  try {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:4000/api/v1/auth/user/$userId"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      // 서버로부터 성공적으로 데이터를 받았을 때의 처리
      print("User Data received successfully");
      final data = jsonDecode(response.body);
      print(data); // 받은 데이터를 출력하거나 다른 처리를 할 수 있습니다.
      // 예를 들어, 받은 데이터를 화면에 표시하는 등의 작업을 할 수 있습니다.
    } else {
      // 서버로부터 오류 응답을 받았을 때의 처리
      throw Exception("Failed to fetch data");
    }
  } catch (e) {
    print("Failed to fetch user data: ${e}");
  }
}