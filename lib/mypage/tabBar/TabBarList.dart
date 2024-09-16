import 'package:flutter/material.dart';
import 'package:mojadel2/mypage/tabBar/MyBoardContents.dart';
import 'package:mojadel2/mypage/tabBar/MyRecipeContents.dart';
import 'package:mojadel2/mypage/tabBar/MyTradeContents.dart';
import 'package:mojadel2/mypage/tabBar/TabbarName.dart';


const List<String> transactionTypes = ['중고거래', '공동구매'];
const List<String> checkTransaction = ['거래 중', '거래 완료'];

class TabBarUsingController2 extends StatefulWidget {
  const TabBarUsingController2({super.key});

  @override
  State<TabBarUsingController2> createState() => _TabBarUsingController2State();
}

class _TabBarUsingController2State extends State<TabBarUsingController2>
    with TickerProviderStateMixin {
  late final TabController tabController;

  String dropDownValue = transactionTypes.first;
  String checkDropDownValue = checkTransaction.first;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: TABS.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            child: TabBar(
              // TabBar 디자인(TabBar 스타일, 글씨 스타일, 액션 스타일, 정렬 등)
              unselectedLabelColor: Colors.grey,
              labelColor: Colors.black,
              labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
              labelPadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 3.0),
              overlayColor: const MaterialStatePropertyAll(Colors.white),
              indicatorColor: Colors.black,
              indicatorSize: TabBarIndicatorSize.tab,
              tabAlignment: TabAlignment.center,
              isScrollable: true,
              // TabBar의 tabController 입력
              controller: tabController,
              // TABS의 배열을 리스트형태로 맵핑하고, 각 탭에 라벨값을 텍스트 형태로 출력
              // 카테고리 이름
              tabs: TABS
                  .map(
                    (e) => Tab(
                  child: Text(e.label),
                ),
              )
                  .toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                SingleChildScrollView(
                  child: MyTradecontents(), // Only one instance here
                ),
                SingleChildScrollView(
                  child: Myboardcontents(), // Only one instance here
                ),
                SingleChildScrollView(
                  child: MyRecipecontents(), // Only one instance here
                ),
                ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text('D Item %index'),
                    );
                  },
                ),
                SingleChildScrollView(
                  child: Column(
                    children: List.generate(10, (index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('C Content $index'),
                      );
                    }),
                  ),
                ),
                SingleChildScrollView(
                  child: Column(
                    children: List.generate(10, (index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('C Content $index'),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}