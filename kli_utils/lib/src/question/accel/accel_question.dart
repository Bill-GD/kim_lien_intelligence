class AccelQuestion {
  final String question;
  final String answer;
  final String explanation;
  List<String> imagePaths;

  AccelQuestion({
    required this.question,
    required this.answer,
    required this.explanation,
    required this.imagePaths,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
        'explanation': explanation,
        'imagePaths': imagePaths,
      };

  factory AccelQuestion.fromJson(Map<String, dynamic> json) {
    return AccelQuestion(
      question: json['question'],
      answer: json['answer'],
      explanation: json['explanation'],
      imagePaths: (json['imagePaths'] as List).map((e) => e.toString()).toList(),
    );
  }
}
