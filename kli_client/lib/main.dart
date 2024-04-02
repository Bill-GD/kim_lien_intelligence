import 'package:flutter/material.dart';
import 'package:kli_client/main_screen/main_screen.dart';

void main() {
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
      home: const MainScreen(),
    );
  }
}
