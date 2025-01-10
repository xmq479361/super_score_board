class GameSettings {
  final String leftPlayerId;
  final String rightPlayerId;
  final int duration;
  final bool isRoundTimer;
  final int roundDuration;

  GameSettings({
    required this.leftPlayerId,
    required this.rightPlayerId,
    required this.duration,
    required this.isRoundTimer,
    required this.roundDuration,
  });

  Map<String, dynamic> toJson() => {
    'leftPlayerId': leftPlayerId,
    'rightPlayerId': rightPlayerId,
    'duration': duration,
    'isRoundTimer': isRoundTimer,
    'roundDuration': roundDuration,
  };

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
    leftPlayerId: json['leftPlayerId'],
    rightPlayerId: json['rightPlayerId'],
    duration: json['duration'],
    isRoundTimer: json['isRoundTimer'],
    roundDuration: json['roundDuration'],
  );
}

