import 'kli_player.dart';

/// Represents a Match, containing the name of the match and the list of players.
class KLIMatch {
  final String name;
  final List<KLIPlayer?> playerList;

  KLIMatch(this.name, this.playerList);

  Map<String, dynamic> toJson() => {
        'name': name,
        'playerList': playerList.map((e) => e?.toJson()).toList(),
      };

  factory KLIMatch.fromJson(Map<String, dynamic> json) {
    return KLIMatch(
      json['name'],
      List<KLIPlayer?>.from(json['playerList'].map((e) => e == null ? null : KLIPlayer.fromJson(e))),
    );
  }
}
