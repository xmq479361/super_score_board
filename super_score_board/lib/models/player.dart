import 'package:flutter/material.dart';

class Player {
  final String id;
  String name;
  Color color;
  int highestScore;
  int totalGames;
  int wonGames;

  Player({
    required this.id,
    required this.name,
    required this.color,
    this.highestScore = 0,
    this.totalGames = 0,
    this.wonGames = 0,
  });

  double get winRate => totalGames == 0 ? 0 : wonGames / totalGames;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.value,
        'highestScore': highestScore,
        'totalGames': totalGames,
        'wonGames': wonGames,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'],
        name: json['name'],
        color: Color(json['color']),
        highestScore: json['highestScore'],
        totalGames: json['totalGames'],
        wonGames: json['wonGames'],
      );
}
