import 'package:flutter/material.dart';

enum MainMenuAction {
  product,
  calculator,
  game,
  cs,
  more,
}

class MainMenuItem {
  final String label;
  final IconData icon;
  final MainMenuAction action;

  const MainMenuItem({
    required this.label,
    required this.icon,
    required this.action,
  });
}
