import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mojadel2/Config/ConfirmDelete.dart';
import 'package:mojadel2/RecipePage/EditRecipe.dart';
import 'package:mojadel2/RecipePage/viewCount.dart';
import 'package:mojadel2/colors/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  int? boardNumber;
  String title = '';
  String content = '';
  String boardImageList = '';
  String writeDatetime = '';
  String writerEmail = '';
  String writerNickname = '';
  String? writerProfileImageUrl;
  int type = 0;
  int cookingTime = 0;
  String step1_content = '';  String step2_content = '';
  String step3_content = '';  String step4_content = '';
  String step5_content = '';  String step6_content = '';
  String step7_content = '';  String step8_content = '';
  String step1_image = '';  String step5_image = '';
  String step6_image = '';  String step2_image = '';
  String step3_image = '';  String step7_image = '';
  String step4_image = '';  String step8_image = '';
  bool isLoading = true;
  int favoriteCount = 0;
  String? _userEmail;
  String? _jwtToken;
  bool isFavorite = false;
  bool isUpdatingFavorite = false;
  String? _profileImageUrl;
  String? _nickname;
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
      increaseRecipeViewCount(widget.recipeId, _jwtToken!);
    });
  }

  Future<void> fetchPostDetails() async {
    final String uri = 'http://10.0.2.2:4000/api/v1/recipe/recipe-board/${widget.recipeId}';
    try {
      http.Response response = await http.get(Uri.parse(uri), headers: {
        'Authorization': 'Bearer $_jwtToken',
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
          type = responseData['type'];
          boardNumber = responseData['boardNumber'];
          isLoading = false;
          isFavorite = responseData['isFavorite'] ?? false;
          writerProfileImageUrl = responseData['writerProfileImage'];
          boardImageList = responseData['boardImageList'] != null
              ? json.encode(responseData['boardImageList'])
              : '';
          cookingTime = responseData['cookingTime'];
          step1_content = responseData['step1_content'] ?? '';
          step1_image = responseData['step1_image'] != null
              ? responseData['step1_image']
              : '';
          step2_content = responseData['step2_content'] ?? '';
          step2_image = responseData['step2_image'] != null
              ? responseData['step2_image']
              : '';
          step3_content = responseData['step3_content'] ?? '';
          step3_image = responseData['step3_image'] != null
              ? responseData['step3_image']
              : '';
          step4_content = responseData['step4_content'] ?? '';
          step4_image = responseData['step4_image'] != null
              ? responseData['step4_image']
              : '';
          step5_content = responseData['step5_content'] ?? '';
          step5_image = responseData['step5_image'] != null
              ? responseData['step5_image']
              : '';
          step6_content = responseData['step6_content'] ?? '';
          step6_image = responseData['step6_image'] != null
              ? responseData['step6_image']
              : '';
          step7_content = responseData['step7_content'] ?? '';
          step7_image = responseData['step7_image'] != null
              ? responseData['step7_image']
              : '';
          step8_content = responseData['step8_content'] ?? '';
          step8_image = responseData['step8_image'] != null
              ? responseData['step8_image']
              : '';
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
    if (isUpdatingFavorite) return;
    setState(() {
      isUpdatingFavorite = true;
    });
    final String uri =
        'http://10.0.2.2:4000/api/v1/recipe/recipe-board/${widget.recipeId}/favorite';
    try {
      final Map<String, dynamic> requestBody = {
        'email': _userEmail,
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
        'content': content,
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
        }
      }
    } catch (error) {
      print('Failed to fetch comments: $error');
    }
  }
  Future<void> deleteComment(int commentNumber) async {
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
        fetchComments();
      }
    } catch (error) {
      print('Failed to delete comment: $error');
    }
  }
  Future<void> editComment(int commentNumber, String newContent) async {
    final String uri = 'http://10.0.2.2:4000/api/v1/recipe/recipe-board/$boardNumber/$commentNumber';
    try {
      final Map<String, dynamic> requestBody = {
        'content': newContent,
      };
      http.Response response = await http.patch(
        Uri.parse(uri),
        headers: {
          'Authorization': 'Bearer $_jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      if (response.statusCode == 200) {
        fetchComments();
      } else {
        print('Failed to edit comment: ${response.statusCode}');
      }
    } catch (error) {
      print('Failed to edit comment: $error');
    }
  }

  Future<void> deleteRecipeBoard() async {
    final String uri = 'http://10.0.2.2:4000/api/v1/recipe/recipe-board/${widget.recipeId}';
    try {
      http.Response response = await http.delete(
        Uri.parse(uri),
        headers: {
          'Authorization': 'Bearer $_jwtToken',
        },
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시글이 삭제되었습니다.')),
        );
        Navigator.pop(context, true);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 삭제에 실패했습니다.')),
      );
    }
  }

  void editRecipeBoard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRecipePage(
          recipeId: widget.recipeId,
          initialTitle: title,
          initialContent: content,
          boardImageList: parseBoardImageList(boardImageList),
          initialType: type,
          initialCookingTime : cookingTime,
          step1_content: step1_content, step2_content :step2_content,
          step3_content: step3_content, step4_content: step4_content,
          step5_content: step5_content, step7_content: step7_content,
          step6_content: step6_content, step8_content: step8_content,
          step1_image: step1_image,
          step2_image: step2_image,
          step3_image: step3_image,
          step4_image: step4_image,
          step5_image: step5_image,
          step6_image: step6_image,
          step7_image: step7_image,
          step8_image: step8_image,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> imageUrls = parseBoardImageList(boardImageList);
    List<String> contentParts = content.split('\n\n재료:\n');
    String mainContent = contentParts.isNotEmpty ? contentParts[0] : '';
    List<String> ingredients = contentParts.length > 1 ? contentParts[1].split('\n') : [];
    List<String> stepContents = [
      step1_content, step2_content, step3_content, step4_content,
      step5_content, step6_content, step7_content, step8_content
    ];
    List<String> stepImages = [
      step1_image, step2_image, step3_image, step4_image,
      step5_image, step6_image, step7_image, step8_image
    ];
    bool isOwner = _nickname == writerNickname;
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
        actions: isOwner
            ? [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              editRecipeBoard();
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return ConfirmDelete(
                        title: '게시글 삭제',
                        content: '정말로 이 게시글을 삭제하시겠습니까?',
                        onDelete: deleteRecipeBoard
                    );
                  }
              );
            },
          ),
        ]
            : [],
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
                          borderRadius: BorderRadius.circular(12.0),
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
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Colors.grey.shade300, // 테두리 색상
                  width: 1.0, // 테두리 두께
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    mainContent,
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 18,),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_sharp, size: 18,color: Colors.grey,),
                      Text(
                        '$cookingTime', style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                      ),
                      Text('분이내', style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),)
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '재료',  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  ),
                  Divider(),
                  if (ingredients.isNotEmpty)
                    for (String ingredient in ingredients)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                ingredient.split(' - ')[0],
                                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                              ),
                            ),
                            Text(
                              ingredient.split(' - ')[1],
                              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                            ),
                            SizedBox(width: 100,)
                          ],
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '요리 순서',  style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      ),
                    ],
                  ),
                  Divider(),
                  for (int i = 0; i < stepContents.length; i++)
                    if (stepContents[i].isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  '${i + 1}. ${stepContents[i]}',
                                  style: TextStyle(fontSize: 13, color: Colors.black),
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (stepImages[i].isNotEmpty)
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(12.0),
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 0.3,
                                    ),
                                    image: DecorationImage(
                                      image: stepImages[i].startsWith('http')
                                          ? NetworkImage(stepImages[i])
                                          : FileImage(File(stepImages[i])) as ImageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      )
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(width: 15),
                Row(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '$favoriteCount',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(width: 12),
                    Icon(
                      Icons.comment,
                      color: Colors.black,
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '$commentCount',
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
                Expanded(child: Container()),
                ElevatedButton(
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
                SizedBox(width: 15,)
              ],
            ),
            SizedBox(height: 5),
            const Divider(height: 20),
            Align(
              alignment: Alignment.centerLeft,
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
                        comments[index].nickname ?? '',
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
                            color: Colors.black,
                            width: 0.5,
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
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
            ),
          ],
        ),
      ),
    );
  }
}
