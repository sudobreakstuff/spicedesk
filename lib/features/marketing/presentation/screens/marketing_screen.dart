import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class MarketingScreen extends StatelessWidget {
  const MarketingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Marketing', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('Create and manage your adverts', style: TextStyle(fontSize: 14, color: SpiceColors.textSecondary)),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: SpiceColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SpiceColors.border),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.campaign_outlined, size: 48, color: SpiceColors.textSecondary),
                      SizedBox(height: 12),
                      Text('Coming soon', style: TextStyle(color: SpiceColors.textSecondary, fontSize: 15)),
                      SizedBox(height: 4),
                      Text('Marketing tools will be available in a future update', style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
