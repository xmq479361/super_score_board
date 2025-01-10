
import 'package:flutter/material.dart';

import '../models/player.dart';
import 'color_pick_button.dart';

class PlayerEditDialog extends StatefulWidget {
  final Player player;
  final Function(Player) onSave;

  const PlayerEditDialog({super.key, required this.player, required this.onSave});

  @override
  State<PlayerEditDialog> createState() => _PlayerEditDialogState();
}

class _PlayerEditDialogState extends State<PlayerEditDialog> {
  late TextEditingController _nameController;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.player.name);
    _selectedColor = widget.player.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑选手信息'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: '选手名称'),
          ),
          const SizedBox(height: 16),
          const Text('选择颜色'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Colors.blue,
              Colors.red,
              Colors.green,
              Colors.orange,
              Colors.pinkAccent.shade100,
              Colors.purple,
              Colors.teal,
            ].map((color) => GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  border: color == _selectedColor
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            widget.onSave(Player(
              id: widget.player.id,
              name: _nameController.text,
              color: _selectedColor,
              highestScore: widget.player.highestScore,
              totalGames: widget.player.totalGames,
              wonGames: widget.player.wonGames,
            ));
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
