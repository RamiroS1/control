import 'package:flutter/material.dart';

import 'core.dart';
import 'state.dart';
import 'screens/splash.dart';

void main() => runApp(const ControlApp());

class ControlApp extends StatefulWidget {
  const ControlApp({super.key});
  @override
  State<ControlApp> createState() => _ControlAppState();
}

class _ControlAppState extends State<ControlApp> {
  final AppState _state = AppState();

  @override
  void initState() {
    super.initState();
    _state.init();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Store(
      state: _state,
      child: MaterialApp(
        title: 'Control',
        debugShowCheckedModeBanner: false,
        theme: T.theme(),
        home: const SplashScreen(),
      ),
    );
  }
}
