import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mojadel2/colors/colors.dart';
import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http; // For HTTP requests
import 'package:mojadel2/yomojomo/Detailboard/showWriteTime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Comment/commentList.dart';
import 'Detailboard/viewCount.dart';
import 'OptionMenu/menuOptions.dart';
import 'package:mojadel2/yomojomo/Detailboard/getUserInfo.dart';

class DetailBoard extends StatefulWidget {
  final int postId;
  final int initialCommentCount;

  const DetailBoard({
    Key? key,
    required this.postId,
    required this.initialCommentCount,
  }) : super(key: key);

  @override
  State<DetailBoard> createState() => _DetailBoardState();
}

class _DetailBoardState extends State<DetailBoard> {
  String title = '';
  String content = '';
  String writeDatetime = '';
  String writerEmail = '';
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
  List<CommentListItem> comments = []; // List to store comments

  @override
  void initState() {
    super.initState();
    commentCount = widget.initialCommentCount;
    _loadUserInfo().then((_) {
      fetchPostDetails();
      increaseViewCount(widget.postId, _jwtToken!);
      _loadFavoriteCount();
      fetchComments();
    });
  }

  Future<void> fetchPostDetails() async {
    final String uri = 'http://10.0.2.2:4000/api/v1/board/${widget.postId}';
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
          isLoading = false;
          isFavorite = responseData['isFavorite'] ?? false;
          _writerProfileImageUrl = responseData['writerProfileImage'];
          boardImageList = responseData['boardImageList'] != null
              ? json.encode(responseData['boardImageList'])
              : '';
        });
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

  Future<void> _loadFavoriteCount() async {
    if (_jwtToken != null) {
      final count =
          await _getFavoriteCountFromLatestList(widget.postId, _jwtToken!);
      setState(() {
        favoriteCount = count ?? 0;
      });
    }
  }
  Future<int?> _getFavoriteCountFromLatestList(
      int postId, String jwtToken) async {
    final String uri = 'http://10.0.2.2:4000/api/v1/board/latest-list';
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
        final List<dynamic> latestList = responseData['latestList'];
        final post = latestList.firstWhere(
            (item) => item['boardNumber'] == postId,
            orElse: () => null);
        if (post != null) {
          final int favoriteCount = post['favoriteCount'] ?? 0;
          final bool isFavorite = post['isFavorite'] ?? false;
          setState(() {
            this.isFavorite = isFavorite;
          });
          return favoriteCount;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (error) {
      return null;
    }
  }
  Future<void> toggleFavorite() async {
    if (isUpdatingFavorite) return; // 이미 업데이트 중이면 아무 작업도 하지 않음
    setState(() {
      isUpdatingFavorite = true;
    });
    final String uri =
        'http://10.0.2.2:4000/api/v1/board/${widget.postId}/favorite';
    try {
      final Map<String, dynamic> requestBody = {
        'email': _userEmail, // 사용자 이메일 추가
      };
      http.Response response = await http.put(
        Uri.parse(uri),
        headers: {
          'Authorization': 'Bearer $_jwtToken', // 인증 헤더 추가
          'Content-Type': 'application/json', // JSON 타입 명시
        },
        body: json.encode(requestBody), // 요청 본문에 이메일 포함
      );
      if (response.statusCode == 200) {
        await _loadFavoriteCount(); // 좋아요 카운트를 다시 불러옴
        setState(() {
          isFavorite = !isFavorite;
          isUpdatingFavorite = false;
        });
      } else {
        print('Failed to update favorite count: ${response.statusCode}');
        setState(() {
          isUpdatingFavorite = false;
        });
      }
    } catch (error) {
      print('Failed to update favorite count: $error');
      setState(() {
        isUpdatingFavorite = false;
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

  Future<void> postComment(String content) async {
    final String uri =
        'http://10.0.2.2:4000/api/v1/board/${widget.postId}/comment';
    try {
      final Map<String, dynamic> requestBody = {
        'content': content, // Add the comment text
      };
      http.Response response = await http.post(
        Uri.parse(uri),
        headers: {
          'Authorization': 'Bearer $_jwtToken', // Add authorization header
          'Content-Type': 'application/json', // Specify JSON content type
        },
        body: json
            .encode(requestBody), // Include comment text in the request body
      );
      if (response.statusCode == 200) {
        setState(() {
          commentCount++; // Increment comment count
        });
        fetchComments(); // Fetch post details again to update the UI
      } else {
        print('Failed to post comment: ${response.statusCode}');
      }
    } catch (error) {
      print('Failed to post comment: $error');
    }
  }

  Future<void> fetchComments() async {
    final String uri = 'http://10.0.2.2:4000/api/v1/board/${widget.postId}/comment-list';
    try {
      http.Response response = await http.get(Uri.parse(uri), headers: {
        'Authorization': 'Bearer $_jwtToken',
      });
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
        json.decode(utf8.decode(response.bodyBytes));
        if (responseData['commentList'] != null &&
            responseData['commentList'] is List) {
          List<CommentListItem> fetchedComments = [];
          for (var commentData in responseData['commentList']) {
            CommentListItem comment = CommentListItem.fromJson(commentData);
            fetchedComments.add(comment);
          }
          setState(() {
            comments = fetchedComments;
          });
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

  void _handleMenuSelection(String value) async {
    handleMenuSelection(
        context, value, _userEmail, writerEmail, widget.postId, _jwtToken!, title,
        content, setState, parseBoardImageList(boardImageList));
  }
  Future<void> deleteComment(int commentNumber) async {
    if (_jwtToken == null) {
      print('JWT token is null');
      return;
    }
    final String uri =
        'http://10.0.2.2:4000/api/v1/board/$boardNumber/$commentNumber';
    try {
      http.Response response = await http.delete(
        Uri.parse(uri),
        headers: {
          'Authorization': 'Bearer $_jwtToken', // Add authorization header
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          commentCount--; // 댓글 수를 줄임
          comments.removeWhere((comment) => comment.commentNumber == commentNumber); // Remove comment from list
        });
        fetchComments(); // Fetch comments again to update the UI
      } else {
        print('Failed to delete comment: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (error) {
      print('Failed to delete comment: $error');
    }
  }
  Future<void> editComment(int commentNumber, String newContent) async {
    final String uri = 'http://10.0.2.2:4000/api/v1/board/$boardNumber/$commentNumber';
    try {
      final Map<String, dynamic> requestBody = {
        'content': newContent, // New content for the comment
      };
      http.Response response = await http.patch(
        Uri.parse(uri),
        headers: {
          'Authorization': 'Bearer $_jwtToken', // Add authorization header
          'Content-Type': 'application/json', // Specify JSON content type
        },
        body: json.encode(requestBody), // Include new content in the request body
      );
      if (response.statusCode == 200) {
        fetchComments(); // Fetch comments again to update the UI
      } else {
        print('Failed to edit comment: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (error) {
      print('Failed to edit comment: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> imageUrls = parseBoardImageList(boardImageList);
    return Scaffold(
      appBar: AppBar(
        title: Text('게시글'),
        backgroundColor: AppColors.mintgreen,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) {
              return {'edit', 'delete'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice == 'edit' ? '수정' : '삭제'),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black, // 테두리 선의 색상 설정
                            width: 1.0, // 테두리 선의 두께 설정
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
                                fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            formatDatetime(writeDatetime),
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(
                    title,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    content,
                    style: TextStyle(fontSize: 22),
                  ),
                  const SizedBox(height: 10),
                  if (imageUrls.isNotEmpty)
                    Column(
                      children: [
                        for (String imageUrl in imageUrls)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Container(
                              width: 400,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                border: Border.all(
                                  color: Colors.black, // 테두리 선의 색상 설정
                                  width: 1.0, // 테두리 선의 두께 설정
                                ),
                                image: DecorationImage(
                                  image: imageUrl.startsWith('http')
                                      ? NetworkImage(imageUrl)
                                      : FileImage(File(imageUrl))
                                          as ImageProvider,
                                  fit: BoxFit.fill, // 이미지가 컨테이너를 가득 채우도록 설정
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        color: Colors.red,
                        size: 17,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '$favoriteCount', // null일 경우 0으로 처리
                        style: TextStyle(fontSize: 17),
                      ),
                      SizedBox(width: 7),
                      Icon(
                        Icons.comment,
                        color: Colors.black,
                        size: 17,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '$commentCount', // null일 경우 0으로 처리
                        style: TextStyle(fontSize: 17),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  const Divider(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                        onPressed: toggleFavorite,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.black, width: 0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 15,
                            ),
                            SizedBox(
                              width: 2,
                            ),
                            Text(
                              'like',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.black),
                            ),
                          ],
                        )),
                  ),
                  SizedBox(height: 10,),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                              comments[index].nickname ?? '', // 닉네임
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatDatetime(
                                      comments[index].writeDatetime ??
                                          ''), // 작성 시간
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  comments[index].content ?? '', // 댓글 내용
                                  style: TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                            leading: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black, // 테두리 선의 색상 설정
                                  width: 0.5, // 테두리 선의 두께 설정
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: comments[index].profileImage != null
                                    ? (comments[index].profileImage!.startsWith('http')
                                        ? NetworkImage(comments[index].profileImage!)
                                        : FileImage(File(comments[index].profileImage!)) as ImageProvider)
                                    : null,
                                child: comments[index].profileImage == null
                                    ? Icon(Icons.person, size: 50)
                                    : null,
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (String value) async {
                                switch (value) {
                                  case 'edit':
                                    TextEditingController editController = TextEditingController(text: comments[index].content);
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('댓글 수정'),
                                          content: TextField(
                                            controller: editController,
                                            decoration: InputDecoration(
                                              hintText: '댓글을 수정하세요',
                                            ),
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop(); // Close the dialog
                                              },
                                              child: Text('취소'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                String newContent = editController.text;
                                                if (comments[index].nickname?.trim() == _nickname?.trim()&&newContent.isNotEmpty && comments[index].commentNumber != null) {
                                                  await editComment(comments[index].commentNumber!, newContent);
                                                  Navigator.of(context).pop(); // Close the dialog
                                                }
                                                else {
                                                  print('댓글 작성자가 아니므로 수정할 수 없습니다.');
                                                }
                                              },
                                              child: Text('저장'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    break;
                                  case 'delete':
                                    if (comments[index].nickname?.trim() == _nickname?.trim() && comments[index].commentNumber != null) {
                                      await deleteComment(comments[index].commentNumber!,);
                                      setState(() {
                                        comments.removeAt(index);
                                      });
                                    } else {
                                      print('댓글 작성자가 아니므로 삭제할 수 없습니다.');
                                    }
                                    break;
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                return {'edit', 'delete'}.map((String choice) {
                                  return PopupMenuItem<String>(
                                    value: choice,
                                    child: Text(choice == 'edit' ? '수정' : '삭제'),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          if (index < comments.length - 1)
                            Divider(),
                        ],
                      );
                    },
                  ),
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: '댓글을 입력하세요',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {
                          String comment = _commentController.text;
                          if (comment.isNotEmpty) {
                            postComment(comment); // Post the comment
                            _commentController.clear(); // Clear the input field
                          }
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
