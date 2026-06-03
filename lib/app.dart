import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/widgets/glass_widgets.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class SpiceDeskApp extends ConsumerWidget {
  const SpiceDeskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      theme: appTheme,
      darkTheme: appTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      title: 'SpiceDesk',
      builder: (context, child) {
        return Glass(
          enabled: true,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
