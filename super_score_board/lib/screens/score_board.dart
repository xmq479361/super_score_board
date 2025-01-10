import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game_record.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../services/storage_service.dart';
import '../widgets/player_edit_dialog.dart';

class ScoreBoard extends StatefulWidget {
  final StorageService storageService;
  final Player leftPlayer;
  final Player rightPlayer;
  final int defaultDuration;
  final bool isRoundTimer;
  final int roundDuration;

  const ScoreBoard({
    super.key,
    required this.storageService,
    required this.leftPlayer,
    required this.rightPlayer,
    required this.defaultDuration,
    required this.isRoundTimer,
    required this.roundDuration,
  });

  @override
  State<ScoreBoard> createState() => _ScoreBoardState();
}

class _ScoreBoardState extends State<ScoreBoard> with WidgetsBindingObserver {
  late Player leftPlayer;
  late Player rightPlayer;
  int leftScore = 0;
  int rightScore = 0;
  bool isInverted = false;
  Timer? _timer;
  int _timeLeft = 0;
  bool isTimerRunning = false;
  bool isLeftPlayerTurn = true;
  int _roundTimeLeft = 0;
  late GameRecord currentGame;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    leftPlayer = widget.leftPlayer;
    rightPlayer = widget.rightPlayer;
    currentGame = GameRecord(
      id: DateTime.now().toString(),
      leftPlayerId: leftPlayer.id,
      rightPlayerId: rightPlayer.id,
      startTime: DateTime.now(),
      duration: widget.defaultDuration,
      leftScore: 0,
      rightScore: 0,
    );
    _timeLeft = widget.defaultDuration;
    _roundTimeLeft = widget.roundDuration;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveGameState();
    } else if (state == AppLifecycleState.resumed) {
      _loadGameState();
    }
  }

  void _saveGameState() {
    widget.storageService.saveGameState(GameState(
      leftPlayerId: leftPlayer.id,
      rightPlayerId: rightPlayer.id,
      leftScore: leftScore,
      rightScore: rightScore,
      timeLeft: _timeLeft,
      isRoundTimer: widget.isRoundTimer,
      roundTimeLeft: _roundTimeLeft,
      isLeftPlayerTurn: isLeftPlayerTurn,
    ));
  }

  Future<void> _loadGameState() async {
    final gameState = await widget.storageService.loadGameState();
    if (gameState != null) {
      setState(() {
        leftScore = gameState.leftScore;
        rightScore = gameState.rightScore;
        _timeLeft = gameState.timeLeft;
        _roundTimeLeft = gameState.roundTimeLeft;
        isLeftPlayerTurn = gameState.isLeftPlayerTurn;
      });
    }
  }

  void _updateScore(bool isLeft, bool increment) {
    setState(() {
      if (isLeft) {
        leftScore += increment ? 1 : -1;
      } else {
        rightScore += increment ? 1 : -1;
      }
    });
  }

  void _editPlayerInfo(bool isLeft) {
    showDialog(
      context: context,
      builder: (context) => PlayerEditDialog(
        player: isLeft ? leftPlayer : rightPlayer,
        onSave: (updatedPlayer) {
          setState(() {
            if (isLeft) {
              leftPlayer = updatedPlayer;
            } else {
              rightPlayer = updatedPlayer;
            }
          });
        },
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = (seconds / 60).floor();
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('倒计时设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add timer settings here
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Handle timer settings changes
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    // Implement settings dialog
  }

    Widget _buildScoreSection(bool isLeft) {
      final player = isLeft ? leftPlayer : rightPlayer;
      final score = isLeft ? leftScore : rightScore;
    return Expanded(
      child: GestureDetector(
        onTap: () => _updateScore(isLeft, true),
        onVerticalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dy > 0) {
            _updateScore(isLeft, true);
          } else if (details.velocity.pixelsPerSecond.dy < 0) {
            _updateScore(isLeft, false);
          }
        },
        onLongPress: () => _editPlayerInfo(isLeft),
        child: Container(
          color: player.color,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                Text(
                  score.toString(),
                  style: const TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Text(
                //   '历史最高: ${player.highestScore}',
                //   style: const TextStyle(
                //     fontSize: 16,
                //     color: Colors.white70,
                //   ),
                // ),
                // Text(
                //   '胜率: ${(player.winRate * 100).toStringAsFixed(1)}%',
                //   style: const TextStyle(
                //     fontSize: 16,
                //     color: Colors.white70,
                //   ),
                // ),
                if (widget.isRoundTimer)
                  Text(
                    isLeft == isLeftPlayerTurn ? '当前回合' : '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
            color: Colors.white,
          ),
          if (widget.isRoundTimer)
            Text(
              '回合时间: ${_formatTime(_roundTimeLeft)}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            )
          else
            Text(
              _formatTime(_timeLeft),
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          if (widget.isRoundTimer)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: _switchTurn,
              color: Colors.white,
            )
          else
            IconButton(
              icon: Icon(isTimerRunning ? Icons.pause : Icons.play_arrow),
              onPressed: () => _showTimerDialog(),
              color: Colors.white,
            ),
        ],
      ),
    );
  }

  void _switchTurn() {
    setState(() {
      isLeftPlayerTurn = !isLeftPlayerTurn;
      _roundTimeLeft = widget.roundDuration;
    });
    _startRoundTimer();
  }

  void _startRoundTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_roundTimeLeft > 0) {
          _roundTimeLeft--;
        } else {
          _timer?.cancel();
          _switchTurn();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _saveGameState();
        return true;
      },
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  _buildScoreSection(true),
                  _buildScoreSection(false),
                ],
              ),
            ),
            _buildControlBar(),
          ],
        ),
      ),
    );
  }
}
