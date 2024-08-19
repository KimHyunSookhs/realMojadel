import 'dart:convert';

List<String> parseBoardImageList(String jsonString) {
  try {
    if (jsonString.isEmpty) {
      return [];
    }
    List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.cast<String>();
  } catch (e) {
    print('Error parsing boardImageList: $e');
    return [];
  }
}