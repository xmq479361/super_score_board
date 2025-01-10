import 'package:flutter/material.dart';
import 'package:super_score_board/models/player.dart';

class AddPlayerDialog extends StatefulWidget {
  const AddPlayerDialog({super.key});

  @override
  State<AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<AddPlayerDialog> {
  final _nameController = TextEditingController();
  Color selectedColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加新选手'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '选手名称',
            ),
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
              onTap: () => setState(() => selectedColor = color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  border: color == selectedColor
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              Navigator.of(context).pop(Player(
                id: DateTime.now().toString(),
                name: _nameController.text,
                color: selectedColor,
              ));
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}