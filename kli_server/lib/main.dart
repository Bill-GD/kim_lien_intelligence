import 'package:flutter/material.dart';

import 'start_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KliServerApp());
}

class KliServerApp extends StatelessWidget {
  const KliServerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const StartPage(),
    );
  }
}
