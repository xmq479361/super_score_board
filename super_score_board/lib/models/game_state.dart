class GameState {
  final String leftPlayerId;
  final String rightPlayerId;
  final int leftScore;
  final int rightScore;
  final int timeLeft;
  final bool isCountdownEnabled;
  final int leftTotalTime;
  final int rightTotalTime;

  GameState({
    required this.leftPlayerId,
    required this.rightPlayerId,
    required this.leftScore,
    required this.rightScore,
    required this.timeLeft,
    required this.isCountdownEnabled,
    required this.leftTotalTime,
    required this.rightTotalTime,
  });

  Map<String, dynamic> toJson() => {
    'leftPlayerId': leftPlayerId,
    'rightPlayerId': rightPlayerId,
    'leftScore': leftScore,
    'rightScore': rightScore,
    'timeLeft': timeLeft,
    'isCountdownEnabled': isCountdownEnabled,
    'leftTotalTime': leftTotalTime,
    'rightTotalTime': rightTotalTime,
  };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
    leftPlayerId: json['leftPlayerId'],
    rightPlayerId: json['rightPlayerId'],
    leftScore: json['leftScore'],
    rightScore: json['rightScore'],
    timeLeft: json['timeLeft'],
    isCountdownEnabled: json['isCountdownEnabled'],
    leftTotalTime: json['leftTotalTime'],
    rightTotalTime: json['rightTotalTime'],
  );
}

