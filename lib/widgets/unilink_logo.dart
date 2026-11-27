import 'package:flutter/material.dart';

class UnilinkLogo extends StatelessWidget {
  final double height;
  final double fontSize;

  const UnilinkLogo({super.key, this.height = 36, this.fontSize = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'unilink',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
