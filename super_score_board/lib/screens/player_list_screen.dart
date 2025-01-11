import 'package:flutter/material.dart';

import '../models/player.dart';
import '../services/storage_service.dart';
import '../widgets/add_player_dialog.dart';
import '../widgets/player_edit_dialog.dart';

class PlayerListScreen extends StatefulWidget {
  final StorageService storageService;

  const PlayerListScreen({super.key, required this.storageService});

  @override
  _PlayerListScreenState createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  List<Player> players = [];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final loadedPlayers = await widget.storageService.loadPlayers();
    setState(() {
      players = loadedPlayers;
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

  Future<void> _editPlayer(Player player) async {
    final updatedPlayer = await showDialog<Player>(
      context: context,
      builder: (context) => PlayerEditDialog(player: player, onSave: (p) {}),
    );
    print("updatedPlayer: ${updatedPlayer?.toJson()}");
    if (updatedPlayer != null) {
      setState(() {
        final index = players.indexWhere((p) => p.id == player.id);
        if (index != -1) {
          players[index] = updatedPlayer;
        }
      });
      await widget.storageService.savePlayers(players);
    }
  }

  Future<void> _deletePlayer(Player player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除选手'),
        content: Text('确定要删除选手 ${player.name} 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        players.removeWhere((p) => p.id == player.id);
      });
      await widget.storageService.savePlayers(players);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选手列表')),
      backgroundColor: Colors.blue.shade900,
      body: SafeArea(
          child: ListView.builder(
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: player.color,
              child: Text(
                player.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(player.name),
            subtitle:
                Text('最高分: ${player.highestScore}, 胜场: ${player.wonGames}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editPlayer(player),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deletePlayer(player),
                ),
              ],
            ),
          );
        },
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPlayer,
        child: const Icon(Icons.add),
      ),
    );
  }
}
