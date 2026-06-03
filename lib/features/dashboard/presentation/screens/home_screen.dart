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
        child: GlassCard(
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [SpiceColors.primary, Color(0xFFA78BFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.business_outlined,
                    size: 36, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text('No workspace selected',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Create or join a workspace to get started',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                width: 200,
                child: ElevatedButton(
                  onPressed: () => context.go('/workspace'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SpiceColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Set Up Workspace'),
                ),
              ),
            ],
          ),
        ).animate().fadeIn().scaleXY(begin: 0.95),
      );
    }

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final userName = ref.watch(authStateProvider).user?.userMetadata?['name']
            as String? ??
        'User';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 300.ms)
            .slideX(begin: -0.04, curve: Curves.easeOut),

        const SizedBox(height: 24),

        Text('Overview',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 15, color: SpiceColors.textSecondary))
            .animate(delay: 100.ms)
            .fadeIn(),
        const SizedBox(height: 12),

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
              label: "Today's Sales",
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
          ].animate(interval: 80.ms, delay: 150.ms).fadeIn().slideY(
              begin: 0.08, curve: Curves.easeOut),
        ),

        const SizedBox(height: 28),

        Text('Quick Actions',
                style: Theme.of(context).textTheme.titleLarge)
            .animate(delay: 400.ms)
            .fadeIn(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.point_of_sale_rounded,
                label: 'New Sale',
                color: SpiceColors.accent,
                onTap: () => context.go('/pos'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.add_box_rounded,
                label: 'Add Product',
                color: SpiceColors.primary,
                onTap: () => context.go('/inventory'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.analytics_rounded,
                label: 'Reports',
                color: const Color(0xFF8B5CF6),
                onTap: () => context.go('/reports'),
              ),
            ),
          ].animate(interval: 80.ms, delay: 480.ms).fadeIn().slideY(
              begin: 0.08, curve: Curves.easeOut),
        ),

        const SizedBox(height: 28),

        Text('Recent Activity',
                style: Theme.of(context).textTheme.titleLarge)
            .animate(delay: 600.ms)
            .fadeIn(),
        const SizedBox(height: 12),
        GlassCard(
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: SpiceColors.textSecondary.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.hourglass_empty_rounded,
                    size: 28, color: SpiceColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Text('No recent activity',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 15)),
              const SizedBox(height: 4),
              Text('Sales and inventory actions will appear here',
                  style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ).animate(delay: 700.ms).fadeIn().scaleXY(begin: 0.98),

        const SizedBox(height: 24),
        Center(
          child: Text(
            'Made by Shahid Singh',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontSize: 11),
          ),
        ).animate(delay: 900.ms).fadeIn(),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [color.withAlpha(50), color.withAlpha(10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: color.withAlpha(60),
          width: 0.5,
        ),
      ),
      child: GlassCard(
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.all(18),
        backgroundColor: Colors.transparent,
        blur: 0,
        shadows: const [],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Icon(Icons.trending_up_rounded,
                    size: 16, color: color.withAlpha(120)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: SpiceColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [color.withAlpha(30), color.withAlpha(5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.withAlpha(50), width: 0.5),
        ),
        child: GlassCard(
          borderRadius: BorderRadius.circular(18),
          padding: const EdgeInsets.symmetric(vertical: 22),
          backgroundColor: Colors.transparent,
          blur: 0,
          shadows: const [],
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
