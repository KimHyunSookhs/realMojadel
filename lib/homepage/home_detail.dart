import 'package:flutter/material.dart';
import 'package:mojadel2/RecipePage/RecipePage.dart';
import 'package:mojadel2/TradePage/TradePage.dart';
import 'package:mojadel2/mypage/mypage.dart';
import 'package:flutter/widgets.dart';
import '../TradePage/ChatBoard/ChatBoard.dart';
import '../yomojomo/messageboard.dart';
import 'package:flutter/cupertino.dart';

class HomePage extends StatefulWidget {
  final int selectedIndex; // 선택된 인덱스를 저장할 변수

  const HomePage({super.key, this.selectedIndex = 0}); //

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  late int _selectedIndex;
  static  List<Widget> _widgetOptions = <Widget> [
    MainhomePage(),
    ChatBoardPage(),
    MessageBoard(),
    RecipePage(),
    MyPageSite(),
  ];
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex; // 전달된 인덱스를 사용
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          body: Center(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey,
            currentIndex: _selectedIndex,
            items:  <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
              BottomNavigationBarItem(icon: Icon( CupertinoIcons.chat_bubble_2_fill), label: '채팅방'),
              BottomNavigationBarItem(icon: Icon(Icons.chat_rounded), label: '요모조모'),
              BottomNavigationBarItem(icon: Icon(Icons.dinner_dining), label: '레시피'),
              BottomNavigationBarItem(
                  icon: Image.asset('assets/Icon/houseimg.png',width: 30,height: 30,),
                  activeIcon: Image.asset('assets/Icon/houseimg.png',width: 30,height: 30,),
                  label: '마이페이지'),
            ],
            onTap: (int index){
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        )
    );
  }
}