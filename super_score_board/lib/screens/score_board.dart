import 'dart:async';
import 'dart:math';

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

class _ScoreBoardState extends State<ScoreBoard>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late Player leftPlayer;
  late Player rightPlayer;
  int leftScore = 0;
  int rightScore = 0;
  int _timeLeft = 0;
  bool isTimerRunning = false;
  Timer? _timer;
  int _leftTotalTime = 0;
  int _rightTotalTime = 0;
  late AppSettings _appSettings;
  bool _isOverlayVisible = true;
  bool _isLeftPlayerActive = true;
  int _roundTimeLeft = 0;

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
    _roundTimeLeft = widget.roundDuration;
    _loadAppSettings();
    if (widget.isRestoredGame) {
      _loadGameState();
    } else {
      _initializeNewGame();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCountdown();
    });
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
    setState(() {});
  }

  void _initializeNewGame() {
    setState(() {
      leftScore = 0;
      rightScore = 0;
      _leftTotalTime = 0;
      _rightTotalTime = 0;
      _timeLeft = widget.defaultDuration;
      _roundTimeLeft = widget.roundDuration;
      _isLeftPlayerActive = true;
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
      isLeftPlayerActive: _isLeftPlayerActive,
      roundTimeLeft: _roundTimeLeft,
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
        _isLeftPlayerActive = gameState.isLeftPlayerActive;
        _roundTimeLeft = gameState.roundTimeLeft;
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

  Future<void> _editPlayerInfo(bool isLeft) async {
    final updatedPlayer = await showDialog<Player>(
      context: context,
      builder: (context) => PlayerEditDialog(
        player: isLeft ? leftPlayer : rightPlayer,
        onSave: (player) {},
      ),
    );
    if (updatedPlayer != null) {
      setState(() {
        if (isLeft) {
          leftPlayer = updatedPlayer;
        } else {
          rightPlayer = updatedPlayer;
        }
      });
    }
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
    isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (widget.isCountdownEnabled && _timeLeft > 0) {
          _timeLeft--;
        } else {
          _timeLeft--;
        }
        if (widget.isRoundTimer) {
          _roundTimeLeft--;
          if (_roundTimeLeft <= 0) {
            _switchActivePlayer();
          }
        }
        if (_isLeftPlayerActive) {
          _leftTotalTime++;
        } else {
          _timer?.cancel();
          _showGameOverDialog();
          _rightTotalTime++;
        }
      });
    });
  }

  void _switchActivePlayer() {
    setState(() {
      _isLeftPlayerActive = !_isLeftPlayerActive;
      _roundTimeLeft = widget.roundDuration;
    });
  }

  void _showGameOverDialog() {
    String winner = leftScore > rightScore ? leftPlayer.name : rightPlayer.name;
    Player winningPlayer = leftScore > rightScore ? leftPlayer : rightPlayer;
    Player losingPlayer = leftScore > rightScore ? rightPlayer : leftPlayer;

    winningPlayer.wonGames++;
    winningPlayer.totalGames++;
    losingPlayer.totalGames++;

    if (leftScore > winningPlayer.highestScore) {
      winningPlayer.highestScore = leftScore;
    }
    if (rightScore > losingPlayer.highestScore) {
      losingPlayer.highestScore = rightScore;
    }

    widget.storageService.savePlayers([winningPlayer, losingPlayer]);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('游戏结束'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('获胜方: $winner'),
            const SizedBox(height: 16),
            Text('${leftPlayer.name}: $leftScore'),
            Text('最高分: ${leftPlayer.highestScore}'),
            Text(
                '胜率: ${(leftPlayer.wonGames / leftPlayer.totalGames * 100).toStringAsFixed(2)}%'),
            const SizedBox(height: 8),
            Text('${rightPlayer.name}: $rightScore'),
            Text('最高分: ${rightPlayer.highestScore}'),
            Text(
                '胜率: ${(rightPlayer.wonGames / rightPlayer.totalGames * 100).toStringAsFixed(2)}%'),
          ],
        ),
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

  void _showSettings() async {
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
                  value: _appSettings.isFaceToFace,
                  onChanged: (value) {
                    setState(() => _appSettings.isFaceToFace = value);
                    _appSettings.isFaceToFace = value;
                    widget.storageService.saveAppSettings(_appSettings);
                  },
                ),
                if (widget.isRoundTimer)
                  SwitchListTile(
                    title: const Text('显示总用时'),
                    value: _appSettings.showTotalTime,
                    onChanged: (value) {
                      setState(() => _appSettings.showTotalTime = value);
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
    setState(() {});
  }

  void _startCountdown() {
    setState(() {
      _isOverlayVisible = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isOverlayVisible = false;
        });
        _startTimer();
      }
    });
  }

  Widget _buildScoreSection(bool isLeft) {
    final player = isLeft ? leftPlayer : rightPlayer;
    final isActive = isLeft ? _isLeftPlayerActive : !_isLeftPlayerActive;
    var sideBoard = _buildSideScoreBoard(isLeft);
    if (_appSettings.isFaceToFace) {
      sideBoard = Transform(
          transform: Matrix4.rotationZ(3.14159 * (isLeft ? 3 : 1) / 2),
          alignment: Alignment.center,
          child: sideBoard);
    }
    // return Expanded(child: ScoreboardView(onChanged: (value){
    //   if (isLeft) {
    //     leftScore = value;
    //   } else {
    //     rightScore = value;
    //   }
    // }, initialScore: 0, player: player));
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
            color: player.color, //.withOpacity(isActive ? 1.0 : 0.5),
            child: Center(child: sideBoard)),
      ),
    );
  }

  Widget _buildSideScoreBoard(bool isLeft) {
    final player = isLeft ? leftPlayer : rightPlayer;
    final score = isLeft ? leftScore : rightScore;
    final totalTime = isLeft ? _leftTotalTime : _rightTotalTime;
    final isActive = isLeft ? _isLeftPlayerActive : !_isLeftPlayerActive;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          player.name,
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: _appSettings.isFaceToFace && !isLeft
              ? TextAlign.right
              : TextAlign.left,
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1), // 从下方滑入
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
          child: Text(
            score.toString(),
            style: const TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: _appSettings.isFaceToFace && !isLeft
                ? TextAlign.right
                : TextAlign.left,
          ),
        ),
        // AnimatedBuilder(
        //
        //     animation: _scoreAnimation,
        //     builder: (context, child) {
        //       final displayScore = previousScore +
        //           (_scoreAnimation.value * (score - previousScore)).round();
        //       return Text(
        //         displayScore.toString(),
        //         style: const TextStyle(
        //           fontSize: 120,
        //           fontWeight: FontWeight.bold,
        //           color: Colors.white,
        //         ),
        //         textAlign:
        //             _isFaceToFace && !isLeft ? TextAlign.right : TextAlign.left,
        //       );
        //     }),
        // Text(
        //   score.toString(),
        //   style: const TextStyle(
        //     fontSize: 120,
        //     fontWeight: FontWeight.bold,
        //     color: Colors.white,
        //   ),
        //   textAlign:
        //       _isFaceToFace && !isLeft ? TextAlign.right : TextAlign.left,
        // ),
        if (widget.isRoundTimer && _appSettings.showTotalTime)
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
          Text(
            _formatTime(_timeLeft),
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: Icon(isTimerRunning ? Icons.pause : Icons.play_arrow),
            onPressed: _showTimerDialog,
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () {
              setState(() {
                _appSettings.isReversedDisplay =
                    !_appSettings.isReversedDisplay;
                widget.storageService.saveAppSettings(_appSettings);
              });
            },
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('结束游戏'),
            content: const Text('确定要结束当前游戏吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  _saveGameState();
                  Navigator.of(context).pop(true);
                },
                child: const Text('确定'),
              ),
            ],
          ),
        );
        if (shouldPop ?? false == true) {
          Navigator.of(context).pop(true);
        }
      },
        child: Scaffold(
          body: Column(
              children: [
                _buildControlBar(),
                Expanded(
                  child: Stack(
                    children: [
                      Row(
                        children: _appSettings.isReversedDisplay ? scoreWidgets.reversed.toList() : scoreWidgets,
                      ),
                      if (_isOverlayVisible)
                        Container(
                          color: Colors.black.withOpacity(0.7),
                          child: Center(
                            child: TweenAnimationBuilder<int>(
                              tween: IntTween(begin: 3, end: 0),
                              duration: const Duration(seconds: 3),
                              builder: (BuildContext context, int value, Widget? child) {
                                return Text(
                                  value.toString(),
                                  style: const TextStyle(fontSize: 72, color: Colors.white),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),]),));
    //   child: Scaffold(
    //     body: Stack(children: [
    //       _buildControlBar(),
    //       Column(
    //         children: [
    //           _buildControlBar(),
    //           Expanded(
    //             child: Row(
    //               children: _appSettings.isReversedDisplay
    //                   ? scoreWidgets.reversed.toList()
    //                   : scoreWidgets,
    //             ),
    //           ),
    //         ],
    //       ),
    //       if (_isOverlayVisible)
    //         Container(
    //           color: Colors.black.withOpacity(0.7),
    //           child: Center(
    //             child: TweenAnimationBuilder<int>(
    //               tween: IntTween(begin: 3, end: 1),
    //               duration: const Duration(seconds: 3),
    //               builder: (BuildContext context, int value, Widget? child) {
    //                 return Text(
    //                   value.toString(),
    //                   style: const TextStyle(fontSize: 72, color: Colors.white),
    //                 );
    //               },
    //             ),
    //           ),
    //         ),
    //     ]),
    //   ),
    // );
  }
}

class ScoreboardView extends StatefulWidget {
  final ValueChanged onChanged;
  final Player player;
  final int initialScore;

  const ScoreboardView(
      {super.key,
      required this.onChanged,
      required this.initialScore,
      required this.player});

  @override
  _ScoreboardViewState createState() => _ScoreboardViewState();
}

class _ScoreboardViewState extends State<ScoreboardView>
    with SingleTickerProviderStateMixin {
  late int _score; // 当前分数
  late AnimationController _controller; // 动画控制器
  late Animation<double> _animation; // 翻页动画
  bool _isAnimating = false; // 动画中标记
  String _currentDisplay = "0"; // 当前显示的分数
  String _nextDisplay = "1"; // 下一页显示的分数
  int offset = 0; // 方向, increment
  double _dragStartOffset = 0.0; // 滑动起始点
  final double _dragDistance = 200.0; // 滑动距离的阈值

  @override
  void initState() {
    super.initState();
    _score = widget.initialScore;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = Tween<double>(begin: 0, end: pi * 2).animate(_controller)
      ..addStatusListener((status) {
        print("animated completed: $status");
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          // 动画完成后更新分数显示
          setState(() {
            _currentDisplay = _nextDisplay;
            _isAnimating = false;
            _controller.reset();
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    _dragStartOffset = details.globalPosition.dy;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;

    final dragDelta = details.globalPosition.dy - _dragStartOffset;
    final progress =
        (dragDelta / _dragDistance).clamp(-1.0, 1.0); // 将滑动比例限制在 -1 到 1
    _currentDisplay = _score.toString();
    if (progress > 0) {
      offset = -1; // 下滑：减少分数
    } else {
      offset = 1; // 上滑：增加分数
    }
    _nextDisplay = max(_score + offset, 0).toString();
    // 设置动画进度（取绝对值）
    _controller.value = ((1 - progress) % 1).abs();
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isAnimating) return;
    final currentValue = _controller.value;
    final newValue = int.parse(_nextDisplay);

    print("\t\t_onDragEnd $_score -> $newValue, ${currentValue}");
    if (newValue > _score) {
      if (currentValue > 0.25) {
        print("_onDragEnd $_score -> $newValue");
        setState(() {
          _score = newValue;
          _controller.forward(from: currentValue); // 完成动画
        });
        widget.onChanged(_score);
      } else {
        _controller.reverse(from: currentValue); // 回到初始位置
      }
    } else if (newValue < _score) {
      if (currentValue < 0.75) {
        print("_onDragEnd $_score -> $newValue");
        setState(() {
          _score = newValue;
          // 回弹
          _controller.reverse(from: currentValue); // 回到初始位置
        });
        widget.onChanged(_score);
      } else {
        _controller.forward(from: currentValue); // 回到初始位置
      }
    }
    _nextDisplay = _score.toString();
  }

  void _startFlipAnimation(int newScore, {forward = true}) {
    if (_isAnimating) return; // 如果动画正在进行，不响应
    setState(() {
      _isAnimating = true;
      _nextDisplay = newScore.toString();
      _score = newScore;
      print("_startFlipAnimation $forward");
      if (forward) {
        _controller.forward(from: 0);
      } else {
        _controller.reverse(from: 1.0);
      }
    });
    widget.onChanged(_score);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: _onDragStart,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      onTap: () => _startFlipAnimation(_score + 1),
      child: Container(
        color: widget.player.color, //Colors.blueGrey,
        child: Center(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final angle = _animation.value;
              final curVal = int.parse(_currentDisplay);
              final nextVal = int.parse(_nextDisplay);
              var showValue = max(curVal, nextVal).toString();
              var flipValue = min(curVal, nextVal).toString();
              return Stack(children: [
                if (angle <= pi) ...{
                  _buildCard(showValue, true), // 背面
                },
                Transform(
                    alignment: Alignment.topCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX(angle),
                    child: _buildCard(flipValue, angle <= pi / 2)),
                if (angle > pi) ...{
                  _buildCard(showValue, true), // 背面
                },
              ]);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String text, bool isFront) {
    return Container(
      width: 200,
      height: 300,
      decoration: BoxDecoration(
        color: isFront ? Colors.blue : Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          if (isFront)
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
        ],
      ),
      alignment: Alignment.center,
      child: (isFront)
          ? Text(
              text,
              style: TextStyle(
                fontSize: 48,
                color: isFront ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            )
          : const SizedBox(),
    );
  }
}
