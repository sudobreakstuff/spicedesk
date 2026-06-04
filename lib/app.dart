import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/widgets/app_sidebar.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

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
        String location;
        try {
          location = GoRouter.of(context).state.matchedLocation;
        } catch (_) {
          return child ?? const SizedBox.shrink();
        }
        final isAuthRoute = location == '/login' || location == '/register';

        if (isAuthRoute) {
          return child ?? const SizedBox.shrink();
        }

        return Row(
          children: [
            const AppSidebar(),
            Expanded(
              child: ClipRect(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}
