import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../global.dart';

class CacheDrawer extends StatefulWidget {
  const CacheDrawer({super.key});

  @override
  State<CacheDrawer> createState() => _CacheDrawerState();
}

class _CacheDrawerState extends State<CacheDrawer> {
  List<_CacheEntity> cacheEntities = [];
  final sh = StorageHandler();
  bool loading = true;
  int get totalSize => cacheEntities.fold(0, (prev, r) => prev + r.size);

  @override
  void initState() {
    super.initState();
    getCachedData();
  }

  void getCachedData() {
    cacheEntities = Directory(cachePath).listSync().whereType<Directory>().map((e) {
      final size = StorageHandler.getDirectorySize(e.path);
      return _CacheEntity(
        name: e.path.split('\\').last,
        path: e.path,
        size: size,
      );
    }).toList();
    loading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 800,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Stack(
          children: [
            KLIIconButton(
              const Icon(Icons.refresh),
              enabledLabel: 'Refresh',
              onPressed: () => getCachedData(),
            ),
            Column(
              children: [
                Text(
                  'Cache ${loading ? '' : '(${getSizeString(totalSize)})'}',
                  style: const TextStyle(fontSize: 24),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                loading
                    ? const Expanded(
                        child: Center(child: Text('Loading...')),
                      )
                    : Expanded(
                        child: ListView.builder(
                          itemCount: cacheEntities.length,
                          itemBuilder: (context, index) {
                            final entity = cacheEntities[index];
                            return ListTile(
                              title: Text(entity.name),
                              // title: Text('"${entity.name}" at ${entity.path}'),
                              subtitle: Text(getSizeString(entity.size)),
                              trailing: IntrinsicWidth(
                                child: Row(
                                  children: [
                                    KLIIconButton(
                                      const Icon(Icons.folder),
                                      enabledLabel: 'Open folder',
                                      onPressed: () async {
                                        launchUrlString(
                                          'file://${Uri.directory(entity.path).toFilePath(windows: Platform.isWindows)}',
                                          mode: LaunchMode.externalApplication,
                                        );
                                      },
                                    ),
                                    KLIIconButton(
                                      const Icon(Icons.delete),
                                      enabledLabel: 'Delete cache of ${entity.name}',
                                      onPressed: () async {
                                        if (await entity.delete(context)) {
                                          cacheEntities.removeAt(index);
                                          setState(() {});
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CacheEntity {
  final String name;
  final String path;
  final int size;

  const _CacheEntity({required this.name, required this.path, required this.size});

  Future<bool> delete(BuildContext context) async {
    final r = await dialogWithActions<bool>(
      context,
      time: 150.ms,
      title: 'Delete cache',
      content: 'Delete cached data of match $name?',
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: const Text('Yes'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('No'),
        ),
      ],
    );

    if (r == true) {
      Directory(path).deleteSync(recursive: true);
      return true;
    }
    return false;
  }
}
