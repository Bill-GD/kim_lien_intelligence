import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../data_manager.dart';
import 'match_editor.dart';

class MatchManager extends StatefulWidget {
  const MatchManager({super.key});

  @override
  State<MatchManager> createState() => _MatchManagerState();
}

class _MatchManagerState extends State<MatchManager> {
  bool isLoading = true;
  int currentMatchIndex = -1;
  List<KLIMatch> matches = [];

  @override
  void initState() {
    super.initState();
    logHandler.info('Opened Match Manager');

    matches = DataManager.getAllMatches();
    currentMatchIndex = -1;
    setState(() => isLoading = false);
    logHandler.info('Loaded ${matches.length} matches');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: managerAppBar(
        context,
        'Quản lý trận đấu',
        actions: [
          const KLIHelpButton(
            content: '''
              Thông tin trận đấu: tên trận, tên thí sinh, ảnh thí sinh.

              Khi bắt đầu trận, ảnh sẽ được gửi sang Client nên ảnh với kích thước lớn sẽ tốn thời gian gửi hơn.
              Ảnh với dung lượng 0.7-1MB sẽ đảm bảo cả chất lượng và tốc độ.
              
              Khi chọn trận, các thí sinh được hiển thị ở bên phải.
              
              Thêm trận: Thêm trận đấu mới vào danh sách trận đấu.
              Sửa trận: Sửa thông tin trận đấu đã chọn.
              Xóa trận: Xóa trận đấu và tất cả câu hỏi của trận.''',
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  managementButtons(),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        matchList(),
                        playerShowcase(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget managementButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          KLIButton(
            'Thêm trận',
            onPressed: () async {
              final newMatch = await Navigator.of(context).push<KLIMatch>(
                DialogRoute<KLIMatch>(
                  context: context,
                  barrierDismissible: false,
                  barrierLabel: '',
                  builder: (_) => MatchEditor(matchNames: matches.map((e) => e.name)),
                ),
              );

              if (newMatch != null) {
                matches.add(newMatch);
                DataManager.addMatch(newMatch.name);
                setState(() {});
              }
            },
          ),
          KLIButton(
            'Sửa trận${currentMatchIndex < 0 ? '' : ': ${matches[currentMatchIndex].name}'}',
            enableCondition: currentMatchIndex >= 0,
            disabledLabel: 'Chưa chọn trận đấu',
            onPressed: () async {
              final newMatch = await Navigator.of(context).push<KLIMatch>(
                DialogRoute<KLIMatch>(
                  context: context,
                  barrierDismissible: false,
                  barrierLabel: '',
                  builder: (_) => MatchEditor(
                    match: matches[currentMatchIndex],
                    matchNames: matches.map((e) => e.name),
                  ),
                ),
              );

              if (newMatch != null) {
                String oldName = matches[currentMatchIndex].name;
                bool changedName = newMatch.name != oldName;
                matches[currentMatchIndex] = newMatch;
                DataManager.updateMatch(newMatch);
                if (changedName) {
                  DataManager.changeMatchName(oldName: oldName, newName: newMatch.name);
                }
                setState(() {});
              }
            },
          ),
          KLIButton(
            'Xóa trận${currentMatchIndex < 0 ? '' : ': ${matches[currentMatchIndex].name}'}',
            enableCondition: currentMatchIndex >= 0,
            disabledLabel: 'Chưa chọn trận đấu',
            onPressed: () async {
              await confirmDialog(
                context,
                message: 'Bạn có muốn xóa trận: ${matches[currentMatchIndex].name}?',
                acceptLogMessage: 'Removed match: ${matches[currentMatchIndex].name}',
                onAccept: () {
                  showToastMessage(context, 'Đã xóa trận: ${matches[currentMatchIndex].name}');
                  DataManager.deleteMatch(matches[currentMatchIndex].name);
                  matches.removeAt(currentMatchIndex);
                  setState(() => currentMatchIndex = -1);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget matchList() {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 96),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Text(
                'Danh sách trận đấu',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: fontSizeMedium,
                ),
              ),
            ),
            Flexible(
              child: matches.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.onBackground),
                        color: Theme.of(context).colorScheme.background,
                      ),
                      alignment: Alignment.center,
                      child: const Text('Không có trận'),
                    )
                  : ListView.separated(
                      itemCount: matches.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 20),
                      itemBuilder: (_, index) => ListTile(
                        title: Text(
                          matches[index].name,
                          style: const TextStyle(
                            fontSize: fontSizeMedium,
                            color: Colors.white,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(width: 2, color: Colors.white),
                        ),
                        onTap: () {
                          currentMatchIndex = index;
                          setState(() {});
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget playerShowcase() {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 96),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Text(
                'Danh sách thí sinh',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: fontSizeMedium,
                ),
              ),
            ),
            Flexible(
              child: currentMatchIndex < 0
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.onBackground),
                      ),
                      child: const Material(child: Center(child: Text('Chưa chọn trận đấu'))),
                    )
                  : playerGrid(),
            ),
          ],
        ),
      ),
    );
  }

  GridView playerGrid() {
    return GridView.builder(
      itemCount: 4,
      padding: const EdgeInsets.symmetric(vertical: 40),
      itemBuilder: (_, index) {
        final p = matches[currentMatchIndex].playerList;

        String fullImagePath = StorageHandler.getFullPath(p[index]?.imagePath ?? '');

        bool hasPlayer = p[index] != null, imageFound = false;
        if (hasPlayer) {
          imageFound = File(fullImagePath).existsSync();
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: GridTile(
            footer: hasPlayer
                ? Text(
                    '${p[index]?.name}',
                    style: const TextStyle(
                      fontSize: fontSizeSmall,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  )
                : null,
            child: !hasPlayer || !imageFound
                ? Container(
                    margin: const EdgeInsets.only(bottom: 35),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.onBackground),
                      color: Theme.of(context).colorScheme.background,
                    ),
                    alignment: Alignment.center,
                    child: Text(!hasPlayer ? 'Không có thí sinh' : 'Không tìm thấy ảnh tại $fullImagePath'),
                  )
                : Padding(
                    padding: const EdgeInsets.only(bottom: 35),
                    child: Image.file(File(fullImagePath), fit: BoxFit.cover),
                  ),
          ),
        );
      },
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
    );
  }
}
