class ObstacleQuestion {
  final int id;
  final String question;
  final String answer;

  ObstacleQuestion(this.id, this.question, this.answer);

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'answer': answer,
      };

  factory ObstacleQuestion.fromJson(Map<String, dynamic> json) {
    return ObstacleQuestion(
      int.parse(json['id']),
      json['question'],
      json['answer'],
    );
  }
}
