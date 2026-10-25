import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class LocationService {
  Future<Position> getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Le service de localisation est désactivé.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Les permissions de localisation sont refusées.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Les permissions de localisation sont définitivement refusées.';
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    final apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'][0]['formatted_address'];
    } else {
      throw 'Erreur lors de la récupération de l\'adresse.';
    }
  }
}