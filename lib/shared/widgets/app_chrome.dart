import 'package:flutter/material.dart';

class MediverseAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MediverseAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title), actions: actions);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ScreenPadding extends StatelessWidget {
  const ScreenPadding({super.key, required this.child, this.bottom = 24});

  final Widget child;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(18, 18, 18, bottom),
        child: child,
      ),
    );
  }
}
