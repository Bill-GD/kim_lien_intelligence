import 'dart:typed_data';

class MatchData {
  // a singleton
  static final MatchData _singleton = MatchData._internal();
  factory MatchData() => _singleton;
  MatchData._internal();

  void setPos(int pos) {
    assert(pos >= 0 && pos < 4, 'Invalid player position: $pos');
    playerPos = pos;
  }

  // a list of players
  int playerPos = -1;
  final players = <Player>[];
  Question? currentQuestion;
}

class Player {
  final int pos;
  final String name;
  final Uint8List imageBytes;
  int point = 0;

  Player({required this.pos, required this.name, required this.imageBytes});
}

class Question {
  final String question;
  final Uint8List? mediaBytes;

  Question(this.question, {this.mediaBytes});
}
