import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/glass_widgets.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../workspace/domain/workspace_state.dart';
import '../../../auth/domain/auth_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(workspaceStateProvider);

    if (workspace.selectedId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.business_outlined,
                size: 64, color: SpiceColors.textSecondary),
            const SizedBox(height: 16),
            Text('No workspace selected',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Create or join a workspace to get started',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/workspace'),
              child: const Text('Set Up Workspace'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Welcome
        Text(
          'Welcome back,',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          ref.watch(authStateProvider).user?.userMetadata?['name'] ?? 'User',
          style: Theme.of(context).textTheme.headlineMedium,
        ),

        const SizedBox(height: 24),

        // Quick stats
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _StatCard(
              icon: Icons.point_of_sale_rounded,
              label: 'Today\'s Sales',
              value: 'R 0.00',
              color: SpiceColors.accent,
            ),
            _StatCard(
              icon: Icons.inventory_2_rounded,
              label: 'Products',
              value: '0',
              color: SpiceColors.primary,
            ),
            _StatCard(
              icon: Icons.people_rounded,
              label: 'Customers',
              value: '0',
              color: const Color(0xFF8B5CF6),
            ),
            _StatCard(
              icon: Icons.receipt_long_rounded,
              label: 'Transactions',
              value: '0',
              color: SpiceColors.warning,
            ),
          ].animate(interval: 100.ms).fadeIn().slideY(begin: 0.1),
        ),

        const SizedBox(height: 28),

        // Quick actions
        Text('Quick Actions',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.point_of_sale_rounded,
                label: 'New Sale',
                onTap: () => context.go('/pos'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.add_box_rounded,
                label: 'Add Product',
                onTap: () => context.go('/inventory'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.analytics_rounded,
                label: 'Reports',
                onTap: () => context.go('/reports'),
              ),
            ),
          ].animate(interval: 100.ms, delay: 300.ms).fadeIn().slideY(
              begin: 0.1),
        ),

        const SizedBox(height: 28),

        Text('Recent Activity',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        GlassCard(
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.hourglass_empty_rounded,
                  size: 40, color: SpiceColors.textSecondary),
              const SizedBox(height: 8),
              Text('No recent activity',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text('Sales and inventory actions will appear here',
                  style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ).animate(delay: 500.ms).fadeIn(),

        const SizedBox(height: 16),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Made by Shahid Singh',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(icon, color: SpiceColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: Theme.of(context).textTheme.labelLarge,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
