import 'package:kli_utils/src/question/obstable/obstacle_question.dart';

class ObstacleMatch {
  String match;
  String keyword;
  List<ObstacleQuestion> hintQuestions;
  String imagePath;
  String explanation;
  int charCount;

  ObstacleMatch({
    required this.match,
    required this.keyword,
    required this.hintQuestions,
    required this.imagePath,
    required this.explanation,
    required this.charCount,
  });

  Map<String, dynamic> toJson() => {
        'match': match,
        'keyword': keyword,
        'hintQuestions': hintQuestions.map((e) => e.toJson()).toList(),
        'imagePath': imagePath,
        'explanation': explanation,
        'charCount': charCount,
      };

  static ObstacleMatch fromJson(Map<String, dynamic> json) => ObstacleMatch(
        match: json['match'],
        keyword: json['keyword'],
        hintQuestions: (json['hintQuestions'] as List).map((e) => ObstacleQuestion.fromJson(e)).toList(),
        imagePath: json['imagePath'],
        explanation: json['explanation'],
        charCount: json['charCount'],
      );
}
