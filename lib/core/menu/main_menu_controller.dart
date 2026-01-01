import 'package:flutter/material.dart';

class MainMenuController extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();
  final int totalCount;

  int activeIndex = 0;

  MainMenuController({required this.totalCount}) {
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final index = (scrollController.offset / 200).round();

    if (index != activeIndex && index >= 0 && index < totalCount) {
      activeIndex = index;
      notifyListeners();
    }
  }

  String get progressText => '${activeIndex + 1}/$totalCount';

  void disposeController() {
    scrollController.dispose();
  }
}
