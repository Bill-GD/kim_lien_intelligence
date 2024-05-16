import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final clientTextController = TextEditingController(), ipTextController = TextEditingController();
  // ,
  // messageController = TextEditingController();
  bool isConnecting = false, isConnected = false;
  // String serverMessage = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    ipTextController.dispose();
    // messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: kToolbarHeight * 1.5,
        title: Column(
          children: [
            const Text('Client', style: TextStyle(fontSize: fontSizeLarge)),
            changeLogVersionText(),
          ],
        ),
        centerTitle: true,
        actions: [
          CloseButton(onPressed: () {
            logger.i('Exiting app');
            exit(0);
          }),
        ],
        forceMaterialTransparency: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/ttkl_bg_new.png', package: 'kli_lib'),
            fit: BoxFit.fill,
            opacity: 0.8,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            connectionStatus(),
            connectInfo(),
            connectButtons(),
            // Text('From server: $serverMessage'),
            // TextField(
            //   controller: messageController,
            //   decoration: const InputDecoration(
            //     labelText: 'Message to Server',
            //   ),
            // ),
            // TextButton(
            //   onPressed: () async {
            //     if (!isConnected) {
            //       showToastMessage(context, 'Not connected');
            //       return;
            //     }
            //     if (messageController.value.text.isEmpty) {
            //       showToastMessage(context, 'Please enter a message');
            //       return;
            //     }
            //     kliClient.sendMessage(
            //       KLISocketMessage(
            //         senderID: playerId!,
            //         message: messageController.value.text,
            //         type: KLIMessageType.normal,
            //       ),
            //     );
            //     if (context.mounted) {
            //       showToastMessage(context, 'Sending');
            //     }
            //   },
            //   child: const Text("Send Message"),
            // ),
          ],
        ),
      ),
    );
  }

  Widget changeLogVersionText() {
    return GestureDetector(
      onTap: () async {
        logger.i('Opening changelog...');
        await showDialog(
          context: context,
          builder: (context) {
            final split = changelog.split(RegExp("(?={)|(?<=})"));

            return AlertDialog(
              title: const Text('Changelog', textAlign: TextAlign.center),
              actions: [
                TextButton(
                  child: const Text('Licenses'),
                  onPressed: () {
                    showLicensePage(
                      context: context,
                      applicationIcon: Image.asset(
                        'assets/images/ttkl_logo.png',
                        package: 'kli_lib',
                        width: 50,
                        height: 50,
                      ),
                      applicationName: 'KLI Client',
                      applicationVersion: 'v${packageInfo.version}.${packageInfo.buildNumber}',
                    );
                  },
                ),
              ],
              content: SingleChildScrollView(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: fontSizeMSmall),
                    children: <InlineSpan>[
                      for (String t in split)
                        TextSpan(
                          text: t.startsWith('{') ? t.substring(1, t.length - 1) : t,
                          style: t.startsWith('{') ? const TextStyle(color: Colors.blue) : null,
                          recognizer: t.startsWith('{')
                              ? (TapGestureRecognizer()
                                ..onTap = () {
                                  logger.i('Opening commit: $t');
                                  final commitID = t.replaceAll(RegExp(r'(latest)|[{}]'), '');
                                  final url =
                                      'https://github.com/Bill-GD/kim_lien_intelligence/commit/$commitID';
                                  launchUrl(Uri.parse(url));
                                })
                              : null,
                        )
                    ],
                  ),
                  softWrap: true,
                ),
              ),
            );
          },
        );
      },
      child: Text(
        'v${packageInfo.version}.${packageInfo.buildNumber}',
        style: TextStyle(
          fontSize: fontSizeXS,
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
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
            for (final c in ClientID.values.getRange(1, ClientID.values.length))
              DropdownMenuEntry(value: c, label: Networking.getClientDisplayID(c))
          ],
          onSelected: (value) {
            KLIClient.clientID = value!;
            setState(() {});
          },
        ),
        const SizedBox(width: 20),
        TextField(
          // enabled: !isConnected,
          readOnly: isConnected,
          style: const TextStyle(fontSize: fontSizeMedium),
          controller: ipTextController,
          decoration: InputDecoration(
            constraints: const BoxConstraints(maxWidth: 250),
            labelText: 'Host IP',
            hintText: 'Enter Host IP',
            labelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
            border: const OutlineInputBorder(),
          ),
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
            logger.i('Client ${KLIClient.clientID} is trying to connect to: $ip');

            runZonedGuarded(
              () async {
                setState(() => isConnecting = true);
                await KLIClient.init(ip, KLIClient.clientID!);
                setState(() {
                  isConnecting = false;
                  isConnected = true;
                });

                KLIClient.onMessageReceived.listen((newMessage) async {
                  if (newMessage.type == KLIMessageType.disconnect) {
                    isConnected = false;
                    await KLIClient.disconnect();
                    clientTextController.text = '';
                    setState(() {});
                    if (mounted) showToastMessage(context, newMessage.msg);
                    logger.i(newMessage.msg);
                  }

                  // serverMessage = newMessage.msg;
                  setState(() {});
                });

                if (mounted) {
                  showToastMessage(
                      context, 'Connected to server as ${KLIClient.clientID} with IP: ${KLIClient.address}');
                }
              },
              (e, stack) {
                setState(() => isConnected = false);
                logger.e('Error when trying to connect: $e');
                if (e is SocketException) {
                  showToastMessage(context, 'Host (ip=$ip) not known');
                  setState(() => isConnecting = false);
                } else {
                  showToastMessage(context, '$e \n $stack');
                }
              },
            );
          },
        ),
        const SizedBox(width: 20),
        KLIButton(
          'Disconnect',
          disabledLabel: 'Not connected',
          enableCondition: isConnected,
          onPressed: () async {
            await KLIClient.disconnect();
            clientTextController.text = '';
            setState(() => isConnected = false);
            if (mounted) showToastMessage(context, 'Disconnected from server');
          },
        ),
        const SizedBox(width: 20),
        KLIButton(
          'To waiting room',
          disabledLabel: 'Not connected',
          enableCondition: isConnected,
          onPressed: () {
            showToastMessage(context, 'To waiting room');
          },
        ),
      ],
    );
  }
}
