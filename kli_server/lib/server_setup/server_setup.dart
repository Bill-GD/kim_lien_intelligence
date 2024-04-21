import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

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
        appBar: AppBar(
          title: Text('Server: $_localAddress'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  itemCount: KLIServer.totalClientCount,
                  itemBuilder: (context, index) {
                    Socket? client = KLIServer.clientAt(index);
                    return ListTile(
                      title: Text(Networking.listOfClient[index]),
                      subtitle: Text('IP: ${client?.address.address}:${client?.port}'),
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (KLIServer.started) {
                    showToastMessage(context, 'Server already exist.');
                    return;
                  }

                  try {
                    await KLIServer.start();
                  } on Exception catch (error) {
                    if (context.mounted) {
                      showToastMessage(context, error.toString());
                    }
                    return;
                  }

                  if (context.mounted) {
                    showToastMessage(
                      context,
                      'Started a local server with IP: ${KLIServer.address}',
                    );
                  }
                },
                child: const Text("Start Server"),
              ),
              TextButton(
                onPressed: () async {
                  if (!KLIServer.started) {
                    showToastMessage(context, 'No server exist');
                    return;
                  }
                  await KLIServer.stop();
                  if (context.mounted) {
                    showToastMessage(context, 'Closed server.');
                  }
                },
                child: const Text("Stop Server"),
              ),
              DropdownMenu(
                label: const Text('Client'),
                dropdownMenuEntries: [
                  for (var i = 0; i < Networking.listOfClient.length; i++)
                    DropdownMenuEntry(
                      value: KLIServer.mapIDToIndex.keys.elementAt(i),
                      label: Networking.listOfClient[i],
                    )
                ],
                onSelected: (value) {
                  chosenClientID = value!;
                  setState(() {});
                },
              ),
              Text('Client message: $_clientMessage'),
              TextField(
                controller: _clientMessageController,
                decoration: const InputDecoration(
                  labelText: 'Message to Client',
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (!KLIServer.started) {
                    showToastMessage(context, 'No server exist');
                    return;
                  }
                  if (_clientMessageController.value.text.isEmpty) {
                    showToastMessage(context, 'Please enter a message');
                    return;
                  }
                  if (chosenClientID.isEmpty) {
                    showToastMessage(context, 'Please select a client');
                    return;
                  }
                  KLIServer.sendMessage(
                    chosenClientID,
                    KLISocketMessage(null, _clientMessageController.value.text, KLIMessageType.normal),
                  );
                  if (context.mounted) {
                    showToastMessage(context, 'Sending');
                  }
                },
                child: const Text("Send Message"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
