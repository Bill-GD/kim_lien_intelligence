import 'package:flutter/material.dart';
import 'package:kli_lib/kli_lib.dart';

import '../data_manager/match_state.dart';

class AllowExtraDialog extends StatefulWidget {
  final spacing = 48.0;
  const AllowExtraDialog({super.key});

  @override
  State<AllowExtraDialog> createState() => _AllowExtraDialogState();
}

class _AllowExtraDialogState extends State<AllowExtraDialog> {
  Color barrierColor = Colors.black54;
  List<bool> selected = [false, false, false, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: barrierColor,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 600),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ai sẽ tham gia câu hỏi phụ?',
                style: TextStyle(fontSize: fontSizeMedium),
              ),
              SizedBox(height: widget.spacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                // mainAxisSize: MainAxisSize.min,
                children: [
                  for (final i in range(0, 3))
                    Expanded(
                      child: ChoiceChip(
                        visualDensity: VisualDensity.standard,
                        label: Text('${MatchState().players[i].name} (${MatchState().scores[i]})'),
                        selected: selected[i],
                        onSelected: (v) {
                          setState(() => selected[i] = v);
                        },
                      ),
                    )
                ],
              ),
              SizedBox(height: widget.spacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: selected.where((e) => e).length >= 2
                        ? () {
                            Future.delayed(50.ms, () => setState(() => barrierColor = Colors.transparent));
                            Navigator.of(context).pop(selected);
                          }
                        : null,
                    child: const Text('OK'),
                  ),
                  TextButton(
                    onPressed: Navigator.of(context).pop,
                    child: const Text('Kết thúc trận đấu luôn', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
