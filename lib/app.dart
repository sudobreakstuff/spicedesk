import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';

class SpiceDeskApp extends ConsumerWidget {
  const SpiceDeskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(appThemeProvider);

    return MaterialApp.router(
      theme: appTheme,
      darkTheme: appTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      title: 'SpiceDesk',
      builder: (context, child) {
        return ColoredBox(
          color: SpiceColors.surface,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
