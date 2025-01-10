import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../services/storage_service.dart';
import '../widgets/add_player_dialog.dart';
import 'score_board.dart';

class StartScreen extends StatefulWidget {
  final StorageService storageService;

  const StartScreen({Key? key, required this.storageService}) : super(key: key);

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  List<Player> players = [];
  Player? leftPlayer;
  Player? rightPlayer;
  int defaultDuration = 900; // 15 minutes
  bool isCountdownEnabled = true;
  bool isRoundTimer = false;
  int roundDuration = 30;
  late AppSettings appSettings;
  GameState? savedGameState;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _loadData();
  }

  Future<void> _loadData() async {
    final loadedPlayers = await widget.storageService.loadPlayers();
    final lastGame = await widget.storageService.loadLastGame();
    appSettings = await widget.storageService.loadAppSettings();
    savedGameState = await widget.storageService.loadGameState();
    setState(() {
      players = loadedPlayers;
      if (lastGame != null) {
        print("_loadData lastGame: ${lastGame.toJson()}");
        leftPlayer = players.firstWhere((p) => p.id == lastGame.leftPlayerId);
        rightPlayer = players.firstWhere((p) => p.id == lastGame.rightPlayerId);
        defaultDuration = lastGame.duration;
        isCountdownEnabled = lastGame.isCountdownEnabled;
        isRoundTimer = lastGame.isRoundTimer;
        roundDuration = lastGame.roundDuration;
      }
    });
  }

  Future<Player?> _addNewPlayer() async {
    final newPlayer = await showDialog<Player>(
      context: context,
      builder: (context) => const AddPlayerDialog(),
    );
    if (newPlayer != null) {
      setState(() {
        players.add(newPlayer);
      });
      await widget.storageService.savePlayers(players);
    }
    return newPlayer;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.blue.shade500],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                        // crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '计分板',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          _buildPlayerSelector('左方选手', leftPlayer,
                              (Player? p) => setState(() => leftPlayer = p)),
                          const SizedBox(height: 16),
                          _buildPlayerSelector('右方选手', rightPlayer,
                              (Player? p) => setState(() => rightPlayer = p)),
                          const SizedBox(height: 32),
                          _buildDurationSelector(),
                          _buildCountdownToggle(),
                          _buildRoundTimerToggle(),
                          if (isRoundTimer) ...[
                            const SizedBox(height: 16),
                            _buildRoundDurationSelector(),
                          ],
                        ]),
                  ),
                ),
                if (savedGameState != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _resumeGame(),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.green,
                        backgroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('恢复上次游戏'),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (leftPlayer != null && rightPlayer != null)
                        ? () => _startNewGame()
                        : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue.shade900,
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text('开始新游戏'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSelector(
      String label, Player? selectedPlayer, void Function(Player?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Player>(
              value: selectedPlayer,
              isExpanded: true,
              dropdownColor: Colors.blue.shade800,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: [
                ...players.map((p) => DropdownMenuItem(
                    value: p,
                    child: Container(
                        color: p.color,
                        child: Text(
                          p.name,
                          // style: TextStyle(color: p.color),
                        )))),
                const DropdownMenuItem(value: null, child: Text('新增选手')),
              ],
              onChanged: (value) async {
                if (value == null) {
                  final newPlayer = await _addNewPlayer();
                  if (newPlayer != null) onChanged(newPlayer);
                } else {
                  onChanged(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '比赛时长',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: defaultDuration,
              isExpanded: true,
              dropdownColor: Colors.blue.shade800,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: [300, 600, 900, 1200, 1500, 1800].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('${value ~/ 60} 分钟'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => defaultDuration = value!);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownToggle() {
    return SwitchListTile(
      title: const Text(
        '启用倒计时',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      value: isCountdownEnabled,
      onChanged: (value) {
        setState(() => isCountdownEnabled = value);
      },
      activeColor: Colors.white,
      activeTrackColor: Colors.blue.shade300,
      inactiveThumbColor: Colors.grey.shade400,
      inactiveTrackColor: Colors.grey.shade700,
    );
  }

  Widget _buildRoundTimerToggle() {
    return SwitchListTile(
      title: const Text(
        '启用单轮计时',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      value: isRoundTimer,
      onChanged: (value) {
        setState(() => isRoundTimer = value);
      },
      activeColor: Colors.white,
      activeTrackColor: Colors.blue.shade300,
      inactiveThumbColor: Colors.grey.shade400,
      inactiveTrackColor: Colors.grey.shade700,
    );
  }

  Widget _buildRoundDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '单轮时长',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: roundDuration,
              isExpanded: true,
              dropdownColor: Colors.blue.shade800,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: [15, 30, 45, 60].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text('$value 秒'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => roundDuration = value!);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _startNewGame() {
    widget.storageService.saveLastGame(GameSettings(
      leftPlayerId: leftPlayer!.id,
      rightPlayerId: rightPlayer!.id,
      duration: defaultDuration,
      isCountdownEnabled: isCountdownEnabled,
      isRoundTimer: isRoundTimer,
      roundDuration: roundDuration,
    ));
    widget.storageService.clearGameState();
    _navigateToScoreBoard(isRestoredGame: false);
  }

  void _resumeGame() {
    if (savedGameState != null) {
      leftPlayer =
          players.firstWhere((p) => p.id == savedGameState!.leftPlayerId);
      rightPlayer =
          players.firstWhere((p) => p.id == savedGameState!.rightPlayerId);
      _navigateToScoreBoard(isRestoredGame: true);
    }
  }

  void _navigateToScoreBoard({required bool isRestoredGame}) {
    widget.storageService.saveLastGame(GameSettings(
      leftPlayerId: leftPlayer!.id,
      rightPlayerId: rightPlayer!.id,
      duration: defaultDuration,
      isCountdownEnabled: isCountdownEnabled,
      isRoundTimer: isRoundTimer,
      roundDuration: roundDuration,
    ));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScoreBoard(
          storageService: widget.storageService,
          leftPlayer: leftPlayer!,
          rightPlayer: rightPlayer!,
          defaultDuration: defaultDuration,
          isCountdownEnabled: isCountdownEnabled,
          isRoundTimer: isRoundTimer,
          roundDuration: roundDuration,
          isRestoredGame: isRestoredGame,
        ),
      ),
    );
  }
}
