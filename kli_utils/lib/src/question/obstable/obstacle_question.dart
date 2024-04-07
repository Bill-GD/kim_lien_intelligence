class ObstacleQuestion {
  final int id;
  final String question;
  final String answer;
  final int charCount;

  ObstacleQuestion(this.id, this.question, this.answer, this.charCount);

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'answer': answer,
        'charCount': charCount,
      };

  factory ObstacleQuestion.fromJson(Map<String, dynamic> json) {
    return ObstacleQuestion(
      int.parse(json['id']),
      json['question'],
      json['answer'],
      int.parse(json['charCount']),
    );
  }
}
