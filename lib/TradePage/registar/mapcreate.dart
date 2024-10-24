import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapCreate extends StatefulWidget {
  @override
  State<MapCreate> createState() => MapCreateState();
}

class MapCreateState extends State<MapCreate> {
  String _selectedPlaceName = '';
  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  LocationData? _currentLocation; // 현재 위치 정보를 저장할 변수
  Location location = Location(); // 위치 정보를 처리하는 객체

  // 지도 초기 위치 설정 (기본값)
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.38075861289008, 126.9286181012336),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // 위치 권한 요청 및 현재 위치 가져오기
  }

  // 현재 위치를 가져오는 함수
  Future<void> _getCurrentLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    // 위치 서비스 사용 가능 여부 확인
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    // 위치 권한 확인 및 요청
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // 현재 위치 가져오기
    _locationData = await location.getLocation();
    setState(() {
      _currentLocation = _locationData;
    });

    // 현재 위치로 지도 이동
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(_locationData.latitude!, _locationData.longitude!),
        zoom: 14.0,
      ),
    ));

    // 현재 위치에 마커 추가
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('current-location'),
          position: LatLng(_locationData.latitude!, _locationData.longitude!),
          infoWindow: InfoWindow(
            title: '현재 위치',
            snippet: '여기 있습니다!',
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        markers: _markers,
        onMapCreated: _onMapCreated,
        myLocationEnabled: true, // 사용자 위치 표시
        myLocationButtonEnabled: true, // 사용자 위치 버튼 활성화
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
  }

  void _showPlaceNameDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("장소명 입력"),
          content: TextField(
            onChanged: (value) {
              _selectedPlaceName = value;
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
