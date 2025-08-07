import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showLogout;
  final VoidCallback? onLogout;

  const CustomNavBar({
    super.key,
    required this.title,
    this.showLogout = false,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: showLogout
          ? [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: onLogout,
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
