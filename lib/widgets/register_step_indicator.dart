import 'package:flutter/material.dart';

class RegisterStepIndicator extends StatelessWidget {
  final int step;
  final int total;

  const RegisterStepIndicator({
    super.key,
    required this.step,
    this.total = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP $step / $total',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: step / total,
          backgroundColor: Colors.grey.shade200,
          color: Colors.black,
          minHeight: 4,
        ),
      ],
    );
  }
}
