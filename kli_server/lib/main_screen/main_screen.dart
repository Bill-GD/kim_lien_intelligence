import 'package:flutter/material.dart';
import 'package:kli_utils/kli_utils.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  ServerIPType _ipType = ServerIPType.local;
  String _ipAddress = '';

  @override
  void initState() {
    super.initState();
    getIpAddresses();
  }

  void getIpAddresses() async {
    _ipAddress = 'Local: ${await getLocalIP()}';
    setState(() {});
    _ipAddress += '\nPublic: ${await getPublicIP()}';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ipAddress),
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
            DropdownButton(
              value: _ipType.name,
              items: const [
                DropdownMenuItem(
                  value: 'local',
                  child: Text('Local'),
                ),
                DropdownMenuItem(
                  value: 'public',
                  child: Text('Public'),
                ),
              ],
              onChanged: (value) {
                _ipType = ServerIPType.values.byName(value!);
                setState(() {});
              },
            ),
            TextButton(
              onPressed: () async {
                if (KLIServer.started) {
                  showToastMessage(context, 'Server already exist.');
                  return;
                }

                try {
                  await KLIServer.start(_ipType);
                } on Exception catch (error) {
                  if (context.mounted) {
                    showToastMessage(context, error.toString());
                  }
                  return;
                }

                if (context.mounted) {
                  showToastMessage(
                    context,
                    'Started a ${_ipType.name} server with IP: ${KLIServer.address}',
                  );
                }
              },
              child: const Text("Create Server"),
            ),
            TextButton(
              onPressed: () async {
                if (!KLIServer.started) {
                  showToastMessage(context, 'No server exist');
                  return;
                }
                await KLIServer.close();
                if (context.mounted) {
                  showToastMessage(
                    context,
                    'Closed server.',
                  );
                }
              },
              child: const Text("Kill Server"),
            ),
          ],
        ),
      ),
    );
  }
}
