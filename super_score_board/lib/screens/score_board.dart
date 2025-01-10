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
  final bool isCountdownEnabled;

  const ScoreBoard({
    Key? key,
    required this.storageService,
    required this.leftPlayer,
    required this.rightPlayer,
    required this.defaultDuration,
    required this.isCountdownEnabled,
  }) : super(key: key);

  @override
  State<ScoreBoard> createState() => _ScoreBoardState();
}

class _ScoreBoardState extends State<ScoreBoard> with WidgetsBindingObserver {
  late Player leftPlayer;
  late Player rightPlayer;
  int leftScore = 0;
  int rightScore = 0;
  int _timeLeft = 0;
  bool isTimerRunning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    leftPlayer = widget.leftPlayer;
    rightPlayer = widget.rightPlayer;
    _timeLeft = widget.defaultDuration;
    _loadGameState();
    if (widget.isCountdownEnabled) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _saveGameState();
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
      isCountdownEnabled: widget.isCountdownEnabled,
    ));
  }

  Future<void> _loadGameState() async {
    final gameState = await widget.storageService.loadGameState();
    if (gameState != null) {
      setState(() {
        leftScore = gameState.leftScore;
        rightScore = gameState.rightScore;
        _timeLeft = gameState.timeLeft;
      });
    }
  }

  void _updateScore(bool isLeft, bool increment) {
    setState(() {
      if (isLeft) {
        leftScore += increment ? 1 : -1;
        if (leftScore < 0) leftScore = 0;
      } else {
        rightScore += increment ? 1 : -1;
        if (rightScore < 0) rightScore = 0;
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
    setState(() {
      isTimerRunning = !isTimerRunning;
    });
    if (isTimerRunning) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          _showGameOverDialog();
        }
      });
    });
  }

  void _showGameOverDialog() {
    String winner = leftScore > rightScore ? leftPlayer.name : rightPlayer.name;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('游戏结束'),
        content: Text('获胜方: $winner\n\n${leftPlayer.name}: $leftScore\n${rightPlayer.name}: $rightScore'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to StartScreen
            },
            child: const Text('返回主菜单'),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('反转显示'),
              trailing: Switch(
                value: false, // TODO: Implement invert display logic
                onChanged: (value) {
                  // TODO: Implement invert display logic
                },
              ),
            ),
            ListTile(
              title: const Text('背景音乐'),
              trailing: Switch(
                value: false, // TODO: Implement background music logic
                onChanged: (value) {
                  // TODO: Implement background music logic
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
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
          if (widget.isCountdownEnabled)
            Text(
              _formatTime(_timeLeft),
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          if (widget.isCountdownEnabled)
            IconButton(
              icon: Icon(isTimerRunning ? Icons.pause : Icons.play_arrow),
              onPressed: _showTimerDialog,
              color: Colors.white,
            ),
        ],
      ),
    );
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
