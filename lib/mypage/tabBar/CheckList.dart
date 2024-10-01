import 'package:flutter/material.dart';

class Checklist extends StatefulWidget {
  const Checklist({Key? key}) : super(key: key);

  @override
  _ChecklistState createState() => _ChecklistState();
}

class _ChecklistState extends State<Checklist> {
  // 체크박스 상태를 관리할 변수들
  Map<String, bool> structureChecklist = {
    '벽이나 천장에 균열이 있는가?': false,
    '창문과 문이 제대로 열리고 닫히는가?': false,
    '각 방에 자연 채광이 충분한가?': false,
    '방음 효과가 충분한가?': false,
  };

  Map<String, bool> plumbingChecklist = {
    '욕실이나 주방에 누수가 있는가?': false,
    '수도꼭지와 샤워의 수압이 괜찮은가?': false,
    '온수기가 제대로 작동하는가?': false,
  };

  Map<String, bool> electricalChecklist = {
    '모든 전기 콘센트가 작동하는가?': false,
    '모든 방에 충분한 조명이 있는가?': false,
    '차단기 상태가 괜찮은가?': false,
  };

  Map<String, bool> safetyChecklist = {
    '작동하는 연기 감지기가 있는가?': false,
    '창문과 문의 잠금장치가 안전한가?': false,
    '화재 대피 계획이나 소화기가 있는가?': false,
  };

  Map<String, bool> pestsChecklist = {
    '해충(벌레, 쥐 등)의 흔적이 있는가?': false,
    '곰팡이나 물 손상의 흔적이 있는가?': false,
  };

  Map<String, bool> appliancesChecklist = {
    '주방 가전(오븐, 냉장고, 식기세척기)이 작동하는가?': false,
    '세탁기가 작동하는가?': false,
  };

  Map<String, bool> nearPlaceChecklist = {
    '주변이 조용하고 안전한가?': false,
    '주차 공간이나 대중교통 접근성이 좋은가?': false,
    '가까운 곳에 편의시설(마트, 공원)이 있는가?': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('자취방 체크리스트', style: TextStyle(
          fontSize: 24, fontWeight:FontWeight.w500,
        ),),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildChecklistSection('구조 점검', structureChecklist),
              const SizedBox(height: 20),
              buildChecklistSection('배관 상태', plumbingChecklist),
              const SizedBox(height: 20),
              buildChecklistSection('전기 시스템', electricalChecklist),
              const SizedBox(height: 20),
              buildChecklistSection('안전 기능', safetyChecklist),
              const SizedBox(height: 20),
              buildChecklistSection('해충 및 곰팡이', pestsChecklist),
              const SizedBox(height: 20),
              buildChecklistSection('가전제품', appliancesChecklist),
              const SizedBox(height: 20),
              buildChecklistSection('주변 환경', nearPlaceChecklist),
            ],
          ),
        ),
      ),
    );
  }

  // 체크리스트 섹션 빌더 함수
  Widget buildChecklistSection(String title, Map<String, bool> checklist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        ...checklist.keys.map((item) => CheckboxListTile(
          title: Text(item, style: TextStyle(fontSize: 13),),
          value: checklist[item],
          onChanged: (bool? value) {
            setState(() {
              checklist[item] = value ?? false;
            });
          },
        )),
      ],
    );
  }
}
