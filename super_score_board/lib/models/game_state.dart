class GameState {
  final String leftPlayerId;
  final String rightPlayerId;
  final int leftScore;
  final int rightScore;
  final int timeLeft;
  final bool isRoundTimer;
  final int roundTimeLeft;
  final bool isLeftPlayerTurn;

  GameState({
    required this.leftPlayerId,
    required this.rightPlayerId,
    required this.leftScore,
    required this.rightScore,
    required this.timeLeft,
    required this.isRoundTimer,
    required this.roundTimeLeft,
    required this.isLeftPlayerTurn,
  });

  Map<String, dynamic> toJson() => {
    'leftPlayerId': leftPlayerId,
    'rightPlayerId': rightPlayerId,
    'leftScore': leftScore,
    'rightScore': rightScore,
    'timeLeft': timeLeft,
    'isRoundTimer': isRoundTimer,
    'roundTimeLeft': roundTimeLeft,
    'isLeftPlayerTurn': isLeftPlayerTurn,
  };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
    leftPlayerId: json['leftPlayerId'],
    rightPlayerId: json['rightPlayerId'],
    leftScore: json['leftScore'],
    rightScore: json['rightScore'],
    timeLeft: json['timeLeft'],
    isRoundTimer: json['isRoundTimer'],
    roundTimeLeft: json['roundTimeLeft'],
    isLeftPlayerTurn: json['isLeftPlayerTurn'],
  );
}

