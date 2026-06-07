import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: ListView(
        padding: const EdgeInsets.all(40),
        children: [
          SizedBox(height: 20),
          _buildHeader(context),
          SizedBox(height: 32),
          _buildDedication(),
          SizedBox(height: 32),
          _buildMission(),
          SizedBox(height: 36),
          _buildFeatures(),
          SizedBox(height: 36),
          _buildHowItWorks(),
          SizedBox(height: 36),
          _buildVersionHistory(),
          SizedBox(height: 36),
          _buildTechStack(),
          SizedBox(height: 36),
          _buildGuides(),
          SizedBox(height: 36),
          _buildCredits(context),
          SizedBox(height: 60),
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
            gradient: LinearGradient(
              colors: [SpiceColors.primary, Color(0xFF818CF8)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: SpiceColors.primary.withAlpha(60),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.store_rounded, color: Colors.white, size: 36),
        ),
        SizedBox(height: 24),
        Text(
          'SpiceDesk',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
        ),
        SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: SpiceColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SpiceColors.primary.withAlpha(60)),
          ),
          child: Text(
            'v2.3.4',
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
            Color(0xFF8B5CF6).withAlpha(15),
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
            child: Icon(Icons.favorite_rounded,
                color: SpiceColors.primary, size: 22),
          ),
          SizedBox(width: 16),
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
                SizedBox(height: 4),
                Text(
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
            child: Icon(Icons.rocket_launch_rounded,
                color: SpiceColors.accent, size: 20),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Our Mission',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: SpiceColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
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

  Widget _buildFeatures() {
    final features = [
      (Icons.point_of_sale_rounded, 'Point of Sale', 'Fast checkout with barcode scanning and receipt printing'),
      (Icons.inventory_2_rounded, 'Inventory Management', 'Real-time stock tracking with low-stock alerts'),
      (Icons.analytics_rounded, 'Sales Analytics', 'Daily, weekly, and monthly revenue reports with charts'),
      (Icons.receipt_long_rounded, 'Invoicing', 'Professional PDF invoices with company branding'),
      (Icons.people_rounded, 'Customer CRM', 'Customer profiles with purchase history tracking'),
      (Icons.money_rounded, 'Expense Tracking', 'Log and categorize business expenses'),
      (Icons.description_rounded, 'Quotations', 'Create and send quotes, convert to sales'),
      (Icons.workspaces_rounded, 'Multi-workspace', 'Manage multiple business locations'),
      (Icons.campaign_rounded, 'Marketing', 'WhatsApp broadcasts & campaign planning — Coming soon'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Features', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
        SizedBox(height: 16),
        ...features.map((f) => _FeatureRow(icon: f.$1, title: f.$2, subtitle: f.$3)),
      ],
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How It Works', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
        SizedBox(height: 20),
        ...['Add products & set stock levels', 'Make sales through the POS', 'Inventory updates automatically', 'View reports & analytics', 'Send invoices & manage expenses']
            .asMap()
            .entries
            .map((e) => _FlowStep(index: e.key + 1, label: e.value, isLast: e.key == 4)),
      ],
    );
  }

  Widget _buildVersionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Version History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
        SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SpiceColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SpiceColors.border),
          ),
          child: Column(
            children: [
              _VersionRow(version: 'v2.3.4', date: 'June 2026', changes: ['Theme system with 6 color themes', 'Enhanced About screen', 'Performance improvements']),
              _VersionRow(version: 'v2.2.7', date: 'April 2026', changes: ['PDF invoice generation', 'Company branding settings', 'Banking details on invoices']),
              _VersionRow(version: 'v1.8.2', date: 'Jan 2026', changes: ['Expense tracking module', 'Customer CRM', 'Multi-workspace support']),
              _VersionRow(version: 'v1.3.1', date: 'Oct 2025', changes: ['Barcode scanning', 'Quotation system', 'Sales analytics dashboard']),
              _VersionRow(version: 'v1.0.0', date: 'July 2025', changes: ['Initial release', 'POS with inventory', 'Basic reporting'], isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTechStack() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tech Stack', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
        SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SpiceColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SpiceColors.border),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TechChip(icon: Icons.flutter_dash, label: 'Flutter'),
              _TechChip(icon: Icons.language, label: 'Dart'),
              _TechChip(icon: Icons.cloud, label: 'Supabase'),
              _TechChip(icon: Icons.storage, label: 'PostgreSQL'),
              _TechChip(icon: Icons.bar_chart, label: 'fl_chart'),
              _TechChip(icon: Icons.picture_as_pdf, label: 'PDF'),
              _TechChip(icon: Icons.router, label: 'GoRouter'),
              _TechChip(icon: Icons.architecture, label: 'Riverpod'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuides() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Guide',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: SpiceColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 20),
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
          color: Color(0xFF8B5CF6),
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
          color: Color(0xFF06B6D4),
          steps: [
            'Add customer profiles with contact details',
            'Track purchase history per customer',
            'Build loyalty through repeat service',
            'Export customer lists for outreach',
          ],
        ),
      ],
    );
  }

  Widget _buildCredits(BuildContext context) {
    final githubUrl = Uri.parse('https://github.com/anomalyco/spicedesk');

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
            Text(
              'Made by Shahid Singh',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: SpiceColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
            SizedBox(height: 12),
            GestureDetector(
              onTap: () => launchUrl(githubUrl, mode: LaunchMode.externalApplication),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.code, color: SpiceColors.primary.withAlpha(200), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'GitHub',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: SpiceColors.primary.withAlpha(220),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'SpiceDesk Business Suite',
              style: TextStyle(
                fontSize: 11,
                color: SpiceColors.textSecondary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Version 2.3.4 — Made in South Africa',
              style: TextStyle(fontSize: 11, color: SpiceColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  _FeatureRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: SpiceColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: SpiceColors.primary, size: 18),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
                SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  final int index;
  final String label;
  final bool isLast;
  _FlowStep({required this.index, required this.label, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: SpiceColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SpiceColors.primary.withAlpha(80)),
                ),
                alignment: Alignment.center,
                child: Text('$index', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: SpiceColors.primary)),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  color: SpiceColors.border,
                ),
            ],
          ),
        ),
        SizedBox(width: 12),
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: SpiceColors.textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _VersionRow extends StatelessWidget {
  final String version;
  final String date;
  final List<String> changes;
  final bool isLast;
  _VersionRow({required this.version, required this.date, required this.changes, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SpiceColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(version, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.primary)),
              ),
            ],
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: SpiceColors.textSecondary)),
                SizedBox(height: 4),
                ...changes.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 7),
                        child: Icon(Icons.circle, size: 4, color: SpiceColors.primary),
                      ),
                      SizedBox(width: 6),
                      Expanded(child: Text(c, style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TechChip extends StatelessWidget {
  final IconData icon;
  final String label;
  _TechChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: SpiceColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SpiceColors.primary.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: SpiceColors.primary),
          SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: SpiceColors.textPrimary)),
        ],
      ),
    );
  }
}

// ── Guide carousel ──

class _GuideCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<String> steps;

  _GuideCard({
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
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: SpiceColors.textPrimary,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: Duration(milliseconds: 200),
                        child: Icon(Icons.keyboard_arrow_down_rounded,
                            color: SpiceColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: SizedBox(width: double.infinity),
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
                              Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Icon(Icons.circle,
                                    size: 6, color: SpiceColors.primary),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  step,
                                  style: TextStyle(
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
                  duration: Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
