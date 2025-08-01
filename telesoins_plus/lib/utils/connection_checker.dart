import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectionChecker with ChangeNotifier {
  bool _isConnected = true;
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  
  ConnectionChecker() {
    _checkConnection();
    _subscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }
  
  bool get isConnected => _isConnected;
  
  Future<void> _checkConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      _isConnected = false;
      notifyListeners();
    }
  }
  
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    // Vérifier si au moins une des connexions est active
    _isConnected = results.any((result) => result != ConnectivityResult.none);
    
    if (wasConnected != _isConnected) {
      notifyListeners();
    }
  }
  
  Future<bool> checkConnectionWithTimeout() async {
    try {
      final results = await Connectivity().checkConnectivity()
          .timeout(const Duration(seconds: 5));
      return results.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }
  
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}