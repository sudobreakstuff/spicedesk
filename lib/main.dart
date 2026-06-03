// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:spicedesk/app.dart';
import 'package:spicedesk/bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GoogleFonts.pendingFonts([
    GoogleFonts.inter(),
    GoogleFonts.jetBrainsMono(),
  ]);

  await bootstrap();

  runApp(
    const ProviderScope(
      child: SpiceDeskApp(),
    ),
  );
}
