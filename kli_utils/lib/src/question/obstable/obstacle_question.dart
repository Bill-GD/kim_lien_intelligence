class ObstacleQuestion {
  final int id;
  final String question;
  final String answer;
  final int charCount;

  const ObstacleQuestion(this.id, this.question, this.answer, this.charCount);

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'answer': answer,
        'charCount': charCount,
      };

  factory ObstacleQuestion.fromJson(Map<String, dynamic> json) {
    return ObstacleQuestion(
      json['id'],
      json['question'],
      json['answer'],
      json['charCount'],
    );
  }
}
