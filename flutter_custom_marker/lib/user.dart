import 'package:google_maps_flutter/google_maps_flutter.dart';

class User {
  String id;
  LatLng latLng;
  String profileImage;

  User({
    this.id,
    this.latLng,
    this.profileImage,
  });
}