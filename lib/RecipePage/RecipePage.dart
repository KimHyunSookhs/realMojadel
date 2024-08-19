import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mojadel2/RecipePage/DetailRecipePage.dart';
import 'package:mojadel2/RecipePage/GeneralRecipeBoard/GeneralRecipePage.dart';
import 'package:mojadel2/RecipePage/RecipeBoardList/RecipeBoardListItem.dart';
import 'package:mojadel2/RecipePage/RecipeRegistar.dart';
import 'package:mojadel2/colors/colors.dart';
import '../Config/ParseBoardImage.dart';
import 'ConvenienceRecipeBoard/ConvenienceRecipePage.dart';

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});
  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  List<RecipeBoardItem> _generalRecipes = [];
  List<RecipeBoardItem> _convenienceStoreRecipes = [];
  List<RecipeBoardItem> _searchResults = [];
  late StreamController<List<RecipeBoardItem>> _generalRecipeStreamController;
  late StreamController<List<RecipeBoardItem>> _convenienceStoreRecipeStreamController;
  bool _isMounted = false;
  bool _isSearching = false;
  String? _jwtToken;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _generalRecipeStreamController = StreamController<List<RecipeBoardItem>>.broadcast();
    _convenienceStoreRecipeStreamController = StreamController<List<RecipeBoardItem>>.broadcast();
    fetchRecipes();
  }

  @override
  void dispose() {
    _isMounted = false;
    _generalRecipeStreamController.close();
    _convenienceStoreRecipeStreamController.close();
    super.dispose();
  }

  Future<void> fetchRecipes() async {
    await Future.wait([
      fetchRecipeBoard(0, _generalRecipeStreamController, (recipes) {
        setState(() {
          _generalRecipes = recipes;
        });
      }),
      fetchRecipeBoard(1, _convenienceStoreRecipeStreamController, (recipes) {
        setState(() {
          _convenienceStoreRecipes = recipes;
        });
      }),
    ]);
  }

  Future<void> fetchRecipeBoard(int type, StreamController<List<RecipeBoardItem>> streamController, Function(List<RecipeBoardItem>) onSuccess) async {
    final String uri = 'http://10.0.2.2:4000/api/v1/recipe/recipe-board/latest-list/$type';
    try {
      http.Response response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        if (_isMounted && responseData['recipelatestList'] != null) {
          if (responseData['recipelatestList'] is List) {
            final List<dynamic> messageList = responseData['recipelatestList'];
            List<RecipeBoardItem> messages = _parseRecipeBoardItems(messageList);
            if (_isMounted) {
              onSuccess(messages);
              streamController.add(messages);
            }
          } else {
            print('recipelatestList는 리스트가 아닙니다.');
          }
        } else {
          print('recipelatestList가 null입니다.');
        }
      } else {
        print('메시지 가져오기 실패: ${response.statusCode}');
      }
    } catch (error) {
      if (_isMounted) {
        print('메시지 가져오기 실패: $error');
      }
    }
  }

  Future<void> _performSearch(String searchWord) async {
    final String uri = 'http://10.0.2.2:4000/api/v1/recipe/recipe-board/search-list/$searchWord';
    try {
      http.Response response = await http.get(Uri.parse(uri), headers: {
        'Authorization': 'Bearer $_jwtToken',
      });
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        if (responseData['searchList'] != null) {
          final List<dynamic> searchList = responseData['searchList'];
          List<RecipeBoardItem> searchResults = _parseRecipeBoardItems(searchList);
          setState(() {
            _searchResults = searchResults;
            _isSearching = true;
          });
        } else {
          print('검색 결과가 없습니다.');
        }
      } else {
        print('검색 실패: ${response.statusCode}');
      }
    } catch (error) {
      print('검색 실패: $error');
    }
  }

  List<RecipeBoardItem> _parseRecipeBoardItems(List<dynamic> dataList) {
    List<RecipeBoardItem> messages = [];
    for (var data in dataList) {
      List<String> boardTitleImageList = _parseImageList(data['boardTitleImage']);
      List<String> writerProfileImage = _parseImageList(data['writerProfileImage']);
      messages.add(
        RecipeBoardItem(
            data['boardNumber'],
            data['title'],
            data['content'],
            boardTitleImageList,
            data['favoriteCount'] ?? 0,
            data['commentCount'] ?? 0,
            data['viewCount'] ?? 0,
            data['writeDatetime'] ?? '',
            data['writerNickname'],
            writerProfileImage
        ),
      );
    }
    return messages;
  }

  List<String> _parseImageList(dynamic imageList) {
    if (imageList == null) return [];
    if (imageList is String) return [imageList];
    return List<String>.from(imageList);
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchResults.clear();
      _searchController.clear();
      fetchRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '검색어를 입력하세요...',
            border: InputBorder.none,
          ),
          onSubmitted: (value) {
            _performSearch(value);
          },
        )
            : Text('레시피'),
        backgroundColor: AppColors.mintgreen,
        actions: _isSearching
            ? [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _stopSearch,
          ),
        ]
            : [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _startSearch,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: _isSearching && _searchResults.isNotEmpty
            ? ListView.builder(
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final item = _searchResults[index];
            return ListTile(
              leading: item.boardTitleImage.isNotEmpty
                  ? Image.file(File(item.boardTitleImage[0]))
                  : null,
              title: Text(item.title),
              subtitle: Text(item.content),
            );
          },
        )
            : ListView(
          children: [
            SectionHeader(title: '일반 레시피', onMorePressed: () async {
              final success = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GeneralRecipePage()),
              );
              if (success != null && success) {
                fetchRecipes();
              }
            }),
            SizedBox(height: 5),
            RecipeGrid(recipeList: _generalRecipes, streamController: _generalRecipeStreamController),

            SizedBox(height: 10),
            SectionHeader(title: '편의점 레시피', onMorePressed: () async {
              final success = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ConvenienceRecipePage()),
              );
              if (success != null && success) {
                fetchRecipes();
              }
            }),
            SizedBox(height: 5),
            RecipeGrid(recipeList: _convenienceStoreRecipes, streamController: _convenienceStoreRecipeStreamController),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.mintgreen,
        shape: CircleBorder(side: BorderSide(color: AppColors.mintgreen)),
        child: Icon(Icons.add),
        onPressed: () async {
          final success = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RecipeRegistar()),
          );
          if (success != null && success) {
            fetchRecipes();
          }
        },
      ),
    );
  }
}
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onMorePressed;

  const SectionHeader({
    Key? key,
    required this.title,
    required this.onMorePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(fontSize: 12),
          ),
          onPressed: onMorePressed,
          child: const Text('더보기'),
        ),
      ],
    );
  }
}
class RecipeGrid extends StatelessWidget {
  final List<RecipeBoardItem> recipeList;
  final StreamController<List<RecipeBoardItem>> streamController;

  const RecipeGrid({
    Key? key,
    required this.recipeList,
    required this.streamController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RecipeBoardItem>>(
      stream: streamController.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && recipeList.isEmpty) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('게시글이 없습니다.'));
        } else {
          final messages = snapshot.data ?? [];
          final displayedMessages = messages.take(4).toList();
          return GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 5,
              mainAxisSpacing: 1,
            ),
            itemCount: displayedMessages.length,
            itemBuilder: (context, index) {
              final message = displayedMessages[index];
              return GestureDetector(
                onTap: () async {
                  final success = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailRecipePage(
                        recipeId: message.boardNumber,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 180,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 0.5),
                        image: DecorationImage(
                          image: FileImage(File(message.boardTitleImage[0])),
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(message.title, style: TextStyle(fontSize: 15)),
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }
}