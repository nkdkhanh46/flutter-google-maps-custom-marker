import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_custom_marker/user.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LatLng _initialPosition;
  Set<Marker> _markers = Set();
  List<User> _users = List();
  List<GlobalKey> _markerIconKeys = List();
  Set<String> renderedMarkers = Set();

  @override
  void initState() {
    _getUsers();
    super.initState();
  }

  void _getUsers() {
    User user1 = User(
      id: Uuid().v4(),
      latLng: LatLng(10.801401, 106.711323),
      profileImage: 'https://64.media.tumblr.com/6de9ea0bc9b0ec0ca8b4ebfca27552d6/3103a523cb3b45c8-93/s128x128u_c1/eecdbc52e53603ab64218f5bc56f669e64ed4cad.jpg',
    );
    _users.add(user1);
    _initialPosition = user1.latLng;

    _users.add(
      User(
        id: Uuid().v4(),
        latLng: LatLng(10.795993, 106.703688),
        profileImage: 'https://av.olm.vn/images/avt/avt0/avt1171160_256by256.jpg',
      )
    );
    _users.forEach((user) {
      _markerIconKeys.add(GlobalKey());
    });
    setState(() { });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_users.isNotEmpty) _buildMarkerIconsContainer(),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildMarkerIconsContainer() {
    return Column(
      children: _buildMarkerIcons(),
    );
  }

  List<Widget> _buildMarkerIcons() {
    List<Widget> icons = List<Widget>();
    for (int i=0; i<_users.length; i++) {
      icons.add(_buildMarkerIcon(i));
    }
    return icons;
  }

  Widget _buildMarkerIcon(int index) {
    User user = _users[index];
    var image = NetworkImage(user.profileImage);

    image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((info, call) {
        _addMarker(user, index);
      }),
    );
    return RepaintBoundary(
      key: _markerIconKeys[index],
      child: Material(
        shape: CircleBorder(),
        clipBehavior: Clip.hardEdge,
        child: Image(
          image: image,
          fit: BoxFit.contain,
          width: 40,
          height: 40,
        ),
      ),
    );
  }

  void _addMarker(User user, int index) async {
    Future.delayed(Duration(seconds: 1)).then((value) async {
      if (renderedMarkers.contains(user.id)) return;

      var markerBytes = await _getMarkerIconBytes(_markerIconKeys[index]);
      if (markerBytes == null) return;

      _markers.add(
          Marker(
              markerId: MarkerId(user.id),
              position: user.latLng,
              icon: BitmapDescriptor.fromBytes(markerBytes)
          )
      );
      renderedMarkers.add(user.id);
      setState(() {});
    });
  }

  Future<Uint8List> _getMarkerIconBytes(GlobalKey markerKey) async {
    if (markerKey.currentContext == null) return null;

    RenderRepaintBoundary boundary = markerKey.currentContext.findRenderObject();
    var image = await boundary.toImage(pixelRatio: 2.0);
    ByteData byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData.buffer.asUint8List();
  }

  Widget _buildBody() {
    if (_initialPosition == null) return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Center(
        child: Text('Loading...')
      ),
    );

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _initialPosition,
        zoom: 15
      ),
      markers: _markers,
    );
  }
}
