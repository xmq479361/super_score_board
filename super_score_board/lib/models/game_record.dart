class GameRecord {
  final String id;
  final String leftPlayerId;
  final String rightPlayerId;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration;
   int leftScore;
   int rightScore;

  GameRecord({
    required this.id,
    required this.leftPlayerId,
    required this.rightPlayerId,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.leftScore,
    required this.rightScore,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'leftPlayerId': leftPlayerId,
    'rightPlayerId': rightPlayerId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'duration': duration,
    'leftScore': leftScore,
    'rightScore': rightScore,
  };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
    id: json['id'],
    leftPlayerId: json['leftPlayerId'],
    rightPlayerId: json['rightPlayerId'],
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    duration: json['duration'],
    leftScore: json['leftScore'],
    rightScore: json['rightScore'],
  );

  GameRecord copyWith({
    String? id,
    String? leftPlayerId,
    String? rightPlayerId,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    int? leftScore,
    int? rightScore,
  }) {
    return GameRecord(
      id: id ?? this.id,
      leftPlayerId: leftPlayerId ?? this.leftPlayerId,
      rightPlayerId: rightPlayerId ?? this.rightPlayerId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      leftScore: leftScore ?? this.leftScore,
      rightScore: rightScore ?? this.rightScore,
    );
  }
}