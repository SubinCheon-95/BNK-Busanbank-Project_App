import 'package:flutter/material.dart';
import '../../widgets/easy_menu_bar.dart';
import '../../core/menu/main_menu_config.dart';

class EasyHomeScreen extends StatelessWidget {
  const EasyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: EasyMenuBar(
          menuType: MainMenuType.easy,
        ),
      ),
    );
  }
}
