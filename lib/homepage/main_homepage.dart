import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mojadel2/registar/registar_page.dart';
import 'package:mojadel2/sample/things_sample.dart';
import '../colors/colors.dart';

class MainhomePage extends StatefulWidget {
  const MainhomePage({Key? key}) : super(key: key);
  @override
  State<MainhomePage> createState() => _MainhomePageState();
}

class _MainhomePageState extends State<MainhomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text('화정동', style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w300,
            color: Colors.black
        ),),
        backgroundColor: AppColors.mintgreen,
        actions: [
          IconButton(
            onPressed: (){},
            icon: Icon(Icons.search),
            color: Colors.black,),
          IconButton(
            onPressed: (){},
            icon: Icon(Icons.notifications),
            color: Colors.black,),
          IconButton(
            onPressed: (){},
            icon: Icon(Icons.menu),
            color: Colors.black,)
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(padding: EdgeInsets.fromLTRB(0, 10, 0, 0)),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {},
                  child: Text('중고거래'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('배달음식'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('운동모임'),
                ),
              ],
            ),
          ),
          Padding(padding: EdgeInsets.fromLTRB(0, 10, 0, 0)),
          Expanded(
              child: ListView.separated(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Container(
                    height: 140.0,
                    child: Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: SizedBox(
                            width: 150,
                            height: 300,
                            child: Image.asset(
                              items[index]['imagePath']!,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: '${items[index]['name']}\n',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: '${items[index]['location']} ${items[index]['time']}\n',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              TextSpan(
                                text: '${items[index]['price']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green, // AppColors.mintgreen 대신 Colors.green을 사용했습니다. 필요에 따라 적절한 색상 코드로 수정하세요.
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (context, index) => Divider(),
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.mintgreen,
        shape: CircleBorder(side: BorderSide(color: AppColors.mintgreen)),
        child: Icon(Icons.add),
        onPressed: (){
          Navigator.push(context,
              MaterialPageRoute(builder: (context)=> RegistarPage(key: UniqueKey(),
                selectedPlaceName: "선택된 장소 이름",
                textController: TextEditingController(), // 적절한 초기화 필요
                textController2: TextEditingController(), // 적절한 초기화 필요
                priceController: TextEditingController(), // 적절한 초기화 필요
                image: XFile(""), // 적절한 초기화 필요
                selectedOption: "",
              )),);
        },
      ),
    );
  }
}