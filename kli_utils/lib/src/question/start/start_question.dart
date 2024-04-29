enum StartQuestionSubject { math, phys, chem, bio, literature, history, geo, english, sport, art, general }

class StartQuestion {
  final StartQuestionSubject subject;
  final String question;
  final String answer;

  const StartQuestion({required this.subject, required this.question, required this.answer});

  Map<String, dynamic> toJson() => {
        'subject': subject.name,
        'question': question,
        'answer': answer,
      };

  factory StartQuestion.fromJson(Map<String, dynamic> json) {
    return StartQuestion(
      subject: StartQuestionSubject.values.byName(json['subject']),
      question: json['question'],
      answer: json['answer'],
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
