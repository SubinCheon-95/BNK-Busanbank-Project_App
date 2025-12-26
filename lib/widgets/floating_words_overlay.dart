import 'package:flutter/material.dart';
import 'dart:math';

/// 🔥 둥둥 떠다니는 단어 위젯 (에러 수정!)
///
/// - Positioned.fill()로 전체 영역 차지
/// - 9개 위치에 골고루 배치
/// - 각 위치에서 살짝만 떠다님
class FloatingWordsOverlay extends StatefulWidget {
  final List<String> words;
  final Color color;
  final int maxWords;

  const FloatingWordsOverlay({
    super.key,
    required this.words,
    required this.color,
    this.maxWords = 10,
  });

  @override
  State<FloatingWordsOverlay> createState() => _FloatingWordsOverlayState();
}

class _FloatingWordsOverlayState extends State<FloatingWordsOverlay>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<Offset>> _animations = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    final displayWords = widget.words.take(widget.maxWords).toList();

    for (int i = 0; i < displayWords.length; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 3000 + _random.nextInt(2000)),
        vsync: this,
      )..repeat(reverse: true);

      // ✅ 아주 작은 범위로만 떠다님
      final smallRange = 0.04;  // ±0.02

      final animation = Tween<Offset>(
        begin: Offset(
          (_random.nextDouble() - 0.5) * smallRange,
          (_random.nextDouble() - 0.5) * smallRange,
        ),
        end: Offset(
          (_random.nextDouble() - 0.5) * smallRange,
          (_random.nextDouble() - 0.5) * smallRange,
        ),
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));

      _controllers.add(controller);
      _animations.add(animation);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayWords = widget.words.take(widget.maxWords).toList();

    if (displayWords.isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ Positioned.fill()로 전체 영역 차지!
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: List.generate(displayWords.length, (index) {
            return SlideTransition(
              position: _animations[index],
              child: Align(
                alignment: _getAlignment(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.color.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    displayWords[index],
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Alignment _getAlignment(int index) {
    // ✅ 9개 위치 - 골고루!
    final positions = [
      Alignment(-1.2, -0.8),  // 왼쪽 위
      Alignment(0.0, -1.2),   // 중앙 위
      Alignment(1.1, -0.6),   // 오른쪽 위
      Alignment(-1.0, 0.2),   // 왼쪽 중간
      Alignment(-0.9, -0.3),    // 중앙 (감정 텍스트)
      Alignment(0.8, 0.0),    // 오른쪽 중간
      Alignment(-1.1, 0.7),   // 왼쪽 아래
      Alignment(0.0, 1.3),    // 중앙 아래
      Alignment(1.1, 0.8),    // 오른쪽 아래
    ];

    return positions[index % positions.length];
  }
}