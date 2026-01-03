import 'package:geolocator/geolocator.dart';

class LocationService {

  // Retrieves the user's current GPS location with permission handling
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Checks whether location services are enabled on the device
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("Location services are disabled");
    }

    // Checks and requests location permission if needed
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permission denied");
      }
    }

    // Handles permanently denied permissions
    if (permission == LocationPermission.deniedForever) {
      return Future.error("Location permission denied permanently.");
    }

    // Returns the current device location with high accuracy
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
