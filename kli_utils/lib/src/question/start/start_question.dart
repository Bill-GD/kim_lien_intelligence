enum StartQuestionSubject { math, phys, chem, bio, literature, history, geo, english, sport, art, general }

class StartQuestion {
  final StartQuestionSubject subject;
  final String question;
  final String answer;

  const StartQuestion(this.subject, this.question, this.answer);

  Map<String, dynamic> toJson() => {
        'subject': subject.name,
        'question': question,
        'answer': answer,
      };

  factory StartQuestion.fromJson(Map<String, dynamic> json) {
    return StartQuestion(
      StartQuestionSubject.values.byName(json['subject']),
      json['question'],
      json['answer'],
    );
  }

  static final _map = {
    StartQuestionSubject.math: 'Toán',
    StartQuestionSubject.phys: 'Vật lý',
    StartQuestionSubject.chem: 'Hóa học',
    StartQuestionSubject.bio: 'Sinh học',
    StartQuestionSubject.literature: 'Văn học',
    StartQuestionSubject.history: 'Lịch sử',
    StartQuestionSubject.geo: 'Địa lý',
    StartQuestionSubject.english: 'Tiếng Anh',
    StartQuestionSubject.sport: 'Thể thao',
    StartQuestionSubject.art: 'Nghệ thuật',
    StartQuestionSubject.general: 'HBC',
  };

  static String mapTypeDisplay(StartQuestionSubject t) => _map[t]!;

  static StartQuestionSubject mapTypeValue(String v) => _map.entries.firstWhere((e) => e.value == v).key;
}
