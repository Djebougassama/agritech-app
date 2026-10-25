// import 'package:mockito/mockito.dart';
// import 'package:geolocator/geolocator.dart';
// import 'dart:math';

// // Création d'un mock de la classe Geolocator
// class MockGeolocator extends Mock implements Geolocator {}

// void main() {
//   final geolocator = MockGeolocator();

//   // Liste de quelques villes en Guinée avec leurs coordonnées
//   final villesGuinee = [
//     {"nom": "Conakry", "latitude": 9.6412, "longitude": -13.5784},
//     {"nom": "Kindia", "latitude": 10.0560, "longitude": -12.8658},
//     {"nom": "Labé", "latitude": 11.3182, "longitude": -12.2833},
//     {"nom": "Kankan", "latitude": 10.3854, "longitude": -9.3057},
//     {"nom": "Nzérékoré", "latitude": 7.7566, "longitude": -8.8176},
//     {"nom": "Fria", "latitude": 10.3662, "longitude": -13.5825},
//     {"nom": "Coyah", "latitude": 9.7064, "longitude": -13.3844},
//     {"nom": "Forécariah", "latitude": 9.4300, "longitude": -13.0881},
//     {"nom": "Kouroussa", "latitude": 10.6500, "longitude": -9.8833},
//     {"nom": "Boké", "latitude": 10.9322, "longitude": -14.2906},
//     {"nom": "Boffa", "latitude": 10.1833, "longitude": -14.0333},
//     {"nom": "Macenta", "latitude": 8.5435, "longitude": -9.4692},
//   ];

//   // Sélectionner une ville au hasard
//   final random = Random();
//   final villeChoisie = villesGuinee[random.nextInt(villesGuinee.length)];

//   // Simuler une réponse de l'API pour la localisation
//   when(geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high))
//       .thenAnswer((_) async => Position(
//             latitude: villeChoisie["latitude"] as double,
//             longitude: villeChoisie["longitude"] as double,
//             timestamp: DateTime.now(),
//             accuracy: 5.0,
//             altitude: 10.0,
//             heading: 0.0,
//             speed: 0.0,
//             speedAccuracy: 0.0,
//           ));

//   print("Localisation simulée : ${villeChoisie['nom']}, "
//       "Latitude: ${villeChoisie['latitude']}, "
//       "Longitude: ${villeChoisie['longitude']}");
// }
