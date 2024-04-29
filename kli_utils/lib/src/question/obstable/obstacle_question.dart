class ObstacleQuestion {
  final int id;
  final String question;
  final String answer;
  final int charCount;

  ObstacleQuestion({
    required this.id,
    required this.question,
    required this.answer,
    required this.charCount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'answer': answer,
        'charCount': charCount,
      };

  factory ObstacleQuestion.fromJson(Map<String, dynamic> json) {
    return ObstacleQuestion(
      id: json['id'],
      question: json['question'],
      answer: json['answer'],
      charCount: json['charCount'],
    );
  }
}
