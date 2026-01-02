
import 'package:flutter/material.dart';
import '../screens/member/pin/pin_register_screen.dart'; // 색상 상수 쓰면

class PinKeypadPanel extends StatelessWidget {
  final Function(String) onNumber;
  final VoidCallback onDelete;

  const PinKeypadPanel({
    super.key,
    required this.onNumber,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1','2','3'],
      ['4','5','6'],
      ['7','8','9'],
      ['','0','del'],
    ];


    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 32),
        decoration: const BoxDecoration(
          color: bnkPrimary,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: keys.map((row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row.map((key) {
                  if (key == '') {
                    return const SizedBox(width: 80);
                  }

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (key == 'del') {
                        onDelete();
                      } else {
                        onNumber(key);
                      }
                    },
                    child: SizedBox(
                      width: 80,
                      height: 56,
                      child: Center(
                        child: key == 'del'
                            ? const Icon(
                          Icons.backspace_outlined,
                          color: Colors.white,
                          size: 26,
                        )
                            : Text(
                          key,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
