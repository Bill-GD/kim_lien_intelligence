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
  String _localAddress = '';
  String chosenClientID = '';

  @override
  void initState() {
    super.initState();
    getIpAddresses();
    // KLIServer.onClientConnectivityChanged.listen((event) {
    //   logger.i('A client connected');
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
    _localAddress = await Networking.getLocalIP();
    setState(() {});
  }

  Future<void> popHandler() async {
    if (!KLIServer.started) {
      logger.i('Leaving Server Setup page...');
      Navigator.pop(context);
      return;
    }
    await confirmDialog(
      context,
      message: 'Bạn có chắc bạn muốn thoát?\nServer sẽ tự động đóng.',
      acceptLogMessage: 'Leaving Server Setup page...',
      onAccept: () async {
        await KLIServer.stop();
        if (context.mounted) Navigator.pop(context);
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
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/ttkl_bg_new.png', package: 'kli_lib'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: const BoxDecoration(border: Border(right: BorderSide(width: 2))),
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Column(children: [
                      clientList(),
                    ]),
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
      'Server status: ${KLIServer.started ? '🟢' : '🔴'} \nLocal IP: $_localAddress',
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
                logger.i('A client connected');
                setState(() {});
              });

              setState(() {});
            } on Exception catch (error, stack) {
              if (mounted) {
                showToastMessage(context, error.toString());
              }
              logger.e(error, stackTrace: stack);
              return;
            }

            if (mounted) {
              showToastMessage(context, 'Started a local server with IP: ${KLIServer.address}');
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
          disabledLabel: 'No server exist',
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
      final connected = client != null;
      String ip = connected ? '${client.address.address}:${client.port}' : 'Not connected';
      clients.add(ListTile(
        title: Text(Networking.getClientDisplayID(ClientID.values[index + 1])),
        subtitle: Text(ip),
        subtitleTextStyle: TextStyle(
          fontSize: fontSizeMSmall,
          color: connected ? Colors.greenAccent : Colors.redAccent,
        ),
        trailing: KLIIconButton(
          const FaIcon(FontAwesomeIcons.linkSlash),
          enableCondition: connected,
          enabledLabel: 'Disconnect ${Networking.getClientDisplayID(ClientID.values[index + 1])}',
          disabledLabel: 'Not connected',
          onPressed: () async {
            await confirmDialog(
              context,
              message: 'Disconnect client?',
              acceptLogMessage: 'Disconnected Client: ${ClientID.values[index + 1]}',
              onAccept: () async {
                KLIServer.sendMessage(
                  ClientID.values[index + 1],
                  KLISocketMessage(
                    senderID: ClientID.host,
                    message: 'Server forced disconnection',
                    type: KLIMessageType.disconnect,
                  ),
                );
                if (connected) client.destroy();
              },
            );
          },
        ),
      ));
    }

    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(maxWidth: 250),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: clients.length,
        separatorBuilder: (_, __) {
          return const SizedBox(height: 30);
        },
        itemBuilder: (_, index) {
          return clients[index];
        },
      ),
    );
  }
}
