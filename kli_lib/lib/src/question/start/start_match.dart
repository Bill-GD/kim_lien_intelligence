import '../../global_export.dart';
import 'start_question.dart';

class StartMatch implements BaseMatch {
  @override
  String match;
  Map<int, List<StartQuestion>> questions;

  int get questionCount => questions.values.fold(0, (a, b) => a + b.length);

  StartMatch({required this.match, required this.questions});

  Map<String, dynamic> toJson() => {
        'match': match,
        'questions': questions.map(
          (k, v) => MapEntry<String, List<Map<String, dynamic>>>(
            k.toString(),
            v.map((e) => e.toJson()).toList(),
          ),
        ),
      };

  factory StartMatch.fromJson(Map<String, dynamic> json) => StartMatch(
        match: json['match'],
        questions: (json['questions'] as Map<String, dynamic>).map(
          (k, v) => MapEntry<int, List<StartQuestion>>(
            int.parse(k),
            (v as List).map((e) => StartQuestion.fromJson(e)).toList(),
          ),
        ),
      );
}
