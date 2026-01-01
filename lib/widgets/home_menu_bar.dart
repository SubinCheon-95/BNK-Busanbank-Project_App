import 'package:flutter/material.dart';
import 'package:tkbank/theme/app_colors.dart';
import '../core/menu/main_menu_config.dart';
import '../core/menu/main_menu_controller.dart';
import '../core/menu/main_menu_item.dart';
import 'package:tkbank/screens/product/product_main_screen.dart';
import 'package:tkbank/screens/product/interest_calculator_screen.dart';
import 'package:tkbank/screens/game/game_menu_screen.dart';
import 'package:tkbank/screens/cs/cs_support_screen.dart';


class HomeMenuBar extends StatefulWidget {
  final MainMenuType menuType;
  final String baseUrl;
  final VoidCallback onMorePressed;

  const HomeMenuBar({
    super.key,
    required this.menuType,
    required this.baseUrl,
    required this.onMorePressed,
  });

  @override
  State<HomeMenuBar> createState() => _HomeMenuBarState();
}

class _HomeMenuBarState extends State<HomeMenuBar> {
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductMainScreen(baseUrl: widget.baseUrl),
          ),
        );
        break;

      case MainMenuAction.calculator:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const InterestCalculatorScreen(),
          ),
        );
        break;

      case MainMenuAction.game:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameMenuScreen(baseUrl: widget.baseUrl),
          ),
        );
        break;

      case MainMenuAction.cs:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CustomerSupportScreen(),
          ),
        );
        break;

      case MainMenuAction.more:
        widget.onMorePressed();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildMenuList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) =>
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '추천 메뉴',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary
                  ),
                ),
                Text(
                  controller.progressText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray4
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildMenuList() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        controller: controller.scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        itemCount: menus.length,
        itemBuilder: (context, index) {
          final item = menus[index];
          final isActive = index == controller.activeIndex;
          return _menuItem(item, isActive);
        },
      ),
    );
  }

  Widget _menuItem(MainMenuItem item, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: InkWell(
        onTap: () => _handleMenuTap(item.action),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 30,
                color: isActive ? AppColors.white : AppColors.primary,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.white : AppColors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
