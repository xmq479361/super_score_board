class GameSettings {
  final String leftPlayerId;
  final String rightPlayerId;
  final int duration;
  final bool isCountdownEnabled;

  GameSettings({
    required this.leftPlayerId,
    required this.rightPlayerId,
    required this.duration,
    required this.isCountdownEnabled,
  });

  Map<String, dynamic> toJson() => {
    'leftPlayerId': leftPlayerId,
    'rightPlayerId': rightPlayerId,
    'duration': duration,
    'isCountdownEnabled': isCountdownEnabled,
  };

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
    leftPlayerId: json['leftPlayerId'],
    rightPlayerId: json['rightPlayerId'],
    duration: json['duration'],
    isCountdownEnabled: json['isCountdownEnabled'],
  );
}

