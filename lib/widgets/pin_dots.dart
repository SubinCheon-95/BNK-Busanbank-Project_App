import 'package:flutter/material.dart';

const Color bnkPrimary = Color(0xFF6A1B9A);

class PinDots extends StatelessWidget {
  final int length;

  const PinDots({
    super.key,
    required this.length,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final filled = i < length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? bnkPrimary : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}
