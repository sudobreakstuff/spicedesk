import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: ListView(
        padding: const EdgeInsets.all(40),
        children: [
          const SizedBox(height: 20),
          _buildHeader(context),
          const SizedBox(height: 32),
          _buildDedication(),
          const SizedBox(height: 32),
          _buildMission(),
          const SizedBox(height: 36),
          _buildGuides(),
          const SizedBox(height: 36),
          _buildCredits(context),
          const SizedBox(height: 60),
        ].animate(interval: 100.ms).fadeIn().slideY(begin: 12),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [SpiceColors.primary, Color(0xFF818CF8)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: SpiceColors.primary.withAlpha(60),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.store_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 24),
        Text(
          'SpiceDesk',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: SpiceColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SpiceColors.primary.withAlpha(60)),
          ),
          child: const Text(
            'v1.2',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SpiceColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDedication() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SpiceColors.primary.withAlpha(20),
            const Color(0xFF8B5CF6).withAlpha(15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SpiceColors.primary.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: SpiceColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.favorite_rounded,
                color: SpiceColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dedicated to Mum and Dad',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: SpiceColors.primary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Thank you for everything. This one is for you.',
                  style: TextStyle(
                    fontSize: 13,
                    color: SpiceColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMission() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SpiceColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SpiceColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SpiceColors.accent.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.rocket_launch_rounded,
                color: SpiceColors.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Our Mission',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: SpiceColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'To empower small businesses with simple, powerful tools that make everyday operations effortless.',
                  style: TextStyle(
                    fontSize: 14,
                    color: SpiceColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuides() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Guide',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: SpiceColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 20),
        _GuideCard(
          icon: Icons.flag_rounded,
          title: 'Getting Started',
          color: SpiceColors.primary,
          steps: [
            'Sign up for a SpiceDesk account',
            'Create your products and set prices',
            'Add your initial stock quantities',
            'Start making sales through the POS',
          ],
        ),
        _GuideCard(
          icon: Icons.point_of_sale_rounded,
          title: 'Point of Sale',
          color: SpiceColors.accent,
          steps: [
            'Add items to cart by searching or scanning',
            'Select a customer or walk-in sale',
            'Apply discounts if needed',
            'Choose payment method and complete the sale',
            'Print or email receipts to customers',
          ],
        ),
        _GuideCard(
          icon: Icons.inventory_2_rounded,
          title: 'Inventory',
          color: const Color(0xFF8B5CF6),
          steps: [
            'View all products with stock levels',
            'Filter by low stock to see items needing restock',
            'Adjust stock quantities manually',
            'Set reorder points to get low stock alerts',
            'Track cost prices for profit calculations',
          ],
        ),
        _GuideCard(
          icon: Icons.analytics_rounded,
          title: 'Reports',
          color: SpiceColors.warning,
          steps: [
            'View daily, weekly, and monthly sales data',
            'Track profit margins over time',
            'Identify top-selling products',
            'Monitor transaction counts and averages',
            'Export reports for accounting',
          ],
        ),
        _GuideCard(
          icon: Icons.receipt_long_rounded,
          title: 'Expenses',
          color: SpiceColors.danger,
          steps: [
            'Log business expenses as they occur',
            'Categorize expenses for better tracking',
            'Review expense summaries by period',
            'Compare expenses against revenue',
            'Plan budgets based on historical data',
          ],
        ),
        _GuideCard(
          icon: Icons.people_rounded,
          title: 'Customers',
          color: const Color(0xFF06B6D4),
          steps: [
            'Add customer profiles with contact details',
            'Track purchase history per customer',
            'Build loyalty through repeat service',
            'Use customer data for targeted marketing',
            'Export customer lists for outreach',
          ],
        ),
      ],
    );
  }

  Widget _buildCredits(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SpiceColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SpiceColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            const Text(
              'Made by Shahid Singh',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SpiceColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.favorite, color: SpiceColors.danger, size: 14),
                SizedBox(width: 4),
                Text(
                  'Built with passion',
                  style: TextStyle(
                    fontSize: 12,
                    color: SpiceColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'SpiceDesk Business Suite',
              style: TextStyle(
                fontSize: 11,
                color: SpiceColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Version 1.2 — Made in South Africa',
              style: TextStyle(fontSize: 11, color: SpiceColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

}

class _GuideCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<String> steps;

  const _GuideCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.steps,
  });

  @override
  State<_GuideCard> createState() => _GuideCardState();
}

class _GuideCardState extends State<_GuideCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: SpiceColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _expanded
                    ? widget.color.withAlpha(80)
                    : SpiceColors.border,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: widget.color.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(widget.icon, color: widget.color, size: 19),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: SpiceColors.textPrimary,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: SpiceColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Column(
                      children: widget.steps.map((step) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Icon(Icons.circle,
                                    size: 6, color: SpiceColors.primary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  step,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: SpiceColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
