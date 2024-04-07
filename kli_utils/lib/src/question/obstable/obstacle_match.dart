import 'package:kli_utils/src/question/obstable/obstacle_question.dart';

class ObstacleMatch {
  final String keyword;
  final List<ObstacleQuestion> hintQuestions;
  final String imagePath;
  final String explanation;
  final int charCount;

  ObstacleMatch({
    required this.keyword,
    required this.hintQuestions,
    required this.imagePath,
    required this.explanation,
    required this.charCount,
  });

  Map<String, dynamic> toJson() => {
        'keyword': keyword,
        'hintQuestions': hintQuestions.map((e) => e.toJson()).toList(),
        'imagePath': imagePath,
        'explanation': explanation,
        'charCount': charCount,
      };

  static ObstacleMatch fromJson(Map<String, dynamic> json) => ObstacleMatch(
        keyword: json['keyword'],
        hintQuestions: (json['hintQuestions'] as List).map((e) => ObstacleQuestion.fromJson(e)).toList(),
        imagePath: json['imagePath'],
        explanation: json['explanation'],
        charCount: json['charCount'],
      );
}
