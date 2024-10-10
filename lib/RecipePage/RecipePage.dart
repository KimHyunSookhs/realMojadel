import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mojadel2/RecipePage/DetailRecipePage.dart';
import 'package:mojadel2/RecipePage/GeneralRecipeBoard/GeneralRecipePage.dart';
import 'package:mojadel2/RecipePage/RecipeBoardList/RecipeBoardListItem.dart';
import 'package:mojadel2/RecipePage/RecipeRegistar.dart';
import 'package:mojadel2/colors/colors.dart';
import 'ConvenienceRecipeBoard/ConvenienceRecipePage.dart';

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});
  @override
  State<RecipePage> createState() => _RecipePageState();
}
class RecipeGrid extends StatefulWidget {
  final List<RecipeBoardListItem> recipeList;
  final StreamController<List<RecipeBoardListItem>> streamController;
  final VoidCallback onRefresh;

  const RecipeGrid({
    Key? key,
    required this.recipeList,
    required this.streamController,
    required this.onRefresh,
  }) : super(key: key);

  @override
  _RecipeGridState createState() => _RecipeGridState();
}

class _RecipePageState extends State<RecipePage> {
  List<RecipeBoardListItem> _generalRecipes = [];
  List<RecipeBoardListItem> _convenienceStoreRecipes = [];
  List<RecipeBoardListItem> _searchResults = [];
  late StreamController<List<RecipeBoardListItem>> _generalRecipeStreamController;
  late StreamController<List<RecipeBoardListItem>> _convenienceStoreRecipeStreamController;
  bool _isMounted = false;
  bool _isSearching = false;
  String? _jwtToken;

  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _generalRecipeStreamController = StreamController<List<RecipeBoardListItem>>.broadcast();
    _convenienceStoreRecipeStreamController = StreamController<List<RecipeBoardListItem>>.broadcast();
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
    try {
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
    } catch (error) {    }
  }

  Future<void> fetchRecipeBoard(int type, StreamController<List<RecipeBoardListItem>> streamController, Function(List<RecipeBoardListItem>) onSuccess) async {
    final String uri = 'http://52.79.217.191:4000/api/v1/recipe/recipe-board/latest-list/$type';
    try {
      http.Response response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        if (_isMounted && responseData['recipelatestList'] != null) {
          if (responseData['recipelatestList'] is List) {
            final List<dynamic> messageList = responseData['recipelatestList'];
            List<RecipeBoardListItem> messages = _parseRecipeBoardItems(messageList);
            if (_isMounted) {
              onSuccess(messages);
              streamController.add(messages);
            }
          }
        } else {
          print('recipelatestList가 null입니다.');
        }
      }
    } catch (error) {
      if (_isMounted) {
        print('메시지 가져오기 실패: $error');
      }
    }
  }

  Future<void> _performSearch(String searchWord) async {
    final String uri = 'http://52.79.217.191:4000/api/v1/recipe/recipe-board/search-list/$searchWord';
    try {
      http.Response response = await http.get(Uri.parse(uri), headers: {
        'Authorization': 'Bearer $_jwtToken',
      });
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));
        if (responseData['searchList'] != null) {
          final List<dynamic> searchList = responseData['searchList'];
          List<RecipeBoardListItem> searchResults = _parseRecipeBoardItems(searchList);
          setState(() {
            _searchResults = searchResults;
            _isSearching = true;
          });
        }
      }
    } catch (error) {
      print('검색 실패: $error');
    }
  }
  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        List<String> contentLines = item.content.split('\n');
        String mainContent = contentLines.isNotEmpty ? contentLines[0] : '';
        return GestureDetector(
          onTap: () async {
            final success = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailRecipePage(
                  recipeId: item.boardNumber,
                ),
              ),
            );
            if (success == true) {
              _performSearch(_searchController.text);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(File(item.boardTitleImage.isNotEmpty ? item.boardTitleImage[0] : '')),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3),
                      Text(
                        mainContent,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.favorite, size: 16, color: Colors.red),
                          SizedBox(width: 4),
                          Text('${item.favoriteCount}'),
                          SizedBox(width: 12),
                          Icon(Icons.comment, size: 16, color: Colors.blue),
                          SizedBox(width: 4),
                          Text('${item.commentCount}'),
                          SizedBox(width: 20),
                        ],
                      ),
                      SizedBox(height: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 0.3),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_sharp, size: 14,),
                            SizedBox(width: 4,),
                            Text(
                              '${item.cookingTime}',
                              style: TextStyle(
                                fontSize: 11,
                              ),
                            ),
                            Text('분', style: TextStyle(
                              fontSize: 11,
                            ),),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<RecipeBoardListItem> _parseRecipeBoardItems(List<dynamic> dataList) {
    List<RecipeBoardListItem> messages = [];
    for (var data in dataList) {
      List<String> boardTitleImageList = _parseImageList(data['boardTitleImage']);
      messages.add(
        RecipeBoardListItem(
          boardNumber: data['boardNumber'],
          title: data['title'],
          content: data['content'],
          boardTitleImage: boardTitleImageList,
          favoriteCount: data['favoriteCount'] ?? 0,
          commentCount: data['commentCount'] ?? 0,
          viewCount: data['viewCount'] ?? 0,
          writeDatetime: data['writeDatetime'] ?? '',
          writerNickname: data['writerNickname'],
          writerProfileImage: data['writerProfileImage']?? '',
          type: data['type'],
          cookingTime: data['cookingTime'],
          step1_content: data['step1_content']??'',
          step2_content: data['step2_content']??'',
          step3_content: data['step3_content']??'',
          step4_content: data['step4_content']??'',
          step5_content: data['step5_content']??'',
          step6_content: data['step6_content']??'',
          step7_content: data['step7_content']??'',
          step8_content: data['step8_content']??'',
          step1_image: data['step1_image']??'',
          step2_image: data['step2_image']??'',
          step3_image: data['step3_image']??'',
          step4_image: data['step4_image']??'',
          step5_image: data['step5_image']??'',
          step6_image: data['step6_image']??'',
          step7_image: data['step7_image']??'',
          step8_image: data['step8_image']??'',
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
            ? _buildSearchResults()
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
            RecipeGrid(
              recipeList: _generalRecipes,
              streamController: _generalRecipeStreamController,
              onRefresh: fetchRecipes,
            ),
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
            RecipeGrid(
              recipeList: _convenienceStoreRecipes,
              streamController: _convenienceStoreRecipeStreamController,
              onRefresh: fetchRecipes,
            ),
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

class _RecipeGridState extends State<RecipeGrid> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RecipeBoardListItem>>(
      stream: widget.streamController.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            widget.recipeList.isEmpty) {
          return Center(child:Text('게시글이 없습니다.'));
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
                      builder: (context) =>
                          DetailRecipePage(
                            recipeId: message.boardNumber,
                          ),
                    ),
                  );
                  if (success == true) {
                    widget.onRefresh();
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 160,
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 0.3),
                        image: message.boardTitleImage
                            .isNotEmpty
                            ? DecorationImage(
                          image: FileImage(File(message.boardTitleImage[0])),
                          fit: BoxFit.fill,
                        )
                            : null, // Handle empty images
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      message.title,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
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
