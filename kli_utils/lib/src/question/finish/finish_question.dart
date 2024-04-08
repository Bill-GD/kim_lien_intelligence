class FinishQuestion {
  int point;
  String question;
  String answer;
  String explanation;
  String mediaPath;

  FinishQuestion({
    required this.point,
    required this.question,
    required this.answer,
    this.explanation = '',
    this.mediaPath = '',
  });

  Map<String, dynamic> toJson() => {
        'point': point,
        'question': question,
        'answer': answer,
        'explanation': explanation,
        'mediaPath': mediaPath,
      };

  factory FinishQuestion.fromJson(Map<String, dynamic> json) => FinishQuestion(
        point: json['point'],
        question: json['question'],
        answer: json['answer'],
        explanation: json['explanation'],
        mediaPath: json['mediaPath'],
      );
}
