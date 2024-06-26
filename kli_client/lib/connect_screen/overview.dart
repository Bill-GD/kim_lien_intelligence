import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kli_client/global.dart';
import 'package:kli_lib/kli_lib.dart';

class Overview extends StatefulWidget {
  const Overview({super.key});

  @override
  State<Overview> createState() => _OverviewState();
}

class _OverviewState extends State<Overview> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(image: bgWidget),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Overview', style: TextStyle(fontSize: fontSizeLarge)),
          forceMaterialTransparency: true,
          automaticallyImplyLeading: kDebugMode,
        ),
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/waiting_screen');
                },
                child: const Text('Connect to server'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/start_screen');
                },
                child: const Text('Start screen'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/obstacle_image_screen');
                },
                child: const Text('Obstacle image screen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
