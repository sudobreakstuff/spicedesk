import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/campaigns_provider.dart';
import '../../data/segments_provider.dart';
import '../../data/broadcasts_provider.dart';
import '../../../customers/data/customers_provider.dart';

class MarketingScreen extends ConsumerWidget {
  const MarketingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: SpiceColors.surface,
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Marketing',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
              SizedBox(height: 4),
              Text('Campaigns, broadcasts & customer segments',
                  style: TextStyle(fontSize: 14, color: SpiceColors.textSecondary)),
              SizedBox(height: 20),
              TabBar(
                tabs: [
                  Tab(text: 'Campaigns'),
                  Tab(text: 'Broadcasts'),
                  Tab(text: 'Segments'),
                ],
                labelColor: SpiceColors.primary,
                unselectedLabelColor: SpiceColors.textSecondary,
                indicatorColor: SpiceColors.primary,
              ),
              SizedBox(height: 20),
              Expanded(child: TabBarView(
                children: [
                  _CampaignsTab(),
                  _BroadcastsTab(),
                  _SegmentsTab(),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CAMPAIGNS TAB
// ============================================================
class _CampaignsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(campaignsProvider);
    final campaigns = campaignsAsync.valueOrNull ?? [];
    return Column(
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: SpiceColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${campaigns.length} campaigns',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.primary)),
          ),
          Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showCampaignDialog(context, ref),
            icon: Icon(Icons.add, size: 18),
            label: Text('New Campaign'),
          ),
        ]),
        SizedBox(height: 16),
        Expanded(
          child: campaignsAsync.isLoading
              ? Center(child: CircularProgressIndicator())
              : campaigns.isEmpty
                  ? _emptyState(Icons.campaign_outlined, 'No campaigns yet', 'Create your first campaign')
                  : ListView.builder(
                      itemCount: campaigns.length,
                      itemBuilder: (_, i) => _CampaignCard(campaigns[i]),
                    ),
        ),
      ],
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        color: SpiceColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SpiceColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: SpiceColors.textSecondary),
            SizedBox(height: 12),
            Text(title, style: TextStyle(color: SpiceColors.textSecondary, fontSize: 15)),
            SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  void _showCampaignDialog(BuildContext context, WidgetRef ref, {Campaign? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String platform = existing?.platform ?? 'Instagram';
    DateTime? date = existing?.scheduledAt;
    String status = existing?.status ?? 'draft';

    final platforms = ['Instagram', 'Facebook', 'WhatsApp', 'Email', 'SMS'];
    final statuses = ['draft', 'scheduled', 'published'];

    Color statusColor(String s) {
      switch (s) {
        case 'published': return SpiceColors.accent;
        case 'scheduled': return SpiceColors.primary;
        default: return SpiceColors.warning;
      }
    }

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
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 16),
              Text('Platform', style: TextStyle(fontSize: 13, color: SpiceColors.textSecondary)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: platforms.map((p) => ChoiceChip(
                  label: Text(p),
                  selected: platform == p,
                  onSelected: (_) => setDialogState(() => platform = p),
                  selectedColor: SpiceColors.primary.withAlpha(40),
                  labelStyle: TextStyle(
                    color: platform == p ? SpiceColors.primary : SpiceColors.textSecondary,
                  ),
                )).toList(),
              ),
              SizedBox(height: 16),
              Text('Status', style: TextStyle(fontSize: 13, color: SpiceColors.textSecondary)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: statuses.map((s) => ChoiceChip(
                  label: Text(s[0].toUpperCase() + s.substring(1)),
                  selected: status == s,
                  onSelected: (_) => setDialogState(() => status = s),
                  selectedColor: statusColor(s).withAlpha(40),
                    labelStyle: TextStyle(
                      color: status == s ? statusColor(s) : SpiceColors.textSecondary,
                  ),
                )).toList(),
              ),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SpiceColors.border),
                ),
                child: ListTile(
                  leading: Icon(Icons.calendar_today, color: SpiceColors.textSecondary),
                  title: Text(
                    date != null ? DateFormat('dd MMM yyyy').format(date!) : 'Set date',
                    style: TextStyle(color: SpiceColors.textPrimary, fontSize: 14),
                  ),
                  trailing: Icon(Icons.edit_calendar, color: SpiceColors.primary, size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setDialogState(() => date = picked);
                  },
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
            if (existing != null)
              TextButton(
                onPressed: () {
                  ref.read(deleteCampaignAction)(existing.id);
                  Navigator.pop(ctx);
                },
                child: Text('Delete', style: TextStyle(color: SpiceColors.danger)),
              ),
            ElevatedButton(
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                if (existing != null) {
                  ref.read(updateCampaignAction)(
                    id: existing.id,
                    title: title,
                    description: descCtrl.text.trim(),
                    platform: platform,
                    scheduledAt: date,
                    status: status,
                  );
                } else {
                  ref.read(createCampaignAction)(
                    title: title,
                    description: descCtrl.text.trim(),
                    platform: platform,
                    scheduledAt: date,
                  );
                }
                Navigator.pop(ctx);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;
  const _CampaignCard(this.campaign);

  Color _statusColor(String status) {
    switch (status) {
      case 'published': return SpiceColors.accent;
      case 'scheduled': return SpiceColors.primary;
      default: return SpiceColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: SpiceColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SpiceColors.border),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: SpiceColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.campaign, color: SpiceColors.primary, size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(campaign.title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
                  SizedBox(height: 3),
                  Text(
                    '${campaign.platform ?? 'No platform'}${campaign.scheduledAt != null ? '  ·  ${DateFormat('dd MMM yyyy').format(campaign.scheduledAt!)}' : ''}',
                    style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary),
                  ),
                  if (campaign.description != null && campaign.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(campaign.description!, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
                    ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(campaign.status).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                campaign.status[0].toUpperCase() + campaign.status.substring(1),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(campaign.status)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ============================================================
// BROADCASTS TAB
// ============================================================
class _BroadcastsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);
    final broadcastsAsync = ref.watch(broadcastLogProvider);
    final campaignsAsync = ref.watch(campaignsProvider);

    final customers = customersAsync.valueOrNull ?? [];
    final broadcasts = broadcastsAsync.valueOrNull ?? [];
    final campaigns = campaignsAsync.valueOrNull ?? [];

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showComposeDialog(context, ref, customers, campaigns),
            icon: Icon(Icons.send, size: 18),
            label: Text('Compose Broadcast'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SpiceColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        SizedBox(height: 20),
        Row(children: [
          Text('History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
          SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: SpiceColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${broadcasts.length} sent',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.primary)),
          ),
        ]),
        SizedBox(height: 12),
        Expanded(
          child: broadcastsAsync.isLoading
              ? Center(child: CircularProgressIndicator())
              : broadcasts.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        color: SpiceColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SpiceColors.border),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history, size: 48, color: SpiceColors.textSecondary),
                            SizedBox(height: 12),
                            Text('No broadcasts sent yet',
                                style: TextStyle(color: SpiceColors.textSecondary, fontSize: 15)),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: broadcasts.length,
                      itemBuilder: (_, i) {
                        final b = broadcasts[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: SpiceColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: SpiceColors.border),
                            ),
                            child: Row(children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: SpiceColors.accent.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.chat, color: SpiceColors.accent, size: 18),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b.message ?? '(no message)',
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 13, color: SpiceColors.textPrimary)),
                                    SizedBox(height: 2),
                                    Text(
                                      '${b.channel}  ·  ${b.sentAt != null ? DateFormat('dd MMM yyyy').format(b.sentAt!) : ''}',
                                      style: TextStyle(fontSize: 11, color: SpiceColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: SpiceColors.accent.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('Sent', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: SpiceColors.accent)),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showComposeDialog(BuildContext context, WidgetRef ref, List<Customer> customers, List<Campaign> campaigns) {
    final msgCtrl = TextEditingController();
    String? selectedCampaignId;
    final selectedCustomerIds = <String>{};
    String filterMode = 'all';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: SpiceColors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: SpiceColors.border),
          ),
          title: Text('Compose Broadcast'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Message', style: TextStyle(fontSize: 13, color: SpiceColors.textSecondary)),
              SizedBox(height: 8),
              TextField(
                controller: msgCtrl,
                maxLines: 4,
                decoration: InputDecoration(hintText: 'Type your message...'),
              ),
              SizedBox(height: 16),
              Text('Link to Campaign (optional)', style: TextStyle(fontSize: 13, color: SpiceColors.textSecondary)),
              SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SpiceColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedCampaignId,
                    hint: Text('No campaign', style: TextStyle(color: SpiceColors.textSecondary)),
                    items: [
                      DropdownMenuItem(value: null, child: Text('No campaign')),
                      ...campaigns.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.title, overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    onChanged: (v) => setDialogState(() => selectedCampaignId = v),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text('Recipients', style: TextStyle(fontSize: 13, color: SpiceColors.textSecondary)),
              SizedBox(height: 8),
              Row(children: [
                ChoiceChip(
                  label: Text('All (${customers.length})'),
                  selected: filterMode == 'all',
                  onSelected: (_) => setDialogState(() {
                    filterMode = 'all';
                    selectedCustomerIds.clear();
                    selectedCustomerIds.addAll(customers.map((c) => c.id));
                  }),
                ),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Text('With Phone'),
                  selected: filterMode == 'phone',
                  onSelected: (_) => setDialogState(() {
                    filterMode = 'phone';
                    selectedCustomerIds.clear();
                    selectedCustomerIds.addAll(
                      customers.where((c) => c.phone != null && c.phone!.isNotEmpty).map((c) => c.id),
                    );
                  }),
                ),
              ]),
              SizedBox(height: 8),
              Text('${selectedCustomerIds.length} selected',
                  style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final message = msgCtrl.text.trim();
                if (message.isEmpty || selectedCustomerIds.isEmpty) return;

                final logAction = ref.read(logBroadcastAction);
                final targets = customers.where((c) => selectedCustomerIds.contains(c.id)).toList();

                for (final customer in targets) {
                  if (customer.phone == null || customer.phone!.isEmpty) continue;
                  try {
                    await sendViaWhatsApp(phone: customer.phone!, message: message);
                    await logAction(
                      campaignId: selectedCampaignId,
                      customerId: customer.id,
                      channel: 'whatsapp',
                      message: message,
                    );
                  } catch (_) {}
                }

                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text('Broadcast sent to ${targets.length} customers'),
                    backgroundColor: SpiceColors.accent,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: Text('Send via WhatsApp'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SEGMENTS TAB
// ============================================================
class _SegmentsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segmentsAsync = ref.watch(segmentsProvider);
    final segments = segmentsAsync.valueOrNull ?? [];

    return Column(
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: SpiceColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${segments.length} segments',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.primary)),
          ),
          Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showCreateSegmentDialog(context, ref),
            icon: Icon(Icons.add, size: 18),
            label: Text('New Segment'),
          ),
        ]),
        SizedBox(height: 16),
        Expanded(
          child: segmentsAsync.isLoading
              ? Center(child: CircularProgressIndicator())
              : segments.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        color: SpiceColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SpiceColors.border),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.segment, size: 48, color: SpiceColors.textSecondary),
                            SizedBox(height: 12),
                            Text('No segments yet',
                                style: TextStyle(color: SpiceColors.textSecondary, fontSize: 15)),
                            SizedBox(height: 4),
                            Text('Create customer segments for targeted broadcasts',
                                style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: segments.length,
                      itemBuilder: (_, i) {
                        final seg = segments[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: SpiceColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: SpiceColors.border),
                            ),
                            child: Row(children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: SpiceColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.group, color: SpiceColors.primary, size: 18),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(seg.name,
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: SpiceColors.textPrimary)),
                                    SizedBox(height: 2),
                                    Text('${seg.filters.length} filters',
                                        style: TextStyle(fontSize: 11, color: SpiceColors.textSecondary)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: SpiceColors.danger, size: 20),
                                onPressed: () {
                                  ref.read(deleteSegmentAction)(seg.id);
                                },
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showCreateSegmentDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    bool hasPhone = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: SpiceColors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: SpiceColors.border),
          ),
          title: Text('New Segment'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Segment Name',
                hintText: 'e.g. VIP Customers',
              ),
            ),
            SizedBox(height: 16),
            CheckboxListTile(
              value: hasPhone,
              onChanged: (v) => setDialogState(() => hasPhone = v ?? false),
              title: Text('Has phone number', style: TextStyle(fontSize: 14, color: SpiceColors.textPrimary)),
              dense: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                ref.read(createSegmentAction)(
                  name: name,
                  filters: {'has_phone': hasPhone},
                );
                Navigator.pop(ctx);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
