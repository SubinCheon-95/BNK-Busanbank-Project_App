import 'package:flutter/material.dart';
import '../core/menu/main_menu_config.dart';
import '../core/menu/main_menu_controller.dart';
import '../core/menu/main_menu_item.dart';

class EasyMenuBar extends StatefulWidget {
  final MainMenuType menuType;

  const EasyMenuBar({
    super.key,
    required this.menuType,
  });

  @override
  State<EasyMenuBar> createState() => _EasyMenuBarState();
}

class _EasyMenuBarState extends State<EasyMenuBar> {
  late MainMenuController controller;
  late List<MainMenuItem> menus;

  @override
  void initState() {
    super.initState();
    menus = MainMenuConfig.getMenus(
      type: widget.menuType,
    );
    controller = MainMenuController(totalCount: menus.length);
  }

  @override
  void dispose() {
    controller.disposeController();
    super.dispose();
  }

  void _handleMenuTap(MainMenuAction action) {
    switch (action) {
      case MainMenuAction.product:
      // TODO: ProductMainScreen 이동
        break;

      case MainMenuAction.calculator:
      // TODO: InterestCalculatorScreen 이동
        break;

      case MainMenuAction.game:
      // TODO: GameMenuScreen 이동
        break;

      case MainMenuAction.cs:
      // TODO: CustomerSupportScreen 이동
        break;

      case MainMenuAction.more:
      // ❌ easy 메뉴에는 더보기 없음 (아무것도 안 하거나 return)
        return;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 상단: 추천 메뉴 + 1/5
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '추천 메뉴',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              AnimatedBuilder(
                animation: controller,
                builder: (_, __) => Text(
                  controller.progressText,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ],
          ),
        ),

        // 가로 스크롤 메뉴
        SizedBox(
          height: 110,
          child: ListView.builder(
            controller: controller.scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: menus.length,
            itemBuilder: (context, index) {
              final isActive = index == controller.activeIndex;
              final item = menus[index];

              return _menuItem(item, isActive);
            },
          ),
        ),
      ],
    );
  }

  Widget _menuItem(MainMenuItem item, bool isActive) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isActive ? Colors.purple : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _handleMenuTap(item.action),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: isActive ? Colors.white : Colors.black,
            ),
            const SizedBox(width: 12),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 26,
                color: isActive ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
