import 'package:flutter/material.dart';

class ColorPickerButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const ColorPickerButton(
      {super.key, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
