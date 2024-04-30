import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../global.dart';

class ServerSetupPage extends StatefulWidget {
  const ServerSetupPage({super.key});

  @override
  State<ServerSetupPage> createState() => _ServerSetupPageState();
}

class _ServerSetupPageState extends State<ServerSetupPage> {
  String _localAddress = '';
  String chosenClientID = '';
  final _clientMessageController = TextEditingController();
  String _clientMessage = '';

  @override
  void initState() {
    super.initState();
    getIpAddresses();
    KLIServer.onClientConnectivityChanged.listen((event) {
      logger.i('A client connected');
      debugPrint('Client connected: $event');
      setState(() {});
    });
    KLIServer.onClientMessage.listen((receivedMessage) {
      _clientMessage = '${receivedMessage.senderID}: ${receivedMessage.msg}';
      setState(() {});
    });
  }

  @override
  void dispose() {
    _clientMessageController.dispose();
    super.dispose();
  }

  void getIpAddresses() async {
    _localAddress = await Networking.getLocalIP();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (pop) {
        if (pop) return;
        if (!KLIServer.started) {
          logger.i('Leaving Server Setup page...');
          Navigator.pop(context);
          return;
        }
        confirmDialog(
          context,
          message: 'Bạn có chắc bạn muốn thoát?\nServer sẽ tự động đóng.',
          acceptLogMessage: 'Leaving Server Setup page...',
          onAccept: () => Navigator.pop(context),
        );
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          forceMaterialTransparency: true,
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/ttkl_bg_new.png'),
              fit: BoxFit.fill,
              opacity: 0.8,
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
                    serverManageButtons(),
                    // DropdownMenu(
                    //   label: const Text('Client'),
                    //   dropdownMenuEntries: [
                    //     for (var i = 0; i < Networking.listOfClient.length; i++)
                    //       DropdownMenuEntry(
                    //         value: KLIServer.mapIDToIndex.keys.elementAt(i),
                    //         label: Networking.listOfClient[i],
                    //       )
                    //   ],
                    //   onSelected: (value) {
                    //     chosenClientID = value!;
                    //     setState(() {});
                    //   },
                    // ),
                    // Text('Client message: $_clientMessage'),
                    // TextField(
                    //   controller: _clientMessageController,
                    //   decoration: const InputDecoration(
                    //     labelText: 'Message to Client',
                    //   ),
                    // ),
                    // TextButton(
                    //   onPressed: () async {
                    //     if (!KLIServer.started) {
                    //       showToastMessage(context, 'No server exist');
                    //       return;
                    //     }
                    //     if (_clientMessageController.value.text.isEmpty) {
                    //       showToastMessage(context, 'Please enter a message');
                    //       return;
                    //     }
                    //     if (chosenClientID.isEmpty) {
                    //       showToastMessage(context, 'Please select a client');
                    //       return;
                    //     }
                    //     KLIServer.sendMessage(
                    //       chosenClientID,
                    //       KLISocketMessage(null, _clientMessageController.value.text, KLIMessageType.normal),
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
            ],
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

  Widget serverManageButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        button(
          context,
          'Start Server',
          enableCondition: !KLIServer.started,
          disabledLabel: 'Server already started',
          onPressed: () async {
            try {
              await KLIServer.start();

              KLIServer.onClientConnectivityChanged.listen((event) {
                logger.i('A client connected');
                debugPrint('Client connected: $event');
                setState(() {});
              });
              KLIServer.onClientMessage.listen((receivedMessage) {
                _clientMessage = '${receivedMessage.senderID}: ${receivedMessage.msg}';
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
        button(
          context,
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
        button(
          context,
          'Match Setup',
          disabledLabel: 'Not available',
          enableCondition: false,
          onPressed: () async {
            await KLIServer.stop();
            setState(() {});
            if (mounted) {
              showToastMessage(context, 'Closed server.');
            }
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
        title: Text(Networking.listOfClient[index]),
        subtitle: Text(ip),
        subtitleTextStyle: TextStyle(
          fontSize: fontSizeMSmall,
          color: connected ? Colors.greenAccent : Colors.redAccent,
        ),
      ));
    }

    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(maxWidth: 250),
      child: ListView.separated(
        shrinkWrap: true,
        // scrollDirection: Axis.horizontal,
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
