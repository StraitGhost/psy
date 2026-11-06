import 'package:flutter/material.dart';

class MiniStat extends StatelessWidget {
  final String value;
  final String label;

  const MiniStat({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}