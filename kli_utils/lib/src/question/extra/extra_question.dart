class ExtraQuestion {
  final String question;
  final String answer;

  const ExtraQuestion({
    required this.question,
    required this.answer,
  });

  Map<String, dynamic> toJson() => {'question': question, 'answer': answer};

  factory ExtraQuestion.fromJson(Map<String, dynamic> json) =>
      ExtraQuestion(question: json['question'], answer: json['answer']);
}
