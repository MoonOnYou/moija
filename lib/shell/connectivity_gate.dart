import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../features/common/network_error_screen.dart';

/// 앱 전역에서 네트워크 연결을 감시한다. 연결이 끊기면(비행기모드·와이파이/데이터
/// 없음) 모든 화면 위에 [NetworkErrorScreen]을 덮고, 복구되면 자동으로 사라진다.
class ConnectivityGate extends StatefulWidget {
  const ConnectivityGate({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate> {
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _offline = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _sub = _connectivity.onConnectivityChanged.listen(_apply);
    // 시작 시점 상태 1회 확인.
    _connectivity.checkConnectivity().then(_apply);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _apply(List<ConnectivityResult> results) {
    // 결과가 비었거나 모두 none이면 오프라인으로 본다.
    final offline = results.every((r) => r == ConnectivityResult.none);
    if (!mounted || offline == _offline) return;
    setState(() => _offline = offline);
  }

  Future<void> _retry() async {
    setState(() => _checking = true);
    final results = await _connectivity.checkConnectivity();
    if (!mounted) return;
    setState(() {
      _offline = results.every((r) => r == ConnectivityResult.none);
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_offline)
          Positioned.fill(
            child: NetworkErrorScreen(onRetry: _retry, retrying: _checking),
          ),
      ],
    );
  }
}
