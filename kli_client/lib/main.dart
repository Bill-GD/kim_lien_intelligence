import 'package:flutter/material.dart';

import 'connect_screen/connect_screen.dart';
import 'global.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initLogger();
  runApp(const KliClientApp());
}

class KliClientApp extends StatelessWidget {
  const KliClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ConnectPage(),
    );
  }
}
