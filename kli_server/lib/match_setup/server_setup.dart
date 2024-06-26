import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kli_lib/kli_lib.dart';

import '../data_manager/match_state.dart';
import '../global.dart';
import '../ui/overview.dart';

class ServerSetup extends StatefulWidget {
  final String matchName;
  const ServerSetup(this.matchName, {super.key});

  @override
  State<ServerSetup> createState() => _ServerSetupState();
}

class _ServerSetupState extends State<ServerSetup> {
  String localAddress = '', publicAddress = '';

  @override
  void initState() {
    KLIServer.stop();
    super.initState();
    logHandler.info('Opened Server Setup page');
    getIpAddresses();
  }

  void getIpAddresses() async {
    localAddress = await Networking.getLocalIP();
    publicAddress = await Networking.getPublicIP();
    setState(() {});
  }

  Future<void> popHandler() async {
    if (!KLIServer.started) {
      logHandler.info('Leaving Server Setup page...');
      Navigator.pop(context);
      return;
    }
    await confirmDialog(
      context,
      message: 'Bạn có chắc bạn muốn thoát?\nServer sẽ tự động đóng.',
      acceptLogMessage: 'Leaving Server Setup page...',
      onAccept: () async {
        MatchState.reset();
        await KLIServer.stop();
        if (mounted) Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): popHandler,
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
          canPop: false,
          onPopInvoked: (pop) async {
            if (pop) return;
            await popHandler();
          },
          child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(forceMaterialTransparency: true),
            body: Container(
              decoration: BoxDecoration(image: bgWidget),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: const BoxDecoration(border: Border(right: BorderSide(width: 2))),
                    constraints: const BoxConstraints(maxWidth: 300),
                    alignment: Alignment.topRight,
                    child: clientList(),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        serverStatus(),
                        managementButtons(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget serverStatus() {
    const s = TextStyle(fontSize: fontSizeLarge);
    return Text(
      'Server status: ${KLIServer.started ? '🟢' : '🔴'}\n'
      'Local IP: $localAddress\n',
      // 'Public IP: $publicAddress',
      textAlign: TextAlign.center,
      style: s,
    );
  }

  Widget managementButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        KLIButton(
          'Start Server',
          enableCondition: !KLIServer.started,
          disabledLabel: 'Server already started',
          onPressed: () async {
            try {
              await KLIServer.start();

              if (!MatchState.initialized) {
                logHandler.empty();
                logHandler.info('Match initialized');
              }

              await MatchState.instantiate(widget.matchName);

              KLIServer.onConnectionChanged.listen((event) {
                setState(() {});
              });

              KLIServer.onMessageReceived.listen((m) {
                if (m.type == KLIMessageType.players) {
                  logHandler.info('Sending player list');
                  for (final p in MatchState().players) {
                    KLIServer.sendMessage(
                      m.senderID,
                      KLISocketMessage(
                        senderID: ConnectionID.host,
                        type: KLIMessageType.players,
                        message: jsonEncode({
                          'name': p.name,
                          'image': Networking.encodeMedia(StorageHandler.getFullPath(p.imagePath)),
                        }),
                      ),
                    );
                  }
                }
              });

              setState(() {});
            } on Exception catch (error, stack) {
              if (mounted) {
                showToastMessage(context, error.toString());
              }
              logHandler.error('$error', stackTrace: stack);
              return;
            }

            if (mounted) {
              showToastMessage(context, 'Started a server');
            }
          },
        ),
        KLIButton(
          'Stop Server',
          disabledLabel: 'No server exist',
          enableCondition: KLIServer.started,
          onPressed: () async {
            MatchState.reset();
            await KLIServer.stop();
            setState(() {});
            if (mounted) {
              showToastMessage(context, 'Closed server.');
            }
          },
        ),
        KLIButton(
          'Start Match',
          enableCondition: KLIServer.started && (kDebugMode || KLIServer.allPlayerConnected),
          disabledLabel: !KLIServer.started ? 'No server exist' : 'Not enough player',
          onPressed: () async {
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const MatchOverview(),
                ),
              );
            }
          },
        ),
        if (kDebugMode)
          KLIButton(
            'Reset',
            onPressed: () {
              final matchName = MatchState().match.name;
              MatchState.reset();
              MatchState.instantiate(matchName);
              debugPrint('Match reset');
              setState(() {});
            },
          ),
      ],
    );
  }

  Widget clientList() {
    final clients = <Widget>[];

    for (int index = 0; index < KLIServer.totalClientCount; index++) {
      final client = KLIServer.clientAt(index);
      final clientConnected = client != null;
      String ip = clientConnected ? '${client.remoteAddress.address}:${client.remotePort}' : 'Not connected';

      clients.add(ListTile(
        title: Text(Networking.getClientDisplayID(ConnectionID.values[index + 1])),
        subtitle: Text(ip),
        subtitleTextStyle: TextStyle(
          fontSize: fontSizeMSmall,
          color: clientConnected ? Colors.greenAccent : Colors.redAccent,
        ),
        trailing: KLIIconButton(
          const FaIcon(FontAwesomeIcons.linkSlash),
          enableCondition: clientConnected,
          enabledLabel: 'Disconnect ${Networking.getClientDisplayID(ConnectionID.values[index + 1])}',
          disabledLabel: 'Not connected',
          onPressed: () async {
            await confirmDialog(
              context,
              message: 'Disconnect client?',
              acceptLogMessage: 'Forced disconnect Client: ${ConnectionID.values[index + 1]}',
              onAccept: () async {
                KLIServer.disconnectClient(ConnectionID.values[index + 1], 'Server forced disconnection');
                if (clientConnected) client.destroy();
              },
            );
          },
        ),
      ));
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: clients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 30),
      itemBuilder: (_, index) => clients[index],
    );
  }
}
