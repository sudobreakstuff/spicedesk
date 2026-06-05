import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';

class Campaign {
  String id;
  String title;
  String description;
  String platform;
  DateTime scheduledDate;
  String status; // draft, scheduled, published

  Campaign({
    required this.id,
    required this.title,
    required this.description,
    required this.platform,
    required this.scheduledDate,
    this.status = 'draft',
  });
}

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  final List<Campaign> _campaigns = [];
  final _dateFormat = DateFormat('dd MMM yyyy');

  Color _statusColor(String status) {
    switch (status) {
      case 'published':
        return SpiceColors.accent;
      case 'scheduled':
        return SpiceColors.primary;
      default:
        return SpiceColors.warning;
    }
  }

  void _showCampaignDialog({Campaign? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String platform = existing?.platform ?? 'Instagram';
    DateTime date = existing?.scheduledDate ?? DateTime.now();
    String status = existing?.status ?? 'draft';

    final platforms = ['Instagram', 'Facebook', 'WhatsApp', 'Email'];
    final statuses = ['draft', 'scheduled', 'published'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: SpiceColors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: SpiceColors.border),
          ),
          title: Text(existing != null ? 'Edit Campaign' : 'New Campaign'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 16),
                const Text('Platform',
                    style: TextStyle(
                        fontSize: 13, color: SpiceColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: platforms.map((p) => ChoiceChip(
                    label: Text(p),
                    selected: platform == p,
                    onSelected: (_) =>
                        setDialogState(() => platform = p),
                    selectedColor:
                        SpiceColors.primary.withAlpha(40),
                    labelStyle: TextStyle(
                      color: platform == p
                          ? SpiceColors.primary
                          : SpiceColors.textSecondary,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Status',
                    style: TextStyle(
                        fontSize: 13, color: SpiceColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: statuses.map((s) => ChoiceChip(
                    label: Text(s[0].toUpperCase() + s.substring(1)),
                    selected: status == s,
                    onSelected: (_) =>
                        setDialogState(() => status = s),
                    selectedColor:
                        _statusColor(s).withAlpha(40),
                    labelStyle: TextStyle(
                      color: status == s
                          ? _statusColor(s)
                          : SpiceColors.textSecondary,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today,
                      color: SpiceColors.textSecondary),
                  title: Text(_dateFormat.format(date),
                      style: const TextStyle(
                          color: SpiceColors.textPrimary, fontSize: 14)),
                  trailing: const Icon(Icons.edit_calendar,
                      color: SpiceColors.primary, size: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => date = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            if (existing != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _campaigns.removeWhere((c) => c.id == existing.id);
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Delete',
                    style: TextStyle(color: SpiceColors.danger)),
              ),
            ElevatedButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                setState(() {
                  if (existing != null) {
                    existing.title = title;
                    existing.description = descCtrl.text.trim();
                    existing.platform = platform;
                    existing.scheduledDate = date;
                    existing.status = status;
                  } else {
                    _campaigns.add(Campaign(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: title,
                      description: descCtrl.text.trim(),
                      platform: platform,
                      scheduledDate: date,
                      status: status,
                    ));
                  }
                });
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<Campaign>.from(_campaigns)
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Marketing',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: SpiceColors.textPrimary)),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: SpiceColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${_campaigns.length} campaigns',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: SpiceColors.primary)),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showCampaignDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Campaign'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Content planner & campaign manager',
                style: TextStyle(
                    fontSize: 14, color: SpiceColors.textSecondary)),
            const SizedBox(height: 24),
            Expanded(
              child: _campaigns.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        color: SpiceColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SpiceColors.border),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.campaign_outlined,
                                size: 48,
                                color: SpiceColors.textSecondary),
                            SizedBox(height: 12),
                            Text('No campaigns yet',
                                style: TextStyle(
                                    color: SpiceColors.textSecondary,
                                    fontSize: 15)),
                            SizedBox(height: 4),
                            Text(
                                'Create your first campaign to get started',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: SpiceColors.textSecondary)),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: sorted.length,
                      itemBuilder: (context, index) {
                        final c = sorted[index];
                        final iconMap = {
                          'Instagram': Icons.camera_alt_outlined,
                          'Facebook': Icons.facebook,
                          'WhatsApp': Icons.chat_outlined,
                          'Email': Icons.email_outlined,
                        };
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: SpiceColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  _showCampaignDialog(existing: c),
                              onLongPress: () =>
                                  _showCampaignDialog(existing: c),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: SpiceColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: SpiceColors.primary
                                            .withAlpha(20),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        iconMap[c.platform] ??
                                            Icons.campaign,
                                        color: SpiceColors.primary,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(c.title,
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: SpiceColors
                                                      .textPrimary)),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${c.platform}  ·  ${_dateFormat.format(c.scheduledDate)}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: SpiceColors
                                                    .textSecondary),
                                          ),
                                          if (c.description.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                      top: 4),
                                              child: Text(
                                                c.description,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: SpiceColors
                                                        .textSecondary),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(c.status)
                                            .withAlpha(20),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        c.status[0].toUpperCase() +
                                            c.status.substring(1),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _statusColor(c.status),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.chevron_right,
                                        color: SpiceColors.border,
                                        size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
