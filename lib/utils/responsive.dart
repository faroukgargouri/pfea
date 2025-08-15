import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

extension ContextSize on BuildContext {
  double get w => MediaQuery.of(this).size.width;
  double get h => MediaQuery.of(this).size.height;

  bool get isMobile => ResponsiveBreakpoints.of(this).smallerThan(TABLET);
  bool get isTablet => ResponsiveBreakpoints.of(this).between(TABLET, DESKTOP);
  bool get isDesktop => ResponsiveBreakpoints.of(this).largerThan(DESKTOP);

  double get gutter => isMobile ? 12 : isTablet ? 16 : 24;
  double get maxContentWidth => isDesktop ? 1100 : isTablet ? 760 : double.infinity;
}

class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget child;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.child,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.maxContentWidth),
            child: Padding(
              padding: EdgeInsets.all(context.gutter),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  final int? mobile;
  final int? tablet;
  final int? desktop;
  final double aspectRatio;
  final List<Widget> children;
  final ScrollController? controller;

  const ResponsiveGrid({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.aspectRatio = 0.72,
    required this.children,
    this.controller,
  });

  int _columns(BuildContext c) {
    if (c.isDesktop) return desktop ?? 5;
    if (c.isTablet)  return tablet  ?? 3;
    return mobile ?? 2;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: EdgeInsets.all(context.gutter),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns(context),
        mainAxisSpacing: context.gutter,
        crossAxisSpacing: context.gutter,
        childAspectRatio: aspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (_, i) => children[i],
    );
  }
}
