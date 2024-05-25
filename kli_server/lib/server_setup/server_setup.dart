import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kli_lib/kli_lib.dart';

import '../global.dart';

class ServerSetup extends StatefulWidget {
  const ServerSetup({super.key});

  @override
  State<ServerSetup> createState() => _ServerSetupState();
}

class _ServerSetupState extends State<ServerSetup> {
  String localAddress = '', publicAddress = '';
  String chosenClientID = '';

  @override
  void initState() {
    super.initState();
    logHandler.info('Opened Server Setup page', d: 1);
    getIpAddresses();
    // KLIServer.onClientConnectivityChanged.listen((event) {
    //   logHandler.i('A client connected');
    //   setState(() {});
    // });
    // KLIServer.onClientMessage.listen((receivedMessage) {
    // _clientMessage = '${receivedMessage.senderID}: ${receivedMessage.msg}';
    //   setState(() {});
    // });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void getIpAddresses() async {
    localAddress = await Networking.getLocalIP();
    publicAddress = await Networking.getPublicIP();
    setState(() {});
  }

  Future<void> popHandler() async {
    if (!KLIServer.started) {
      logHandler.info('Leaving Server Setup page...', d: 2);
      Navigator.pop(context);
      return;
    }
    await confirmDialog(
      context,
      message: 'Bạn có chắc bạn muốn thoát?\nServer sẽ tự động đóng.',
      acceptLogMessage: 'Leaving Server Setup page...',
      onAccept: () async {
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
      'Server status: ${KLIServer.started ? '🟢' : '🔴'}\nLocal IP: $localAddress\nPublic IP: $publicAddress',
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

              KLIServer.onClientConnectivityChanged.listen((event) {
                setState(() {});
              });

              setState(() {});
            } on Exception catch (error, stack) {
              if (mounted) {
                showToastMessage(context, error.toString());
              }
              logHandler.error('$error', stackTrace: stack, d: 2);
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
            await KLIServer.stop();
            setState(() {});
            if (mounted) {
              showToastMessage(context, 'Closed server.');
            }
          },
        ),
        KLIButton(
          'Start Match',
          disabledLabel: !KLIServer.started ? 'No server exist' : 'Not enough player',
          enableCondition: KLIServer.started && KLIServer.allPlayerConnected,
          onPressed: () async {
            await KLIServer.stop();
            setState(() {});
            if (mounted) showToastMessage(context, 'Closed server.');
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
        title: Text(Networking.getClientDisplayID(ClientID.values[index + 1])),
        subtitle: Text(ip),
        subtitleTextStyle: TextStyle(
          fontSize: fontSizeMSmall,
          color: clientConnected ? Colors.greenAccent : Colors.redAccent,
        ),
        trailing: KLIIconButton(
          const FaIcon(FontAwesomeIcons.linkSlash),
          enableCondition: clientConnected,
          enabledLabel: 'Disconnect ${Networking.getClientDisplayID(ClientID.values[index + 1])}',
          disabledLabel: 'Not connected',
          onPressed: () async {
            await confirmDialog(
              context,
              message: 'Disconnect client?',
              acceptLogMessage: 'Forced disconnect Client: ${ClientID.values[index + 1]}',
              onAccept: () async {
                KLIServer.disconnectClient(ClientID.values[index + 1], 'Server forced disconnection');
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
