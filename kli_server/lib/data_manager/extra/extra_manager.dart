import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../../global.dart';
import '../data_manager.dart';
import '../import_dialog.dart';
import 'extra_question_editor.dart';

class ExtraManager extends StatefulWidget {
  const ExtraManager({super.key});

  @override
  State<ExtraManager> createState() => _ExtraManagerState();
}

class _ExtraManagerState extends State<ExtraManager> {
  bool isLoading = true, hasSelectedMatch = false;
  List<String> matchNames = [];
  late ExtraSection selectedMatch;

  @override
  void initState() {
    super.initState();
    logHandler.info('Opened Extra Manager');
    selectedMatch = ExtraSection.empty();
    matchNames = DataManager.getMatchNames();
    setState(() => isLoading = false);
  }

  void getNewQuestion(Map<String, dynamic> data) {
    final List<ExtraQuestion> allQ = [];
    final sheet = data.values.first;

    for (final r in (sheet as List<Map>)) {
      final v = r.values;
      final q = ExtraQuestion(question: v.elementAt(1), answer: v.elementAt(2));
      allQ.add(q);
    }

    selectedMatch = ExtraSection(matchName: selectedMatch.matchName, questions: allQ);
    logHandler.info('Loaded ${selectedMatch.questions.length} questions from excel');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: managerAppBar(
        context,
        'Quản lý câu hỏi phụ',
        actions: [
          const KLIHelpButton(
            content: '''
              Thông tin câu hỏi: Nội dung, đáp án.
              
              Chọn trận đấu: Chọn trận đấu để hiện các câu hỏi.

              Thêm câu hỏi: Thêm câu hỏi mới cho trận đấu đang chọn.
              Nhập từ file: Nhập câu hỏi từ file Excel.
              Xóa câu hỏi: Xóa toàn bộ câu hỏi của trận đang chọn.

              Bấm vào câu hỏi để chỉnh sửa. Bấm vào nút xóa để xóa câu hỏi.
              
              Định dạng file Excel:
              - Chỉ lấy 1 sheet
              - Cột 1: STT
              - Cột 2: Câu hỏi
              - Cột 3: Đáp án''',
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                managementButtons(),
                questionList(),
              ],
            ),
    );
  }

  Widget managementButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          matchSelector(matchNames, (value) async {
            logHandler.info('Selected match: $value');
            hasSelectedMatch = value != null;
            selectedMatch = DataManager.getSectionOfMatch(value!);
            setState(() {});
          }),
          KLIButton(
            'Thêm câu hỏi',
            enableCondition: hasSelectedMatch,
            enabledLabel: 'Thêm 1 câu hỏi cho phần thi',
            disabledLabel: 'Chưa chọn trận đấu',
            onPressed: () async {
              final newQ = await Navigator.of(context).push<ExtraQuestion>(DialogRoute<ExtraQuestion>(
                context: context,
                barrierDismissible: false,
                barrierLabel: '',
                builder: (_) => const ExtraQuestionEditor(),
              ));
              if (newQ != null) {
                selectedMatch.questions.add(newQ);
                DataManager.updateSectionDataOfMatch<ExtraSection>(selectedMatch);
              }
              setState(() {});
            },
          ),
          KLIButton(
            'Nhập từ file',
            enableCondition: hasSelectedMatch,
            enabledLabel: 'Cho phép nhập dữ liệu từ file Excel',
            disabledLabel: 'Chưa chọn trận đấu',
            onPressed: () async {
              Map<String, dynamic>? data = await Navigator.of(context).push<Map<String, dynamic>>(DialogRoute<Map<String, dynamic>>(
                context: context,
                barrierDismissible: false,
                barrierLabel: '',
                builder: (_) => ImportQuestionDialog(
                  matchName: selectedMatch.matchName,
                  maxColumnCount: 3,
                  maxSheetCount: 1,
                  columnWidths: const [100, 500, 250, 200, 200],
                ),
              ));

              if (data == null) return;

              getNewQuestion(data);
              DataManager.updateSectionDataOfMatch<ExtraSection>(selectedMatch);
              setState(() {});
            },
          ),
          KLIButton(
            'Xóa câu hỏi',
            enableCondition: hasSelectedMatch,
            enabledLabel: 'Xóa toàn bộ câu hỏi của phần thi hiện tại',
            disabledLabel: 'Chưa chọn trận đấu',
            onPressed: () async {
              await confirmDialog(
                context,
                message: 'Bạn có muốn xóa tất cả câu hỏi phụ của trận: ${selectedMatch.matchName}?',
                acceptLogMessage: 'Removed all extra questions for match: ${selectedMatch.matchName}',
                onAccept: () async {
                  if (mounted) {
                    showToastMessage(context, 'Đã xóa (match: ${selectedMatch.matchName})');
                  }
                  DataManager.removeSectionDataOfMatch<ExtraSection>(selectedMatch);
                  selectedMatch = ExtraSection.empty();
                  setState(() {});
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget questionList() {
    List<double> widthRatios = [0.4, 0.25, 0.03];

    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 96),
        decoration: BoxDecoration(
          border: Border.all(width: 2, color: Theme.of(context).colorScheme.onBackground),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            customListTile(context, columns: [
              (const Text('Câu hỏi'), widthRatios[0]),
              (const Text('Đáp án'), widthRatios[1]),
              (const Text(''), widthRatios[2]),
            ]),
            Flexible(
              child: Material(
                borderRadius: BorderRadius.circular(10),
                child: ListView.builder(
                  itemCount: selectedMatch.questions.length,
                  itemBuilder: (_, index) {
                    final q = selectedMatch.questions[index];

                    return customListTile(
                      context,
                      columns: [
                        (Text(q.question), widthRatios[0]),
                        (Text(q.answer), widthRatios[1]),
                        (
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await confirmDialog(
                                context,
                                message: 'Bạn có muốn xóa câu hỏi này?\n"${q.question}"',
                                acceptLogMessage: 'Removed an extra question',
                                onAccept: () async {
                                  selectedMatch.questions.removeAt(index);
                                  DataManager.updateSectionDataOfMatch<ExtraSection>(selectedMatch);
                                  logHandler.info('Deleted extra question of ${selectedMatch.matchName}');
                                  setState(() {});
                                },
                              );
                            },
                          ),
                          widthRatios[2]
                        )
                      ],
                      onTap: () async {
                        final newQ = await Navigator.of(context).push<ExtraQuestion>(DialogRoute<ExtraQuestion>(
                          context: context,
                          barrierDismissible: false,
                          barrierLabel: '',
                          builder: (_) => ExtraQuestionEditor(question: q),
                        ));
                        if (newQ != null) {
                          selectedMatch.questions[index] = newQ;
                          DataManager.updateSectionDataOfMatch<ExtraSection>(selectedMatch);
                        }
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
