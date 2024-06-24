import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../global.dart';
import 'waiting_screen.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  String loadingText = 'Initializing package info...';
  bool isLoading = true;

  final clientTextController = TextEditingController(), ipTextController = TextEditingController();
  bool isConnecting = false, isConnected = false;

  StreamSubscription<KLISocketMessage>? newMessageSubscription;

  @override
  void initState() {
    logHandler.depth = 1;
    super.initState();
  }

  @override
  void dispose() {
    ipTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: kToolbarHeight * 1.5,
        title: Column(
          children: [
            const Text('Client', style: TextStyle(fontSize: fontSizeLarge)),
            ChangelogPanel(
              changelog: changelog,
              versionString: 'v${packageInfo.version}.${packageInfo.buildNumber}',
              appName: 'KLI Client',
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          CloseButton(onPressed: () {
            logHandler.info('Exiting app', d: 0);
            exit(0);
          }),
        ],
        forceMaterialTransparency: true,
      ),
      body: Container(
        decoration: BoxDecoration(image: bgWidget),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            connectionStatus(),
            connectInfo(),
            connectButtons(),
          ],
        ),
      ),
    );
  }

  Widget connectionStatus() {
    const s = TextStyle(fontSize: fontSizeLarge);
    return Text(
      'Connection status: ${isConnecting ? '🟡' : isConnected ? '🟢' : '🔴'}',
      textAlign: TextAlign.center,
      style: s,
    );
  }

  Widget connectInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DropdownMenu(
          enabled: !isConnected,
          initialSelection: KLIClient.clientID,
          controller: clientTextController,
          label: const Text('Client'),
          dropdownMenuEntries: [
            for (final c in ConnectionID.values.getRange(1, ConnectionID.values.length))
              DropdownMenuEntry(value: c, label: Networking.getClientDisplayID(c))
          ],
          onSelected: (value) {
            KLIClient.clientID = value!;
            setState(() {});
          },
        ),
        const SizedBox(width: 20),
        KLITextField(
          readOnly: isConnected,
          controller: ipTextController,
          constraints: const BoxConstraints(maxWidth: 250),
          labelText: 'Host IP',
          hintText: 'Enter Host IP',
        ),
      ],
    );
  }

  Widget connectButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KLIButton(
          'Connect',
          disabledLabel: 'Already connected',
          enableCondition: !isConnecting && !isConnected,
          onPressed: () {
            final ip = ipTextController.value.text.trim();
            if (ip.isEmpty) {
              showToastMessage(context, 'Please enter an IP');
              return;
            }
            if (KLIClient.clientID == null) {
              showToastMessage(context, 'Please select a player ID');
              return;
            }
            logHandler.info('Selected role: ${KLIClient.clientID}');

            runZonedGuarded(
              () async {
                setState(() => isConnecting = true);
                await KLIClient.init(ip, KLIClient.clientID!);
                setState(() {
                  isConnecting = false;
                  isConnected = true;
                });

                newMessageSubscription = KLIClient.onMessageReceived.listen((newMessage) {
                  if (newMessage.type != KLIMessageType.disconnect) return;

                  isConnected = false;
                  KLIClient.disconnect();
                  clientTextController.text = '';
                  if (mounted) showToastMessage(context, newMessage.msg);
                  newMessageSubscription!.cancel();
                  newMessageSubscription = null;

                  setState(() {});
                });

                if (mounted) {
                  showToastMessage(
                    context,
                    'Connected to server as ${KLIClient.clientID} with IP: ${KLIClient.remoteAddress}',
                  );
                }
              },
              (e, stack) {
                logHandler.error('Error when trying to connect: $e', stackTrace: stack);
                if (e is SocketException) {
                  showToastMessage(context, 'Host (ip=$ip) not known');
                } else {
                  showToastMessage(context, 'An error occurred, please check log to see what happened');
                }
                setState(() {
                  isConnected = false;
                  isConnecting = false;
                });
              },
            );
          },
        ),
        const SizedBox(width: 20),
        KLIButton(
          'Disconnect',
          disabledLabel: 'Not connected',
          enableCondition: isConnected,
          onPressed: () {
            KLIClient.disconnect();
            clientTextController.text = '';
            setState(() => isConnected = false);
            if (mounted) showToastMessage(context, 'Disconnected from server');
          },
        ),
        const SizedBox(width: 20),
        KLIButton(
          'To waiting room',
          enabledLabel: 'When you\'re ready',
          disabledLabel: 'Not connected',
          enableCondition: isConnected,
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const WaitingScreen()));
          },
        ),
      ],
    );
  }
}
