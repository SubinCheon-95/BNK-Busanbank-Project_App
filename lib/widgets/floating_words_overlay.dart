import 'package:flutter/material.dart';
import 'dart:math';

/// 🔥 둥둥 떠다니는 단어 위젯 (수정!)
///
/// 수정 사항:
/// - 원래 SlideTransition 방식 유지
/// - 이동 범위 대폭 확대 (화면 전체)
/// - 9개 위치에 골고루 배치
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
      // ✅ 각 단어마다 다른 속도로 애니메이션
      final controller = AnimationController(
        duration: Duration(milliseconds: 4000 + _random.nextInt(3000)),  // 4~7초
        vsync: this,
      )..repeat(reverse: true);

      // ✅ 랜덤한 경로로 이동 (범위 확대!)
      final animation = Tween<Offset>(
        begin: Offset(
          _random.nextDouble() * 0.15 - 0.1,  // -1.0 ~ 1.0 (좌우 전체)
          _random.nextDouble() * 0.15 - 0.1, // -0.75 ~ 0.75 (상하 전체)
        ),
        end: Offset(
          _random.nextDouble() * 0.2 - 0.1,
          _random.nextDouble() * 0.2 - 0.1,
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

    return IgnorePointer(
      child: Stack(
        children: List.generate(displayWords.length, (index) {
          return SlideTransition(
            position: _animations[index],
            child: Align(
              alignment: _getAlignment(index),  // ✅ 9개 위치에 골고루 배치
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,  // ✅ 패딩 줄임
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
                    fontSize: 30,  // ✅ 글자 크기 줄임
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Alignment _getAlignment(int index) {
    // ✅ 9개 위치에 골고루 배치
    final positions = [
      Alignment(-0.7, -0.7),  // 0: 왼쪽 위
      Alignment(0.0, -0.7),   // 1: 중앙 위
      Alignment(0.7, -0.7),   // 2: 오른쪽 위
      Alignment(-0.7, 0.0),   // 3: 왼쪽 중간
      Alignment(0.0, 0.0),    // 4: 중앙
      Alignment(0.7, 0.0),    // 5: 오른쪽 중간
      Alignment(-0.7, 0.7),   // 6: 왼쪽 아래
      Alignment(0.0, 0.7),    // 7: 중앙 아래
      Alignment(0.7, 0.7),    // 8: 오른쪽 아래
    ];

    return positions[index % positions.length];
  }
}