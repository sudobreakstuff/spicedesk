import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spicedesk/app.dart';
import 'package:spicedesk/bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Don't block on font download — use cached fonts or fall back to system
  try {
    await bootstrap();
  } catch (e) {
    debugPrint('Bootstrap error: $e');
    // Continue anyway — auth screens work without Supabase
  }

  runApp(
    const ProviderScope(
      child: SpiceDeskApp(),
    ),
  );
}
