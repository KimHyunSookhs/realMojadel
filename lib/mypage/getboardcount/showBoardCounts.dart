import 'package:flutter/material.dart';
import 'package:mojadel2/mypage/getboardcount/getBoardCount.dart';
import 'package:mojadel2/mypage/getboardcount/getRecipeBoardCount.dart';
import 'package:mojadel2/mypage/getboardcount/getTradeBoardCount.dart';

class ShowBoardCounts extends StatelessWidget {
  final String? userEmail;
  final String? jwtToken;
  final String? nickname;
  ShowBoardCounts({this.userEmail, this.jwtToken, this.nickname});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(width: 5),
          Row(
            children: [
              Text('중고거래 ', style: TextStyle(fontSize: 10),),
              FutureBuilder<int?>(
                future: getUserTradePostsCount(userEmail ?? '', jwtToken ?? '', nickname),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('0', style: TextStyle(fontSize: 10),);
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    final int? postsCount = snapshot.data;
                    return Text(postsCount != null ? '$postsCount' : '0', style: TextStyle(fontSize: 10),);
                  }
                },
              ),
              Text('개', style: TextStyle(fontSize: 10),),
              VerticalDivider(
                width: 12,
                thickness: 0.6,
                color: Colors.black,
              ),
              Text('요모조모 ', style: TextStyle(fontSize: 10),),
              FutureBuilder<int?>(
                future: getUserPostsCount(userEmail ?? '', jwtToken ?? '', nickname),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('0', style: TextStyle(fontSize: 10),);
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    final int? postsCount = snapshot.data;
                    return Text(postsCount != null ? '$postsCount' : '0', style: TextStyle(fontSize: 10),);
                  }
                },
              ),
              Text('개', style: TextStyle(fontSize: 10),),
              VerticalDivider(
                width: 12,
                thickness: 0.6,
                color: Colors.black,
              ),
              Text('레시피 ', style: TextStyle(fontSize: 10),),
              FutureBuilder<int?>(
                future: getUserRecipePostsCount(userEmail ?? '', jwtToken ?? '', nickname),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('0', style: TextStyle(fontSize: 10),);
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    final int? postsCount = snapshot.data;
                    return Text(postsCount != null ? '$postsCount' : '0', style: TextStyle(fontSize: 10),);
                  }
                },
              ),
              Text('개', style: TextStyle(fontSize: 10),),
              SizedBox(width: 5),
            ],
          ),
        ],
      ),
    );
  }
}
