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
  String matchName = '';
}

class Player {
  final int pos;
  final String name;
  final String fullImagePath;
  int point = 0;

  Player({required this.pos, required this.name, required this.fullImagePath});
}
