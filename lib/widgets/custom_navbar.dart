import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ===================== TRIKI APP BAR =====================
class TrikiAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? fullName;
  final String? codeSage;

  /// If provided, this is used for logout. If null, a default implementation
  /// clears SharedPreferences (userId/fullName/codeSage/token) and routes to /login.
  final Future<void> Function(BuildContext context)? onLogout;

  /// Optional custom leading (e.g., a custom menu/back button).
  /// If not null, it overrides [showMenu].
  final Widget? leading;

  /// Extra actions to add before the logout button.
  final List<Widget>? actionsBeforeLogout;

  /// Optional center widget (e.g., a page title). By default, only the logo shows at left.
  final Widget? center;

  /// Height of the AppBar (default 56).
  final double height;

  /// If true and [leading] is null, show a hamburger that opens the Scaffold drawer.
  final bool showMenu;

  /// Optional colors (keep defaults matching your current design).
  final Color backgroundColor;
  final Color logoTint; // used only for menu icon color to match dark logo on white bg

  /// OPTIONAL: Blue navbar content (shown under the app bar if provided)
  final List<BlueNavItem>? blueNavItems;
  final BlueNavbarVariant blueNavVariant;
  final double blueNavHeight;

  const TrikiAppBar({
    super.key,
    this.fullName,
    this.codeSage,
    this.onLogout,
    this.leading,
    this.actionsBeforeLogout,
    this.center,
    this.height = kToolbarHeight,
    this.showMenu = false,
    this.backgroundColor = Colors.white,
    this.logoTint = Colors.black87,
    this.blueNavItems,
    this.blueNavVariant = BlueNavbarVariant.tabs,
    this.blueNavHeight = 42,
  });

  Future<void> _defaultLogout(BuildContext context) async {
    final p = await SharedPreferences.getInstance();
    await p.remove('userId');
    await p.remove('fullName');
    await p.remove('codeSage');
    await p.remove('token');
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<void> _confirmAndLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Déconnecter')),
        ],
      ),
    );
    if (ok == true) {
      if (onLogout != null) {
        await onLogout!(context);
      } else {
        await _defaultLogout(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return AppBar(
      elevation: 0,
      backgroundColor: backgroundColor,
      titleSpacing: 0,

      // If a custom leading is provided, use it. Otherwise, show menu if requested.
      leading: leading ??
          (showMenu
              ? Builder(
                  builder: (ctx) => IconButton(
                    icon: Icon(Icons.menu, color: logoTint),
                    tooltip: 'Menu',
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                )
              : null),

      title: Row(
        children: [
          const SizedBox(width: 12),

          // Left logo
          Image.asset('assets/logo.png', height: 34),
          const SizedBox(width: 12),

          // Optional center content
          if (center != null) Expanded(child: center!) else const Spacer(),

          // User info (wide screens only)
          if (!isMobile && (fullName?.isNotEmpty == true || codeSage?.isNotEmpty == true)) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (fullName?.isNotEmpty == true)
                  Text(
                    fullName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                if (codeSage?.isNotEmpty == true) const SizedBox(height: 2),
                if (codeSage?.isNotEmpty == true)
                  Text(
                    'CODE: ${codeSage!}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),

      actions: [
        if (actionsBeforeLogout != null) ...actionsBeforeLogout!,
        // Logout: icon on mobile; labeled button on wide screens
        if (isMobile)
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () => _confirmAndLogout(context),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: OutlinedButton.icon(
              onPressed: () => _confirmAndLogout(context),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Déconnexion'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Colors.black26),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
      ],

      // 🔵 Blue navbar (if provided)
      bottom: (blueNavItems != null && blueNavItems!.isNotEmpty)
          ? BlueNavbar(items: blueNavItems!, variant: blueNavVariant, height: blueNavHeight)
          : null,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(height + ((blueNavItems?.isNotEmpty ?? false) ? blueNavHeight : 0));
}

/// ===================== BLUE NAVBAR (reusable) =====================
const trikiBlue = Color(0xFF0D47A1);

class BlueNavItem {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap; // null => current page
  final bool selected;

  const BlueNavItem({
    required this.label,
    this.icon,
    this.onTap,
    this.selected = false,
  });
}

enum BlueNavbarVariant { tabs, textOnly }

class BlueNavbar extends StatelessWidget implements PreferredSizeWidget {
  final List<BlueNavItem> items;
  final BlueNavbarVariant variant;
  final double height;

  const BlueNavbar({
    super.key,
    required this.items,
    this.variant = BlueNavbarVariant.tabs,
    this.height = 42,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    if (variant == BlueNavbarVariant.textOnly) {
      // Simple white text on blue, separated by bullets
      return Container(
        color: trikiBlue,
        height: height,
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                Text(
                  items[i].label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: .2,
                  ),
                ),
                if (i != items.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('•', style: TextStyle(color: Colors.white54)),
                  ),
              ],
            ],
          ),
        ),
      );
    }

    // Tabs (pill) variant
    return Container(
      color: trikiBlue,
      height: height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: items.map((it) {
            final sel = it.selected;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: InkWell(
                onTap: it.onTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? Colors.white : Colors.white24),
                  ),
                  child: Row(
                    children: [
                      if (it.icon != null) ...[
                        Icon(it.icon, size: 16, color: sel ? trikiBlue : Colors.white),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        it.label,
                        style: TextStyle(
                          color: sel ? trikiBlue : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
