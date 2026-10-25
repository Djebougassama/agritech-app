// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'firebase_options.dart';
// import 'routes.dart';
// import 'package:intl/date_symbol_data_local.dart';


// // 🔔 Gestionnaire des notifications en arrière-plan
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   print("🔔 Notification en arrière-plan : ${message.messageId}");
// }

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );

//   // 🔧 Enregistrement du handler background (DOIT être ici)
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//   WidgetsFlutterBinding.ensureInitialized();
//   await initializeDateFormatting('fr_FR', null);

//   runApp(MyApp());
// }

// class MyApp extends StatefulWidget {
//   static _MyAppState? of(BuildContext context) =>
//       context.findAncestorStateOfType<_MyAppState>();

//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   bool _darkMode = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadTheme();
//     _initFirebaseMessaging();
//   }

//   Future<void> _loadTheme() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _darkMode = prefs.getBool('darkMode') ?? false;
//     });
//   }

//   Future<void> toggleTheme(bool isDark) async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _darkMode = isDark;
//     });
//     await prefs.setBool('darkMode', isDark);
//   }

//   void _initFirebaseMessaging() async {
//     FirebaseMessaging messaging = FirebaseMessaging.instance;

//     NotificationSettings settings = await messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     print('🔐 Permission de notification : ${settings.authorizationStatus}');

//     String? token = await messaging.getToken();
//     print("📲 Token FCM : $token");

//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'high_importance_channel',
//       'Notifications Importantes',
//       description: 'Ce canal est utilisé pour les notifications importantes.',
//       importance: Importance.high,
//     );

//     await flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);

//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const InitializationSettings initializationSettings =
//         InitializationSettings(android: initializationSettingsAndroid);

//     await flutterLocalNotificationsPlugin.initialize(initializationSettings);

//     // 🔔 Gérer les notifications en premier plan
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       print('📩 Notification reçue (foreground) : ${message.notification?.title}');
//       RemoteNotification? notification = message.notification;
//       AndroidNotification? android = message.notification?.android;

//       if (notification != null && android != null) {
//         flutterLocalNotificationsPlugin.show(
//           notification.hashCode,
//           notification.title,
//           notification.body,
//           NotificationDetails(
//             android: AndroidNotificationDetails(
//               channel.id,
//               channel.name,
//               channelDescription: channel.description,
//               icon: '@mipmap/ic_launcher',
//             ),
//           ),
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Agritech App',
//       theme: ThemeData.light(),
//       darkTheme: ThemeData.dark(),
//       themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
//       initialRoute: '/',
//       routes: routes,
//       onUnknownRoute: (settings) {
//         return MaterialPageRoute(
//           builder: (context) => Scaffold(
//             body: Center(child: Text('Page non trouvée')),
//           ),
//         );
//       },
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:intl/date_symbol_data_local.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:provider/provider.dart';
// import 'services/connectivity_service.dart';
// import 'firebase_options.dart';
// import 'routes.dart';

// // 🔔 Gestionnaire des notifications en arrière-plan
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   print("🔔 Notification en arrière-plan : ${message.messageId}");
// }

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );

//   // ✅ Activer la persistance locale de Firestore
//   FirebaseFirestore.instance.settings = const Settings(
//     persistenceEnabled: true,
//     cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
//   );

//   // 🔧 Enregistrement du handler background
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

//   // 🗓️ Initialiser les formats de date en français
//   await initializeDateFormatting('fr_FR', null);
  
//   FirebaseFirestore.instance.settings = const Settings(
//     persistenceEnabled: true,
//   );

//   runApp(MyApp());
// }

// class MyApp extends StatefulWidget {
//   static _MyAppState? of(BuildContext context) =>
//       context.findAncestorStateOfType<_MyAppState>();

//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   bool _darkMode = false;
//   bool _offline = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadTheme();
//     _initFirebaseMessaging();
//     _monitorConnectivity();
//   }

//   Future<void> _loadTheme() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _darkMode = prefs.getBool('darkMode') ?? false;
//     });
//   }

//   Future<void> toggleTheme(bool isDark) async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _darkMode = isDark;
//     });
//     await prefs.setBool('darkMode', isDark);
//   }

//   void _initFirebaseMessaging() async {
//     FirebaseMessaging messaging = FirebaseMessaging.instance;

//     NotificationSettings settings = await messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     print(' Permission de notification : ${settings.authorizationStatus}');

//     String? token = await messaging.getToken();
//     print(" Token FCM : $token");

//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'high_importance_channel',
//       'Notifications Importantes',
//       description: 'Ce canal est utilisé pour les notifications importantes.',
//       importance: Importance.high,
//     );

//     await flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);

//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const InitializationSettings initializationSettings =
//         InitializationSettings(android: initializationSettingsAndroid);

//     await flutterLocalNotificationsPlugin.initialize(initializationSettings);

//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       print(' Notification reçue (foreground) : ${message.notification?.title}');
//       RemoteNotification? notification = message.notification;
//       AndroidNotification? android = message.notification?.android;

//       if (notification != null && android != null) {
//         flutterLocalNotificationsPlugin.show(
//           notification.hashCode,
//           notification.title,
//           notification.body,
//           NotificationDetails(
//             android: AndroidNotificationDetails(
//               channel.id,
//               channel.name,
//               channelDescription: channel.description,
//               icon: '@mipmap/ic_launcher',
//             ),
//           ),
//         );
//       }
//     });
//   }

//   void _monitorConnectivity() {
//   Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
//     setState(() {
//       _offline = results.isEmpty || results.first == ConnectivityResult.none;
//     });
//   });
// }


//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Agritech App',
//       theme: ThemeData.light(),
//       darkTheme: ThemeData.dark(),
//       themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
//       initialRoute: '/',
//       routes: routes,

//       // ✅ Ajout des localisations pour les widgets comme DatePicker
//       localizationsDelegates: const [
//         GlobalMaterialLocalizations.delegate,
//         GlobalWidgetsLocalizations.delegate,
//         GlobalCupertinoLocalizations.delegate,
//       ],
//       supportedLocales: const [
//         Locale('fr', 'FR'),
//         Locale('en', 'US'),
//       ],

//       builder: (context, child) {
//         return Stack(
//           children: [
//             child!,
//             if (_offline)
//               Positioned(
//                 top: 0,
//                 left: 0,
//                 right: 0,
//                 child: Container(
//                   color: Colors.red,
//                   padding: EdgeInsets.all(4),
//                   child: SafeArea(
//                     child: Center(
//                       child: Text(
//                         " Vous êtes hors ligne",
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         );
//       },

//       onUnknownRoute: (settings) {
//         return MaterialPageRoute(
//           builder: (context) => Scaffold(
//             body: Center(child: Text('Page non trouvée')),
//           ),
//         );
//       },
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'services/connectivity_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 Notification en arrière-plan : \${message.messageId}");
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await initializeDateFormatting('fr_FR', null);

  runApp(
    ChangeNotifierProvider(
      create: (_) {
        final service = ConnectivityService();
        service.initialize();
        return service;
      },
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _initFirebaseMessaging();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = isDark;
    });
    await prefs.setBool('darkMode', isDark);
  }

  void _initFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print(' Permission de notification : \${settings.authorizationStatus}');

    String? token = await messaging.getToken();
    print(" Token FCM : \$token");

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notifications Importantes',
      description: 'Ce canal est utilisé pour les notifications importantes.',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(' Notification reçue (foreground) : \${message.notification?.title}');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = Provider.of<ConnectivityService>(context).isOffline;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agritech App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: routes,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            if (isOffline)
  Positioned(
    top: 0,
    left: 0,
    right: 0,
    child: Container(
      height: 30, // hauteur fixe
      color: const Color.fromARGB(255, 156, 230, 106),
      alignment: Alignment.center,
      child: Text(
        "Vous êtes hors ligne",
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
    ),
  ),
          ],
        );
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(child: Text('Page non trouvée')),
          ),
        );
      },
    );
  }
}

