import 'extra_question.dart';

class ExtraMatch {
  String match;
  List<ExtraQuestion> questions;

  ExtraMatch({required this.match, required this.questions});

  Map<String, dynamic> toJson() => {
        'match': match,
        'questions': questions.map((e) => e.toJson()).toList(),
      };

  factory ExtraMatch.fromJson(Map<String, dynamic> json) {
    return ExtraMatch(
      match: json['match'],
      questions: (json['questions'] as List).map((e) => ExtraQuestion.fromJson(e)).toList(),
    );
  }
}
