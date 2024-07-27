import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mojadel2/colors/colors.dart';
import 'package:mojadel2/homepage/main_homepage.dart';
import 'package:mojadel2/mypage/mypage.dart';
import 'package:flutter/widgets.dart';
import '../NearPlace/ChatBoard.dart';
import '../yomojomo/messageboard.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:flutter/cupertino.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static final XFile defaultImage = XFile('');

  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget> [
    MainhomePage(),
    ChatBoardPage(sellerNickname: '현수',),
    MessageBoard(),
    Text('레시피'),
    MyPageSite(),
  ];

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
            selectedItemColor: AppColors.mintgreen,
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