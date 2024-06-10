import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mojadel2/yomojomo/Detailboard/getUserInfo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../colors/colors.dart';
import '../yomojomo/Detailboard/showWriteTime.dart';
import 'EditTrade.dart';


class DetailPage extends StatefulWidget {
  final int tradeId;
  const DetailPage({Key? key, required this.tradeId}) : super(key: key);
  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  String title = '';
  String content = '';
  String writeDatetime = '';
  String writerEmail = '';
  String tradeLocation = '';
  String price = '';
  bool isLoading = true;
  int favoriteCount = 0;
  int commentCount = 0; // Added commentCount
  String writerNickname = '';
  String? _userEmail;
  String? _jwtToken;
  bool isFavorite = false;
  int? boardNumber;
  String boardImageList = ''; // Add imageUrl
  bool isUpdatingFavorite = false;
  String? _profileImageUrl;
  String? _nickname;
  String? _writerProfileImageUrl;
  int? commentNumber;
  TextEditingController _commentController = TextEditingController();
  int _currentImageIndex=0;
  @override
  void initState() {
    super.initState();
    _loadUserInfo().then((_) {
      fetchTradeDetail();
    });
  }

  Future<void> fetchTradeDetail() async {
    final String uri = 'http://10.0.2.2:4000/api/v1/trade-board/${widget
        .tradeId}';
    try {
      http.Response response = await http.get(Uri.parse(uri), headers: {
        'Authorization': 'Bearer $_jwtToken', // 인증 헤더 추가
      });
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
        json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          title = responseData['title'];
          content = responseData['content'];
          writeDatetime = responseData['writeDatetime'];
          writerNickname = responseData['writerNickname'];
          writerEmail = responseData['writerEmail'];
          boardNumber = responseData['boardNumber'];
          tradeLocation = responseData['tradeLocation'];
          isLoading = false;
          price = responseData['price'];
          _writerProfileImageUrl = responseData['writerProfileImage'];
          boardImageList = responseData['boardImageList'] != null
              ? json.encode(responseData['boardImageList'])
              : '';
        });
        print("${responseData}");
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('jwtToken');
    if (_jwtToken != null) {
      final userInfo = await UserInfoService.getUserInfo(_jwtToken!);
      setState(() {
        _nickname = userInfo['nickname'];
        _userEmail = userInfo['email'];
        _profileImageUrl = userInfo['profileImage'];
      });
    }
  }
  List<String> parseBoardImageList(String jsonString) {
    try {
      if (jsonString.isEmpty) {
        return []; // Return an empty list if the string is empty
      }
      List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<String>();
    } catch (e) {
      print('Error parsing boardImageList: $e');
      return [];
    }
  }

  Future<void> confirmDelete() async {
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
                deleteTradeBoard();
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> deleteTradeBoard() async {
    final String uri = 'http://10.0.2.2:4000/api/v1/trade-board/${widget.tradeId}';
    try {
      http.Response response = await http.delete(
        Uri.parse(uri),
        headers: {
          'Authorization': 'Bearer $_jwtToken', // 인증 헤더 추가
        },
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글이 삭제되었습니다.')),
        );
        Navigator.pop(context, true); // 게시글 목록으로 돌아가기
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글 삭제에 실패했습니다.')),
        );
        print(' 상태 코드: ${response.statusCode}, 메시지: ${response.body}');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 삭제에 실패했습니다.')),
      );
    }
  }

  void editTradeBoard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTradePage(
        tradeId: widget.tradeId,
        initialTitle: title,
        initialContent: content,
        initialLocation: tradeLocation,
        initialPrice: price,
        boardImageList: parseBoardImageList(boardImageList),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> imageUrls = parseBoardImageList(boardImageList);
    return Scaffold(
      appBar: AppBar(
        title:  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0),
        ),
        backgroundColor: AppColors.mintgreen,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        actions: [
          // 수정 버튼
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              editTradeBoard();
            },
          ),
          // 삭제 버튼
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              confirmDelete();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (imageUrls.isNotEmpty)
              imageUrls.length > 1
                  ? Column(
                children: [
                  CarouselSlider(
                    items: imageUrls.map((imageUrl) {
                      return Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageUrl.startsWith('http')
                                ? NetworkImage(imageUrl)
                                : FileImage(File(imageUrl))
                            as ImageProvider,
                            fit: BoxFit.fill,
                          ),
                        ),
                      );
                    }).toList(),
                    options: CarouselOptions(
                      height: 350,
                      enlargeCenterPage: true,
                      aspectRatio: 16 / 9,
                      viewportFraction: 0.8,
                      enableInfiniteScroll: true,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: imageUrls.map((url) {
                      int index = imageUrls.indexOf(url);
                      return Container(
                        width: 8.0,
                        height: 8.0,
                        margin: EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentImageIndex
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              )
                  : Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  border: Border.all(
                    color: Colors.black, // 테두리 선의 색상 설정
                    width: 1.0, // 테두리 선의 두께 설정
                  ),
                  image: DecorationImage(
                    image: imageUrls[0].startsWith('http')
                        ? NetworkImage(imageUrls[0])
                        : FileImage(File(imageUrls[0]))
                    as ImageProvider,
                    fit: BoxFit.fill, // 이미지가 컨테이너를 가득 채우도록 설정
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black, // 테두리 선의 색상 설정
                            width: 0.8, // 테두리 선의 두께 설정
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white10,
                          backgroundImage: _writerProfileImageUrl != null
                              ? (_writerProfileImageUrl!.startsWith('http')
                              ? NetworkImage(_writerProfileImageUrl!)
                              : FileImage(File(_writerProfileImageUrl!))
                          as ImageProvider)
                              : null,
                          child: _writerProfileImageUrl == null
                              ? Icon(Icons.person, size: 50)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            writerNickname,
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            tradeLocation,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  SizedBox(height: 8.0),
                  Text(
                    '$content',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    '가격: $price원',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  SizedBox(height: 8.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}