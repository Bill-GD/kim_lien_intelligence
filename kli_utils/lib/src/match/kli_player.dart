class KLIPlayer {
  String name;
  String imagePath;

  KLIPlayer(this.name, this.imagePath);

  Map<String, dynamic> toJson() => {
        'name': name,
        'imagePath': imagePath,
      };

  factory KLIPlayer.fromJson(Map<String, dynamic> json) {
    return KLIPlayer(
      json['name'],
      json['imagePath'],
    );
  }
}
