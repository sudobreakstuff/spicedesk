import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A frosted glass container with backdrop blur — the core glassmorphism widget.
class GlassCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final double blur;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;

  const GlassCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.blur = 10,
    this.onTap,
    this.width,
    this.height,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          constraints: constraints,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor ?? SpiceColors.glassSurface,
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: border ??
                Border.all(color: SpiceColors.glassBorder, width: 0.5),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

/// A glass-styled bottom navigation bar.
class GlassBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassBottomBarItem> items;

  const GlassBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: SpiceColors.glassSurface,
            border: Border(
              top: BorderSide(color: SpiceColors.glassBorder, width: 0.5),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final selected = i == currentIndex;
                  return Expanded(
                    child: InkWell(
                      onTap: () => onTap(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              selected ? item.activeIcon : item.icon,
                              size: 22,
                              color: selected
                                  ? SpiceColors.primary
                                  : SpiceColors.textSecondary,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    selected ? FontWeight.w600 : FontWeight.w400,
                                color: selected
                                    ? SpiceColors.primary
                                    : SpiceColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassBottomBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const GlassBottomBarItem({
    required this.icon,
    IconData? activeIcon,
    required this.label,
  }) : activeIcon = activeIcon ?? icon;
}

/// A glass-styled app bar.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;

  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: AppBar(
          title: title,
          actions: actions,
          leading: leading,
          centerTitle: false,
          elevation: 0,
          backgroundColor: SpiceColors.surface.withAlpha(180),
          foregroundColor: SpiceColors.textPrimary,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: SpiceColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// A glass-styled scaffold that applies backdrop blur to the app bar area.
class GlassScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const GlassScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? SpiceColors.surface,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// A glass-styled dialog.
class GlassDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;

  const GlassDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AlertDialog(
          backgroundColor: SpiceColors.surfaceAlt.withAlpha(220),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: SpiceColors.glassBorder, width: 0.5),
          ),
          title: title,
          content: content,
          actions: actions,
        ),
      ),
    );
  }
}

/// A simple glass container that wraps children with backdrop blur.
class Glass extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const Glass({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: child,
      ),
    );
  }
}
