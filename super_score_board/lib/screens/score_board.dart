import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';
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
  final bool isRoundTimer;
  final int roundDuration;
  final bool isRestoredGame;

  const ScoreBoard({
    Key? key,
    required this.storageService,
    required this.leftPlayer,
    required this.rightPlayer,
    required this.defaultDuration,
    required this.isCountdownEnabled,
    required this.isRoundTimer,
    required this.roundDuration,
    required this.isRestoredGame,
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
  bool _isReversed = false;
  bool _showTotalTime = true;
  int _leftTotalTime = 0;
  int _rightTotalTime = 0;
  late AppSettings _appSettings;
  bool _isFaceToFace = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    leftPlayer = widget.leftPlayer;
    rightPlayer = widget.rightPlayer;
    _timeLeft = widget.defaultDuration;
    _loadAppSettings();
    if (widget.isRestoredGame) {
      _loadGameState();
    } else {
      _initializeNewGame();
    }
    if (widget.isCountdownEnabled) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _saveGameState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
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

  Future<void> _loadAppSettings() async {
    _appSettings = await widget.storageService.loadAppSettings();
    setState(() {
      _isReversed = _appSettings.isReversedDisplay;
      _showTotalTime = _appSettings.showTotalTime;
      _isFaceToFace = _appSettings.isFaceToFace;
    });
  }

  void _initializeNewGame() {
    setState(() {
      leftScore = 0;
      rightScore = 0;
      _leftTotalTime = 0;
      _rightTotalTime = 0;
      _timeLeft = widget.defaultDuration;
    });
  }

  void _saveGameState() {
    widget.storageService.saveGameState(GameState(
      leftPlayerId: leftPlayer.id,
      rightPlayerId: rightPlayer.id,
      leftScore: leftScore,
      rightScore: rightScore,
      timeLeft: _timeLeft,
      isCountdownEnabled: widget.isCountdownEnabled,
      leftTotalTime: _leftTotalTime,
      rightTotalTime: _rightTotalTime,
    ));
  }

  Future<void> _loadGameState() async {
    final gameState = await widget.storageService.loadGameState();
    if (gameState != null) {
      print("_loadGameState: ${gameState.toJson()}");
      setState(() {
        leftScore = gameState.leftScore;
        rightScore = gameState.rightScore;
        _timeLeft = gameState.timeLeft;
        _leftTotalTime = gameState.leftTotalTime;
        _rightTotalTime = gameState.rightTotalTime;
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
        print("_startTimer: $_timeLeft, ${_leftTotalTime}");
        if (_timeLeft > 0) {
          _timeLeft--;
          if (widget.isRoundTimer) {
            if (_isReversed) {
              _leftTotalTime++;
            } else {
              _rightTotalTime++;
            }
          }
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
        content: Text(
            '获胜方: $winner\n\n${leftPlayer.name}: $leftScore\n${rightPlayer.name}: $rightScore'),
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

  void _showSettings()  async {
    var value = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('面对面模式'),
                  value: _isFaceToFace,
                  onChanged: (value) {
                    setState(() => _isFaceToFace = value);
                    _appSettings.isFaceToFace = value;
                    widget.storageService.saveAppSettings(_appSettings);
                  },
                ),
                if (widget.isRoundTimer)
                  SwitchListTile(
                    title: const Text('显示总用时'),
                    value: _showTotalTime,
                    onChanged: (value) {
                      setState(() => _showTotalTime = value);
                      _appSettings.showTotalTime = value;
                      widget.storageService.saveAppSettings(_appSettings);
                    },
                  ),
                // SwitchListTile(
                //   title: const Text('背景音乐'),
                //   trailing: Switch(
                //     value: false, // TODO: Implement background music logic
                //     onChanged: (value) {
                //       // TODO: Implement background music logic
                //     },
                //   ),
                // ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
    setState(() {
    });
  }

  Widget _buildScoreSection(bool isLeft) {
    final player = isLeft ? leftPlayer : rightPlayer;
    var sideBoard = _buildSideScoreBoard(isLeft);
    if (_isFaceToFace) {
      sideBoard = Transform(
          transform: Matrix4.rotationZ(3.14159 * (isLeft ? 3 : 1) / 2),
          alignment: Alignment.center,
          child: sideBoard);
    }
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
                child: sideBoard,
              ))),
    );
  }

  Widget _buildSideScoreBoard(bool isLeft) {
    final player = isLeft ? leftPlayer : rightPlayer;
    final score = isLeft ? leftScore : rightScore;
    final totalTime = isLeft ? _leftTotalTime : _rightTotalTime;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          player.name,
          style: const TextStyle(fontSize: 24, color: Colors.white),
          textAlign:
              _isFaceToFace && !isLeft ? TextAlign.right : TextAlign.left,
        ),
        Text(
          score.toString(),
          style: const TextStyle(
            fontSize: 120,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign:
              _isFaceToFace && !isLeft ? TextAlign.right : TextAlign.left,
        ),
        if (widget.isRoundTimer && _showTotalTime)
          Text(
            '总用时: ${_formatTime(totalTime)}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
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
    );
  }

  Widget _buildControlBar() {
    return Container(
      color: Colors.black54,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
              style: const TextStyle(fontSize: 24, color: Colors.white),
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
    final scoreWidgets = [
      _buildScoreSection(true),
      _buildScoreSection(false),
    ];

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
                children:
                    _isReversed ? scoreWidgets.reversed.toList() : scoreWidgets,
              ),
            ),
            _buildControlBar(),
          ],
        ),
      ),
    );
  }
}
