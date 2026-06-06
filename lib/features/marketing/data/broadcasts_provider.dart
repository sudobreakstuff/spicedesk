import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../features/workspace/domain/workspace_state.dart';

class BroadcastRecord {
  final String id;
  final String? campaignId;
  final String? customerId;
  final String channel;
  final String? message;
  final String status;
  final DateTime? sentAt;
  final DateTime createdAt;

  BroadcastRecord({
    required this.id,
    this.campaignId,
    this.customerId,
    required this.channel,
    this.message,
    this.status = 'pending',
    this.sentAt,
    required this.createdAt,
  });

  factory BroadcastRecord.fromJson(Map<String, dynamic> json) {
    return BroadcastRecord(
      id: json['id'] as String,
      campaignId: json['campaign_id'] as String?,
      customerId: json['customer_id'] as String?,
      channel: json['channel'] as String,
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'pending',
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

final broadcastLogProvider =
    FutureProvider<List<BroadcastRecord>>((ref) async {
  final wsId = ref.read(workspaceStateProvider).selectedId;
  if (wsId == null) return [];

  final data = await supabase
      .from('broadcast_log')
      .select()
      .eq('workspace_id', wsId)
      .order('created_at', ascending: false);

  return (data as List).map((e) => BroadcastRecord.fromJson(e)).toList();
});

Future<void> sendViaWhatsApp({
  required String phone,
  required String message,
}) async {
  final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
  final uri = Uri.parse(
    'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw Exception('Could not open WhatsApp');
  }
}

final logBroadcastAction = Provider<Future<void> Function({
  String? campaignId,
  String? customerId,
  required String channel,
  String? message,
})>((ref) {
  return ({
    String? campaignId,
    String? customerId,
    required String channel,
    String? message,
  }) async {
    final wsId = ref.read(workspaceStateProvider).selectedId;
    if (wsId == null) throw Exception('No workspace selected');

    await supabase.from('broadcast_log').insert({
      'workspace_id': wsId,
      'campaign_id': campaignId,
      'customer_id': customerId,
      'channel': channel,
      'message': message,
      'status': 'sent',
      'sent_at': DateTime.now().toIso8601String(),
    });

    ref.invalidate(broadcastLogProvider);
  };
});
