import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityService {
  Stream<bool> get onlineStateStream;
  Future<bool> isCurrentlyOnline();
}

class ConnectivityPlusService implements ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityPlusService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  Stream<bool> get onlineStateStream async* {
    yield await isCurrentlyOnline();
    yield* _connectivity.onConnectivityChanged.map(_anyOnline);
  }

  @override
  Future<bool> isCurrentlyOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _anyOnline(results);
  }

  bool _anyOnline(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
