import 'package:flutter/material.dart';

import '../models/game_settings.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loadedPlayers = await widget.storageService.loadPlayers();
    final lastGame = await widget.storageService.loadLastGame();
    setState(() {
      players = loadedPlayers;
      if (lastGame != null) {
        leftPlayer = players.firstWhere((p) => p.id == lastGame.leftPlayerId);
        rightPlayer = players.firstWhere((p) => p.id == lastGame.rightPlayerId);
        defaultDuration = lastGame.duration;
        isCountdownEnabled = lastGame.isCountdownEnabled;
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: 16),
                _buildCountdownToggle(),
                const Spacer(),
                ElevatedButton(
                  onPressed: (leftPlayer != null && rightPlayer != null)
                      ? () => _startGame()
                      : null,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue.shade900,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('开始比赛'),
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

  void _startGame() {
    widget.storageService.saveLastGame(GameSettings(
      leftPlayerId: leftPlayer!.id,
      rightPlayerId: rightPlayer!.id,
      duration: defaultDuration,
      isCountdownEnabled: isCountdownEnabled,
    ));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ScoreBoard(
          storageService: widget.storageService,
          leftPlayer: leftPlayer!,
          rightPlayer: rightPlayer!,
          defaultDuration: defaultDuration,
          isCountdownEnabled: isCountdownEnabled,
        ),
      ),
    );
  }
}
