import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class BlockTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const BlockTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}