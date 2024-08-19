import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mojadel2/colors/colors.dart';
import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http; // For HTTP requests
import 'package:mojadel2/yomojomo/Detailboard/showWriteTime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mojadel2/Comment/commentList.dart';
import 'package:mojadel2/Config/getUserInfo.dart';
import '../Config/ParseBoardImage.dart';
import '../Favorite/FavoriteListItem.dart';
import 'OptionMenu_Recipe/RecipeMenuOptions.dart';

class DetailRecipePage extends StatefulWidget {
  final int recipeId;
  const DetailRecipePage({Key? key,required this.recipeId}) : super(key: key);
  @override
  State<DetailRecipePage> createState() => _DetailRecipePageState();
}

class _DetailRecipePageState extends State<DetailRecipePage> {
  String title = '';
  String content = '';
  String writeDatetime = '';
  String writerEmail = '';
  bool isLoading = true;
  int favoriteCount = 0;
  String writerNickname = '';
  String? _userEmail;
  String? _jwtToken;
  bool isFavorite = false;
  int? boardNumber;
  String boardImageList = '';
  bool isUpdatingFavorite = false;
  String? _profileImageUrl;
  String? _nickname;
  String? _writerProfileImageUrl;
  TextEditingController _commentController = TextEditingController();
  int? commentNumber;
  int commentCount = 0;
  List<CommentListItem> comments = [];
  List<FavoriteListItem> favorites = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo().then((_) {
      fetchPostDetails();
      fetchComments();
      fetchFavorits();
    });
  }

  Future<void> fetchPostDetails() async {
    final String uri = 'http://10.0.2.2:4000/api/v1/recipe/recipe-board/${widget.recipeId}';
    try {
      http.Response response = await http.get(Uri.parse(uri), headers: {
        'Authorization': 'Bearer $_jwtToken', // 인증 헤더 추가
      });
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
        json.decode(utf8.decode(response.bodyBytes));
        print("${responseData}");
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

  Future<void> toggleFavorite() async {
    if (isUpdatingFavorite) return; // 이미 업데이트 중이면 아무 작업도 하지 않음
    setState(() {
      isUpdatingFavorite = true;
    });
    final String uri =
        'http://10.0.2.2:4000/api/v1/recipe/recipe-board/${widget.recipeId}/favorite';
    try {
      final Map<String, dynamic> requestBody = {
        'email': _userEmail, // 사용자 이메일 추가
      };
      http.Response response = await http.put(
        Uri.parse(uri),
        headers: {
          'Authorization': 'Bearer $_jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      if (response.statusCode == 200) {
        setState(() {
          isFavorite = !isFavorite;
          isUpdatingFavorite = false;
        });
        await fetchFavorits();
      } else {
        setState(() {
          isUpdatingFavorite = false;
        });
      }
    } catch (error) {
      setState(() {
        isUpdatingFavorite = false;
      });
    }
  }
  Future<void> fetchFavorits() async {
  final String uri = 'http://10.0.2.2:4000/api/v1/recipe/recipe-board/${widget.recipeId}/favorite-list';
  try {
    http.Response response = await http.get(Uri.parse(uri), headers: {
      'Authorization': 'Bearer $_jwtToken',
    });
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData =
      json.decode(utf8.decode(response.bodyBytes));
      if (responseData['favoriteList'] != null &&
          responseData['favoriteList'] is List) {
        List<FavoriteListItem> fetchFavorits = [];
        for (var favoriteData in responseData['favoriteList']) {
          FavoriteListItem favorite = FavoriteListItem.fromJson(favoriteData);
          fetchFavorits.add(favorite);
        }
        setState(() {
          favorites = fetchFavorits;
          favoriteCount = favorites.length;
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

  Future<void> postComment(String content) async {
    final String uri =
        'http://10.0.2.2:4000/api/v1/recipe/recipe-board/${widget.recipeId}/comment';
    try {
      final Map<String, dynamic> requestBody = {
        'content': content, // Add the comment text
      };
      http.Response response = await http.post(
        Uri.parse(uri),
        headers: {
          'Authorization': 'Bearer $_jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      if (response.statusCode == 200) {
        setState(() {
          commentCount++;
        });
        fetchComments();
      } else {
        print('Failed to post comment: ${response.statusCode}');
      }
    } catch (error) {
      print('Failed to post comment: $error');
    }
  }
  Future<void> fetchComments() async {
    final String uri = 'http://10.0.2.2:4000/api/v1/recipe/recipe-board/${widget.recipeId}/comment-list';
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
            commentCount = comments.length;
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
  Future<void> deleteComment(int commentNumber) async {
    if (_jwtToken == null) {
      print('JWT token is null');
      return;
    }
    final String uri =
        'http://10.0.2.2:4000/api/v1/recipe/recipe-board/$boardNumber/$commentNumber';
    try {
      http.Response response = await http.delete(
        Uri.parse(uri),
        headers: {
          'Authorization': 'Bearer $_jwtToken', // Add authorization header
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          commentCount--;
          comments.removeWhere((comment) => comment.commentNumber == commentNumber);
        });
        fetchComments(); // Fetch comments again to update the UI
      }
    } catch (error) {
      print('Failed to delete comment: $error');
    }
  }
  Future<void> editComment(int commentNumber, String newContent) async {
    final String uri = 'http://10.0.2.2:4000/api/v1/recipe/recipe-board/$boardNumber/$commentNumber';
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
                onPressed: ()  {
                  Navigator.of(context).pop();
                  deleteRecipeBoard();
                },),],);});}

  Future<void> deleteRecipeBoard() async {
    final String uri = 'http://10.0.2.2:4000/api/v1/recipe/recipe-board/${widget.recipeId}';
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
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 삭제에 실패했습니다.')),
      );
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
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {

            },
          ),
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
        padding: const EdgeInsets.all(0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (imageUrls.isNotEmpty)
              Column(
                children: [
                  for (String imageUrl in imageUrls)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0.5),
                      child: Container(
                        width: 450,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          border: Border.all(
                            color: Colors.black,
                            width: 0.3,
                          ),
                          image: DecorationImage(
                            image: imageUrl.startsWith('http')
                                ? NetworkImage(imageUrl)
                                : FileImage(File(imageUrl))
                            as ImageProvider,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Text(content,    style: TextStyle(fontSize: 22),  ),
            const SizedBox(height: 15),
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
            SizedBox(height: 5,     ),
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
                            formatDatetime(comments[index].writeDatetime ?? ''), // 작성 시간
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
                      postComment(comment);
                      _commentController.clear();
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
