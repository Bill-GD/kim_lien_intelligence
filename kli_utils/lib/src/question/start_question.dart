enum QuestionSubject {
  english,
}

class StartQuestion {
  QuestionSubject subject;
  String question;
  String answer;

  StartQuestion(this.subject, this.question, this.answer);

  Map<String, dynamic> toJson() => {
        'subject': subject.name,
        'question': question,
        'answer': answer,
      };

  factory StartQuestion.fromJson(Map<String, dynamic> json) {
    return StartQuestion(
      QuestionSubject.values.byName(json['subject']),
      json['question'],
      json['answer'],
    );
  }
}
