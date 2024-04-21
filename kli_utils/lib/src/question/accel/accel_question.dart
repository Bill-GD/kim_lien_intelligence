/// IQ: 1 image, Arrange: 2 images, Sequence: 3+ images
enum AccelQuestionType { none, iq, arrange, sequence }

class AccelQuestion {
  AccelQuestionType type;
  final String question;
  final String answer;
  final String explanation;
  List<String> imagePaths;

  AccelQuestion({
    required this.type,
    required this.question,
    required this.answer,
    required this.imagePaths,
    this.explanation = '',
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'question': question,
        'answer': answer,
        'imagePaths': imagePaths,
        'explanation': explanation,
      };

  factory AccelQuestion.fromJson(Map<String, dynamic> json) {
    return AccelQuestion(
      type: getTypeFromImageCount((json['imagePaths'] as List).length),
      question: json['question'],
      answer: json['answer'],
      imagePaths: (json['imagePaths'] as List).map((e) => e.toString()).toList(),
      explanation: json['explanation'],
    );
  }

  static AccelQuestionType getTypeFromImageCount(int count) {
    if (count == 1) {
      return AccelQuestionType.iq;
    }
    if (count == 2) {
      return AccelQuestionType.arrange;
    }
    if (count >= 3) {
      return AccelQuestionType.sequence;
    }
    return AccelQuestionType.none;
  }

  static final _map = {
    AccelQuestionType.none: 'Không xác định',
    AccelQuestionType.iq: 'IQ',
    AccelQuestionType.arrange: 'Sắp xếp',
    AccelQuestionType.sequence: 'Chuỗi hình ảnh',
  };

  static String mapTypeDisplay(AccelQuestionType t) => _map[t]!;
}
