import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService with ChangeNotifier {
  ConnectivityResult _connectivityStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  ConnectivityResult get connectivityStatus => _connectivityStatus;

  bool get isOffline => _connectivityStatus == ConnectivityResult.none;

  Future<void> initialize() async {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _connectivityStatus = result;
      notifyListeners();

      if (result != ConnectivityResult.none) {
        _resyncFirestore();
      }
    });

    final result = await _connectivity.checkConnectivity();
    _connectivityStatus = result;
    notifyListeners();
  }

  void _resyncFirestore() async {
    await FirebaseFirestore.instance.clearPersistence();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    debugPrint("🔥 Firebase synchronisé après reconnexion.");
  }

  void disposeService() {
    _connectivitySubscription?.cancel();
  }
}
