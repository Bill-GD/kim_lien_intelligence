import '../../global_export.dart';
import 'obstacle_question.dart';

class ObstacleMatch extends BaseMatch {
  String keyword;
  List<ObstacleQuestion?> hintQuestions;
  String imagePath;
  String explanation;
  int charCount;

  ObstacleMatch({
    required super.match,
    required this.keyword,
    required this.hintQuestions,
    required this.imagePath,
    required this.explanation,
    required this.charCount,
  });

  Map<String, dynamic> toJson() => {
        'match': match,
        'keyword': keyword,
        'hintQuestions': hintQuestions.map((e) => e?.toJson()).toList(),
        'imagePath': imagePath,
        'explanation': explanation,
        'charCount': charCount,
      };

  factory ObstacleMatch.fromJson(Map<String, dynamic> json) => ObstacleMatch(
        match: json['match'],
        keyword: json['keyword'],
        hintQuestions: (json['hintQuestions'] as List)
            .map((e) => e == null ? null : ObstacleQuestion.fromJson(e))
            .toList(),
        imagePath: json['imagePath'],
        explanation: json['explanation'],
        charCount: json['charCount'],
      );
}
