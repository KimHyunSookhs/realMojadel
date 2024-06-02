import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mojadel2/colors/colors.dart';
import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http; // For HTTP requests
import 'package:shared_preferences/shared_preferences.dart';

void showSearchDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      String searchWord = '';
      return AlertDialog(
        title: Text('검색어를 입력하세요'),
        content: TextField(
          onChanged: (value) {
            searchWord = value;
          },
          decoration: InputDecoration(hintText: "검색어"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchWord(searchWord: searchWord),
                ),
              );
            },
            child: Text('검색'),
          ),
        ],
      );
    },
  );
}

class SearchWord extends StatefulWidget {
  final String searchWord;

  const SearchWord({Key? key, required this.searchWord}) : super(key: key);

  @override
  _SearchWordState createState() => _SearchWordState();
}

class _SearchWordState extends State<SearchWord> {
  int? boardNumber;
  String title = '';
  String content = '';
  String boardImageList = '';
  int favoriteCount = 0;
  int commentCount = 0;
  int viewCount = 0;
  String writeDatetime = '';
  String writerNickname = '';
  String? _writerProfileImageUrl;
  String? _jwtToken;

  @override
  void initState() {
    super.initState();
    searchPost();
  }

  Future<void> searchPost() async {
    final String uri = 'http://10.0.2.2:4000/api/v1/board/search-list/${widget.searchWord}';
    try {
      http.Response response = await http.get(Uri.parse(uri), headers: {
        'Authorization': 'Bearer $_jwtToken',
      });
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          boardNumber = responseData['boardNumber'];
          title = responseData['title'];
          content = responseData['content'];
          writeDatetime = responseData['writeDatetime'];
          writerNickname = responseData['writerNickname'];
          boardImageList = responseData['boardImageList'] != null
              ? json.encode(responseData['boardImageList'])
              : '';
        });
        print('${responseData}');
      } else {
        setState(() {
          // Handle error
        });
      }
    } catch (error) {
      setState(() {
        // Handle error
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('검색 결과'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('제목: $title', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('내용: $content'),
            // Add more fields as needed
          ],
        ),
      ),
    );
  }
}