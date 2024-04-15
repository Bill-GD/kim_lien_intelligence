import '../../global_export.dart';
import 'finish_question.dart';

class FinishMatch implements BaseMatch {
  @override
  String match;
  List<FinishQuestion> questions;

  FinishMatch({required this.match, required this.questions});

  Map<String, dynamic> toJson() => {
        'match': match,
        'questions': questions.map((e) => e.toJson()).toList(),
      };

  factory FinishMatch.fromJson(Map<String, dynamic> json) => FinishMatch(
        match: json['match'],
        questions: (json['questions'] as List).map((e) => FinishQuestion.fromJson(e)).toList(),
      );
}
