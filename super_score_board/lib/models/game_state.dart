class GameState {
  final String leftPlayerId;
  final String rightPlayerId;
  final int leftScore;
  final int rightScore;
  final int timeLeft;
  final bool isCountdownEnabled;

  GameState({
    required this.leftPlayerId,
    required this.rightPlayerId,
    required this.leftScore,
    required this.rightScore,
    required this.timeLeft,
    required this.isCountdownEnabled,
  });

  Map<String, dynamic> toJson() => {
    'leftPlayerId': leftPlayerId,
    'rightPlayerId': rightPlayerId,
    'leftScore': leftScore,
    'rightScore': rightScore,
    'timeLeft': timeLeft,
    'isCountdownEnabled': isCountdownEnabled,
  };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
    leftPlayerId: json['leftPlayerId'],
    rightPlayerId: json['rightPlayerId'],
    leftScore: json['leftScore'],
    rightScore: json['rightScore'],
    timeLeft: json['timeLeft'],
    isCountdownEnabled: json['isCountdownEnabled'],
  );
}

