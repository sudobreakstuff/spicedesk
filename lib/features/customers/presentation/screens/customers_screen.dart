import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customers', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('Manage your customer database', style: TextStyle(fontSize: 14, color: SpiceColors.textSecondary)),
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
                      Icon(Icons.people_outline, size: 48, color: SpiceColors.textSecondary),
                      SizedBox(height: 12),
                      Text('No customers yet', style: TextStyle(color: SpiceColors.textSecondary, fontSize: 15)),
                      SizedBox(height: 4),
                      Text('Customers will appear here after sales', style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
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
