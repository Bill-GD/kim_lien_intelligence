import 'dart:typed_data';

class MatchData {
  // a singleton
  static final MatchData _singleton = MatchData._internal();
  factory MatchData() => _singleton;
  MatchData._internal();

  // a list of players
  final List<Map<String, dynamic>> players = [];
  Question? currentQuestion;
}

class Question {
  String question;
  Uint8List? mediaBytes;

  Question(this.question, {this.mediaBytes});
}
