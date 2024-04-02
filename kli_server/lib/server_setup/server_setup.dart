import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

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

  void getIpAddresses() async {
    _localAddress = await getLocalIP();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    title: Text(listOfClient[index]),
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
            DropdownButton(
              value: chosenClientID.isEmpty ? null : chosenClientID,
              items: [
                for (var i = 0; i < listOfClient.length; i++)
                  DropdownMenuItem(
                    value: KLIServer.mapIDToIndex.keys.elementAt(i),
                    child: Text(listOfClient[i]),
                  )
              ],
              onChanged: (value) {
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
    );
  }
}
