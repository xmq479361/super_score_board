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
  int defaultDuration = 300; // 5 minutes
  bool isRoundTimer = false;
  int roundDuration = 30;

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
        isRoundTimer = lastGame.isRoundTimer;
        roundDuration = lastGame.roundDuration;
      }
    });
  }

  Future<void> _addNewPlayer() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('计分板设置')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPlayerDropdown('左方选手', leftPlayer, (Player? p) => setState(() => leftPlayer = p)),
            const SizedBox(height: 16),
            _buildPlayerDropdown('右方选手', rightPlayer, (Player? p) => setState(() => rightPlayer = p)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('默认时长'),
              trailing: DropdownButton<int>(
                value: defaultDuration,
                items: [300, 600, 900].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('${value ~/ 60} 分钟'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => defaultDuration = value!),
              ),
            ),
            SwitchListTile(
              title: const Text('轮次计时游戏'),
              value: isRoundTimer,
              onChanged: (value) => setState(() => isRoundTimer = value),
            ),
            if (isRoundTimer)
              ListTile(
                title: const Text('单轮计时时间'),
                trailing: DropdownButton<int>(
                  value: roundDuration,
                  items: [15, 30, 45, 60].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value 秒'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => roundDuration = value!),
                ),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: (leftPlayer != null && rightPlayer != null)
                  ? () => _startGame()
                  : null,
              child: const Text('开始比赛'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerDropdown(String label, Player? selectedPlayer, void Function(Player?) onChanged) {
    return DropdownButtonFormField<Player>(
      decoration: InputDecoration(labelText: label),
      value: selectedPlayer,
      items: [
        ...players.map((p) => DropdownMenuItem(value: p, child: Text(p.name))),
        const DropdownMenuItem(value: null, child: Text('新增选手')),
      ],
      onChanged: (value) {
        if (value == null) {
          _addNewPlayer();
        } else {
          onChanged(value);
        }
      },
    );
  }

  void _startGame() {
    widget.storageService.saveLastGame(GameSettings(
      leftPlayerId: leftPlayer!.id,
      rightPlayerId: rightPlayer!.id,
      duration: defaultDuration,
      isRoundTimer: isRoundTimer,
      roundDuration: roundDuration,
    ));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ScoreBoard(
          storageService: widget.storageService,
          leftPlayer: leftPlayer!,
          rightPlayer: rightPlayer!,
          defaultDuration: defaultDuration,
          isRoundTimer: isRoundTimer,
          roundDuration: roundDuration,
        ),
      ),
    );
  }
}
