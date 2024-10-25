import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../global.dart';
import '../match_data.dart';
import 'cache_drawer.dart';
import 'waiting_screen.dart';

final _key = GlobalKey<ScaffoldState>();

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  String loadingText = 'Initializing package info...';
  bool isLoading = true;

  final clientTextController = TextEditingController(), ipTextController = TextEditingController();
  ConnectionID? selectedID;
  bool isConnecting = false, isConnected = false;

  @override
  void initState() {
    super.initState();
    updateChild = () => setState(() {});
    KLIClient.onDisconnected.listen((m) {
      showPopupMessage(context, title: 'Forced disconnection', content: m);
      setState(() => isConnected = false);
      updateDebugOverlay();
    });
  }

  @override
  void dispose() {
    ipTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(image: bgDecorationImage),
      alignment: Alignment.center,
      child: Scaffold(
        key: _key,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: kToolbarHeight * 1.5,
          title: Column(
            children: [
              const Text('Client', style: TextStyle(fontSize: fontSizeLarge)),
              ChangelogPanel(
                changelog: changelog,
                versionString: appVersionString,
                appName: 'KLI Client',
                devToggle: () {
                  showDebugInfo = !showDebugInfo;
                  updateDebugOverlay();
                },
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 16),
              child: CloseButton(onPressed: () {
                logHandler.info('Exiting app');
                exit(0);
              }),
            ),
          ],
          forceMaterialTransparency: true,
        ),
        endDrawer: const CacheDrawer(),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            connectionStatus(),
            connectInfo(),
            connectButtons(),
            cacheButton(),
          ],
        ),
      ),
    );
  }

  Widget connectionStatus() {
    const s = TextStyle(fontSize: fontSizeLarge);
    return Text(
      'Trạng thái kết nối: ${isConnecting ? '🟡' : isConnected ? '🟢' : '🔴'}',
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
          initialSelection: selectedID,
          controller: clientTextController,
          label: const Text('Client'),
          dropdownMenuEntries: [for (final c in ConnectionID.values.getRange(1, ConnectionID.values.length)) DropdownMenuEntry(value: c, label: Networking.getClientDisplayID(c))],
          onSelected: (value) {
            selectedID = value;
            setState(() {});
          },
        ),
        const SizedBox(width: 20),
        KLITextField(
          readOnly: isConnected,
          controller: ipTextController,
          constraints: const BoxConstraints(maxWidth: 250),
          maxLines: 1,
          labelText: 'Host IP',
          hintText: 'Nhập IP của host',
        ),
      ],
    );
  }

  Widget connectButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KLIButton(
          'Kết nối',
          disabledLabel: 'Đã kết nối',
          enableCondition: !isConnecting && !isConnected,
          onPressed: () async {
            final ip = ipTextController.value.text.trim();
            if (ip.isEmpty || selectedID == null) {
              showPopupMessage(
                context,
                title: 'Thiếu thông tin',
                content: 'Vui lòng nhập IP và chọn client ID',
              );
              return;
            }

            logHandler.info('Selected id: ${selectedID!.name}');
            try {
              setState(() => isConnecting = true);
              await KLIClient.init(ip, selectedID!);
              setState(() {
                isConnecting = false;
                isConnected = true;
              });
              updateDebugOverlay();
            } on Exception catch (e, stack) {
              logHandler.error('Error when trying to connect: $e', stackTrace: stack);
              setState(() {
                isConnected = false;
                isConnecting = false;
              });
              if (e is SocketException) {
                throw KLIException(
                  'Lỗi kết nối',
                  'Vui lòng đảm bảo IP của host ($ip) là chính xác hoặc server đã được mở',
                );
              }
            }
          },
        ),
        const SizedBox(width: 20),
        KLIButton(
          'Ngắt kết nối',
          disabledLabel: 'Chưa kết nối',
          enableCondition: isConnected,
          onPressed: () {
            KLIClient.disconnect();
            // clientTextController.text = '';
            MatchData().reset();
            setState(() => isConnected = false);
            updateDebugOverlay();
          },
        ),
        const SizedBox(width: 20),
        KLIButton(
          'Vào phòng chờ',
          enabledLabel: "Khi đã sẵn sàng",
          disabledLabel: 'Chưa kết nối',
          enableCondition: isConnected,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const WaitingScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget cacheButton() {
    return KLIButton(
      'Quản lý data',
      onPressed: () {
        _key.currentState?.openEndDrawer();
      },
    );
  }
}
