import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mojadel2/registar/registar_page.dart';

class MapCreate extends StatefulWidget {
  @override
  State<MapCreate> createState() => MapCreateState();
}

class MapCreateState extends State<MapCreate> {
  String _selectedPlaceName = '';
  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.637349311552, 126.83228024242),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        markers: _markers,
        onMapCreated: _onMapCreated,
      ),
      floatingActionButton: Stack(
        children: <Widget>[
          Positioned(
            left: 30, // 왼쪽에서부터의 거리
            bottom: 10, // 하단에서부터의 거리
            child: FloatingActionButton(
              onPressed: () {
                _showPlaceNameDialog();
              },
              // child: Text('선택 완료'),
              child: Icon(Icons.add_location_outlined),
              tooltip: '선택 완료',
            ),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('id-1'),
          position: LatLng(37.637349311552, 126.83228024242),
          infoWindow: InfoWindow(
            title: '우리 동네',
            snippet: '거래 희망 장소!',
          ),
        ),
      );
    });
  }

  void _showPlaceNameDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("장소명 입력"),
          content: TextField(
            onChanged: (value) {
              setState(() {
                _selectedPlaceName = value;
              });
            },
            decoration: InputDecoration(hintText: "장소명을 입력해주세요"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context, _selectedPlaceName);
              },
              child: Text('확인'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
          ],
        );
      },
    );
  }
}
