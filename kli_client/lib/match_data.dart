import 'dart:typed_data';

class MatchData {
  // a singleton
  static final MatchData _singleton = MatchData._internal();
  factory MatchData() => _singleton;
  MatchData._internal();

  void setPlayerReady(int pos) => players
      .firstWhere(
        (element) => element.pos == pos,
        orElse: () => throw Exception('No player found'),
      )
      .ready = true;

  // a list of players
  final players = <Player>[];
  Question? currentQuestion;
}

class Player {
  final int pos;
  final String name;
  final Uint8List imageBytes;
  bool ready = false;

  Player({required this.pos, required this.name, required this.imageBytes});
}

class Question {
  final String question;
  final Uint8List? mediaBytes;

  Question(this.question, {this.mediaBytes});
}
