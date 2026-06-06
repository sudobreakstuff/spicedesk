import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_client.dart';
import '../../workspace/domain/workspace_state.dart';

final workspaceSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return {};

  final data = await supabase
      .from('workspaces')
      .select('settings')
      .eq('id', wsId)
      .maybeSingle();

  return (data?['settings'] as Map<String, dynamic>?) ?? {};
});

final deliveryChargeProvider = FutureProvider<double>((ref) async {
  final settings = await ref.watch(workspaceSettingsProvider.future);
  return (settings['delivery_charge'] as num?)?.toDouble() ?? 20.0;
});

final taxRateProvider = FutureProvider<double>((ref) async {
  final settings = await ref.watch(workspaceSettingsProvider.future);
  return (settings['tax_rate'] as num?)?.toDouble() ?? 0.0;
});

final invoiceFooterProvider = FutureProvider<String>((ref) async {
  final settings = await ref.watch(workspaceSettingsProvider.future);
  return settings['invoice_footer'] as String? ?? 'Thank you for your business!';
});
