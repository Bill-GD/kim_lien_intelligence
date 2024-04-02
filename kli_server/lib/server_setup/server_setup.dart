import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

class ServerSetupPage extends StatefulWidget {
  const ServerSetupPage({super.key});

  @override
  State<ServerSetupPage> createState() => _ServerSetupPageState();
}

class _ServerSetupPageState extends State<ServerSetupPage> {
  String _localAddress = '';

  @override
  void initState() {
    super.initState();
    getIpAddresses();
    KLIServer.onClientConnectivityChanged.listen((event) {
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
                itemBuilder: (context, index) => ListTile(
                  title: Text(KLIClient.listOfClient[index]),
                  subtitle: Text('IP: ${KLIServer.clientAt(index)?.address.address}'),
                ),
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
                  showToastMessage(
                    context,
                    'Closed server.',
                  );
                }
              },
              child: const Text("Stop Server"),
            ),
          ],
        ),
      ),
    );
  }
}
