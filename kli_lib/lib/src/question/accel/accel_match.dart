import '../../global_export.dart';
import 'accel_question.dart';

class AccelMatch implements BaseMatch {
  @override
  String match;
  List<AccelQuestion?> questions;

  AccelMatch({required this.match, required this.questions});

  Map<String, dynamic> toJson() => {
        'match': match,
        'questions': questions.map((e) => e?.toJson()).toList(),
      };

  factory AccelMatch.fromJson(Map<String, dynamic> json) {
    return AccelMatch(
      match: json['match'],
      questions:
          (json['questions'] as List).map((e) => e == null ? null : AccelQuestion.fromJson(e)).toList(),
    );
  }
}
