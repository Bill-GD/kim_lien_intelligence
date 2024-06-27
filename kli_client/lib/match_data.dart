import 'dart:typed_data';

class MatchData {
  // a singleton
  static final MatchData _singleton = MatchData._internal();
  factory MatchData() => _singleton;
  MatchData._internal();

  // a list of players
  final players = <Player>[];
  Question? currentQuestion;
}

class Player {
  final int pos;
  final String name;
  final Uint8List imageBytes;

  Player({required this.pos, required this.name, required this.imageBytes});
}

class Question {
  final String question;
  final Uint8List? mediaBytes;

  Question(this.question, {this.mediaBytes});
}
