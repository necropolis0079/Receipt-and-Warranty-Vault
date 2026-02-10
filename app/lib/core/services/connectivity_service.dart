import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Three connectivity states.
enum ConnectivityState { online, offline, limited }

/// Two-layer network detection:
/// 1. connectivity_plus — checks for network interface (WiFi, mobile, etc.)
/// 2. internet_connection_checker_plus — DNS probe for actual internet
class ConnectivityService {
  ConnectivityService() {
    _init();
  }

  final _connectivity = Connectivity();
  final _internetChecker = InternetConnection();
  final _controller = StreamController<ConnectivityState>.broadcast();
  ConnectivityState _currentState = ConnectivityState.online;

  /// Current connectivity state.
  ConnectivityState get currentState => _currentState;

  /// Stream of connectivity changes.
  Stream<ConnectivityState> get stateStream => _controller.stream;

  void _init() {
    _connectivity.onConnectivityChanged.listen((results) async {
      final hasInterface = results.any((r) => r != ConnectivityResult.none);
      if (!hasInterface) {
        _updateState(ConnectivityState.offline);
        return;
      }
      // Has network interface — check for actual internet
      final hasInternet = await _internetChecker.hasInternetAccess;
      _updateState(hasInternet ? ConnectivityState.online : ConnectivityState.limited);
    });
  }

  void _updateState(ConnectivityState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _controller.add(newState);
    }
  }

  /// One-shot connectivity check.
  Future<ConnectivityState> check() async {
    final results = await _connectivity.checkConnectivity();
    final hasInterface = results.any((r) => r != ConnectivityResult.none);
    if (!hasInterface) return ConnectivityState.offline;
    final hasInternet = await _internetChecker.hasInternetAccess;
    return hasInternet ? ConnectivityState.online : ConnectivityState.limited;
  }

  /// Dispose resources.
  void dispose() {
    _controller.close();
  }
}
