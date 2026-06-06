import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../features/workspace/domain/workspace_state.dart';

class Campaign {
  final String id;
  final String title;
  final String? description;
  final String? platform;
  final DateTime? scheduledAt;
  final String status;
  final DateTime createdAt;

  Campaign({
    required this.id,
    required this.title,
    this.description,
    this.platform,
    this.scheduledAt,
    this.status = 'draft',
    required this.createdAt,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      platform: json['platform'] as String?,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'] as String)
          : null,
      status: json['status'] as String? ?? 'draft',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

final campaignsProvider =
    FutureProvider<List<Campaign>>((ref) async {
  final wsId = ref.read(workspaceStateProvider).selectedId;
  if (wsId == null) return [];

  final data = await supabase
      .from('marketing_campaigns')
      .select()
      .eq('workspace_id', wsId)
      .order('created_at', ascending: false);

  return (data as List).map((e) => Campaign.fromJson(e)).toList();
});

final createCampaignAction = Provider<Future<void> Function({
  required String title,
  String? description,
  String? platform,
  DateTime? scheduledAt,
})>((ref) {
  return ({
    required String title,
    String? description,
    String? platform,
    DateTime? scheduledAt,
  }) async {
    final wsId = ref.read(workspaceStateProvider).selectedId;
    if (wsId == null) throw Exception('No workspace selected');

    await supabase.from('marketing_campaigns').insert({
      'workspace_id': wsId,
      'title': title,
      'description': description,
      'platform': platform,
      'scheduled_at': scheduledAt?.toIso8601String(),
    });

    ref.invalidate(campaignsProvider);
  };
});

final updateCampaignAction = Provider<Future<void> Function({
  required String id,
  String? title,
  String? description,
  String? platform,
  DateTime? scheduledAt,
  String? status,
})>((ref) {
  return ({
    required String id,
    String? title,
    String? description,
    String? platform,
    DateTime? scheduledAt,
    String? status,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (platform != null) updates['platform'] = platform;
    if (scheduledAt != null) updates['scheduled_at'] = scheduledAt.toIso8601String();
    if (status != null) updates['status'] = status;
    updates['updated_at'] = DateTime.now().toIso8601String();

    await supabase.from('marketing_campaigns').update(updates).eq('id', id);
    ref.invalidate(campaignsProvider);
  };
});

final deleteCampaignAction = Provider<Future<void> Function(String id)>((ref) {
  return (String id) async {
    await supabase.from('marketing_campaigns').delete().eq('id', id);
    ref.invalidate(campaignsProvider);
  };
});
