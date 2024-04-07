enum QuestionSubject { math, phys, chem, bio, literature, history, geo, english, sport, art, general }

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

  static final _map = {
    QuestionSubject.math: 'Toán',
    QuestionSubject.phys: 'Vật lý',
    QuestionSubject.chem: 'Hóa học',
    QuestionSubject.bio: 'Sinh học',
    QuestionSubject.literature: 'Văn học',
    QuestionSubject.history: 'Lịch sử',
    QuestionSubject.geo: 'Địa lý',
    QuestionSubject.english: 'Tiếng Anh',
    QuestionSubject.sport: 'Thể thao',
    QuestionSubject.art: 'Nghệ thuật',
    QuestionSubject.general: 'HBC',
  };

  static String mapTypeDisplay(QuestionSubject t) => _map[t]!;

  static QuestionSubject mapType(String v) => _map.entries.firstWhere((e) => e.value == v).key;
}
