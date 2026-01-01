import 'package:flutter/material.dart';
import 'main_menu_item.dart';

enum MainMenuType {
  normal,
  easy,
}

class MainMenuConfig {
  static List<MainMenuItem> getMenus({
    required MainMenuType type,
  }) {
    final commonMenus = [
      const MainMenuItem(
        label: '상품 보기',
        icon: Icons.shopping_bag,
        action: MainMenuAction.product,
      ),
      const MainMenuItem(
        label: '금리계산기',
        icon: Icons.calculate,
        action: MainMenuAction.calculator,
      ),
      const MainMenuItem(
        label: '금융 게임',
        icon: Icons.games,
        action: MainMenuAction.game,
      ),
      const MainMenuItem(
        label: '고객센터',
        icon: Icons.support_agent,
        action: MainMenuAction.cs,
      ),
    ];

    if (type == MainMenuType.normal) {
      return [
        ...commonMenus,
        const MainMenuItem(
          label: '더보기',
          icon: Icons.more_horiz,
          action: MainMenuAction.more,
        ),
      ];
    }

    // easy 메인 (4개, 더보기 없음)
    return commonMenus;
  }
}
