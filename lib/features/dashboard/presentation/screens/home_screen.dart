import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';

    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          // Header
          Text(
            '$greeting,',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: SpiceColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Here\'s what\'s happening with your business today.',
            style: TextStyle(fontSize: 14, color: SpiceColors.textSecondary),
          ),

          const SizedBox(height: 32),

          // Stats grid
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.6,
            children: [
              _StatCard(
                icon: Icons.trending_up,
                label: 'Today\'s Sales',
                value: 'R 0.00',
                accent: SpiceColors.accent,
                onTap: () => context.go('/reports'),
              ),
              _StatCard(
                icon: Icons.shopping_bag,
                label: 'Products',
                value: '0',
                accent: SpiceColors.primary,
                onTap: () => context.go('/inventory'),
              ),
              _StatCard(
                icon: Icons.people,
                label: 'Customers',
                value: '0',
                accent: const Color(0xFF8B5CF6),
                onTap: () => context.go('/customers'),
              ),
              _StatCard(
                icon: Icons.receipt_long,
                label: 'Transactions',
                value: '0',
                accent: SpiceColors.warning,
                onTap: () => context.go('/reports'),
              ),
            ].animate(interval: 80.ms).fadeIn().slideY(begin: 12),
          ),

          const SizedBox(height: 36),

          const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.point_of_sale_rounded,
                  label: 'New Sale',
                  subtitle: 'Start a transaction',
                  onTap: () => context.go('/pos'),
                  color: SpiceColors.accent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionCard(
                  icon: Icons.add_box_rounded,
                  label: 'Add Product',
                  subtitle: 'Add to inventory',
                  onTap: () => context.go('/inventory'),
                  color: SpiceColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionCard(
                  icon: Icons.analytics_rounded,
                  label: 'View Reports',
                  subtitle: 'See your analytics',
                  onTap: () => context.go('/reports'),
                  color: SpiceColors.warning,
                ),
              ),
            ].animate(interval: 100.ms, delay: 200.ms).fadeIn().slideY(begin: 12),
          ),

          const SizedBox(height: 36),

          const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: SpiceColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SpiceColors.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.hourglass_empty, size: 32, color: SpiceColors.textSecondary),
                SizedBox(height: 12),
                Text('No recent activity', style: TextStyle(color: SpiceColors.textSecondary)),
                SizedBox(height: 4),
                Text('Sales and inventory actions will appear here',
                    style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn(),

          const SizedBox(height: 48),
          const Center(
            child: Text('Made by Shahid Singh',
                style: TextStyle(fontSize: 11, color: SpiceColors.textSecondary)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback? onTap;

  const _StatCard({required this.icon, required this.label, required this.value, required this.accent, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SpiceColors.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SpiceColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: accent.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accent, size: 18),
                  ),
                  const Spacer(),
                  Icon(Icons.trending_up, size: 14, color: SpiceColors.accent.withAlpha(100)),
                ],
              ),
              const SizedBox(height: 16),
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _ActionCard({required this.icon, required this.label, required this.subtitle, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SpiceColors.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: SpiceColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: SpiceColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, size: 16, color: SpiceColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
