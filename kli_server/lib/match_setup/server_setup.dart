import 'dart:async';

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
  String localAddress = '';
  final List<StreamSubscription> subscriptions = [];
  bool canClosePopup = false;
  final ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});
    KLIServer.stop();
    logHandler.info('Opened Server Setup page');
    getIpAddresses();
    ipController.text = 'Local IP: $localAddress\n';
  }

  void getIpAddresses() async {
    KLIServer.serverAddress = await Networking.getLocalIP();
    localAddress = KLIServer.serverIP;
    ipController.text = 'Local IP: $localAddress\n';
    updateDebugOverlay();
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
        await KLIServer.stop();
        updateDebugOverlay();
        if (mounted) Navigator.pop(context);
      },
    );
  }

  @override
  void dispose() {
    for (final sub in subscriptions) {
      sub.cancel();
    }
    super.dispose();
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
            endDrawer: Drawer(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Player: pi_<pos>'),
                  const Text('obstacle: oi'),
                  const Text('accel: ai_<q>_<i>'),
                  const Text('finish: f_<path>'),
                  const Text(''),
                  Text('Match data: ${DataSize.matchActualDataSize}'),
                  Text('Match msg data: ${DataSize.matchMessageSize}'),
                  Text('Player data: ${DataSize.playerActualDataSize}'),
                  Text('Player msg data: ${DataSize.playerMessageSize}'),
                ],
              ),
            ),
            body: Container(
              decoration: BoxDecoration(image: bgDecorationImage),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Server status: ${KLIServer.started ? '🟢' : '🔴'}\n',
          textAlign: TextAlign.center,
          style: s,
        ),
        IntrinsicWidth(
          child: TextFormField(
            style: const TextStyle(fontSize: fontSizeLarge),
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            readOnly: true,
            controller: ipController,
          ),
        ),
      ],
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
            await KLIServer.start(updateDebugOverlay);
            updateDebugOverlay();
            addClientListeners();
            if (DataSize.matchActualDataSize == 0 && mounted) {
              showPopupMessage(
                context,
                title: 'Match data',
                content: 'Please remember to prepare the match data before any client connect.',
              );
            }
            setState(() {});
          },
        ),
        KLIButton(
          'Stop Server',
          disabledLabel: 'No server exist',
          enableCondition: KLIServer.started,
          onPressed: () async {
            // MatchState.reset();
            await KLIServer.stop();
            updateDebugOverlay();
            setState(() {});
          },
        ),
        KLIButton(
          'Start Match',
          enableCondition: KLIServer.started && (isTesting || MatchState().allPlayerReady),
          disabledLabel: !KLIServer.started ? 'No server exist' : 'Not enough player',
          onPressed: () async {
            KLIServer.sendToAllClients(KLISocketMessage(
              senderID: ConnectionID.host,
              type: KLIMessageType.startMatch,
            ));

            KLIServer.sendToAllClients(KLISocketMessage(
              senderID: ConnectionID.host,
              message: MatchState().sectionDisplay(MatchState().section),
              type: KLIMessageType.section,
            ));

            updateDebugOverlay();
            logHandler.empty();
            logHandler.info('Match started');
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (context) => const MatchOverview()),
              );
            }
          },
        ),
        KLIButton(
          'Prepare match data',
          onPressed: () async {
            showPopupMessage(
              context,
              title: 'Match data',
              content: '''
              The app is preparing the match data. Please wait for it to finish.
              This data will be used by the clients while playing the match.''',
            );
            Future.delayed(
              300.ms,
              () {
                MatchState.prepareMatchData(storageHandler.matchData, storageHandler.playerData);
                showPopupMessage(context, title: 'Finish', content: 'Done! You can close this now.');
                setState(() {});
              },
            );
          },
        ),
        if (isTesting)
          KLIButton(
            'Reset',
            onPressed: () {
              final matchName = MatchState().match.name;
              MatchState.reset();
              MatchState.instantiate(matchName);
              updateDebugOverlay();
              logHandler.info('Match reset');
              debugPrint('Match reset');
              setState(() {});
            },
          ),
      ],
    );
  }

  void addClientListeners() {
    subscriptions.add(KLIServer.onConnectionChanged.listen((e) {
      if (e >= 0 && e < 4) {
        MatchState.playerReady[e] = false;
      }
      setState(() {});
    }));

    subscriptions.add(KLIServer.onMessageReceived.listen((m) {
      if (m.type == KLIMessageType.dataSize) {
        final id = m.senderID.name;
        id.contains('player') || id.contains('mc') //
            ? MatchState.sendPlayerData(m.senderID, false, storageHandler.playerData)
            : MatchState.sendMatchData(m.senderID, false, storageHandler.matchData);
      }

      if (m.type == KLIMessageType.matchName) {
        KLIServer.sendMessage(
          m.senderID,
          KLISocketMessage(
            senderID: ConnectionID.host,
            type: KLIMessageType.matchName,
            message: widget.matchName,
          ),
        );
      }

      if (m.type == KLIMessageType.playerData) {
        MatchState.sendPlayerData(m.senderID, true, storageHandler.playerData);
      }

      if (m.type == KLIMessageType.matchData) {
        MatchState.sendMatchData(m.senderID, true, storageHandler.matchData);
      }

      if (m.type == KLIMessageType.playerReady) {
        final pos = m.senderID.index - 1;
        assert(pos >= 0 && pos < 4, 'Invalid player position: $pos');
        MatchState.playerReady[pos] = true;

        KLIServer.sendMessage(
          m.senderID,
          KLISocketMessage(
            senderID: ConnectionID.host,
            type: KLIMessageType.playerReady,
          ),
        );
        setState(() {});
      }
    }));
  }

  Widget clientList() {
    final clients = <Widget>[];

    for (int index = 0; index < KLIServer.totalClientCount; index++) {
      final client = KLIServer.getClientSocket(index);
      final clientConnected = client != null;
      String ip = clientConnected ? '${client.remoteAddress.address}:${client.remotePort}' : 'Not connected';

      String t = Networking.getClientDisplayID(ConnectionID.values[index + 1]);
      Widget w = Text(t);
      if (index < 4) {
        t += MatchState.initialized && MatchState.playerReady[index] ? '  ✔️' : '  ❌';
        w = Tooltip(
          message: MatchState.playerReady[index] ? 'Ready' : 'Not ready',
          child: Text(t),
        );
      }

      clients.add(
        ListTile(
          title: w,
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
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: clients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 30),
      itemBuilder: (_, index) => clients[index],
    );
  }
}
