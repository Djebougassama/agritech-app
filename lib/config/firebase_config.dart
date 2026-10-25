import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static Future<void> initialiserFirebase() async {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyAYuwDORNANDq0VLWt0WshY7dzy1CKAPGw",
        appId: "1:17971614829:ios:ce998a5dab082dee4f9b64",
        messagingSenderId: "17971614829",
        projectId: "agritech-platform",
        storageBucket: "agritech-platform.firebasestorage.app",
      ),
    );
  }
}