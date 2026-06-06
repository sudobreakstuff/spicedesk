import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_client.dart';

class WorkspaceState {
  final String? selectedId;
  final String? selectedName;

  WorkspaceState({this.selectedId, this.selectedName});

  factory WorkspaceState.initial() => WorkspaceState();
}

class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  WorkspaceNotifier() : super(WorkspaceState.initial()) {
    _load();
  }

  void _load() {
    final id = prefs.getString('workspace_id');
    final name = prefs.getString('workspace_name');
    if (id != null) {
      state = WorkspaceState(selectedId: id, selectedName: name);
    } else {
      _autoSelectFirst();
    }
  }

  Future<void> _autoSelectFirst() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Get user's workspaces, ordered by most recent activity
    final data = await supabase
        .from('workspace_members')
        .select('workspace_id, workspaces(name)')
        .eq('user_id', user.id)
        .order('joined_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data != null) {
      final ws = data['workspaces'] as Map<String, dynamic>? ?? {};
      final id = data['workspace_id'] as String;
      final name = ws['name'] as String? ?? 'My Store';
      await prefs.setString('workspace_id', id);
      await prefs.setString('workspace_name', name);
      state = WorkspaceState(selectedId: id, selectedName: name);
    }
  }

  Future<void> createWorkspace(String name) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('You must be logged in to create a workspace');

    final response = await supabase
        .from('workspaces')
        .insert({'name': name, 'created_by': user.id})
        .select()
        .single();

    final wsId = response['id'] as String;
    await supabase.from('workspace_members').insert({
      'workspace_id': wsId,
      'user_id': user.id,
      'role': 'owner',
    });

    await prefs.setString('workspace_id', wsId);
    await prefs.setString('workspace_name', name);
    state = WorkspaceState(selectedId: wsId, selectedName: name);
  }

  Future<void> selectWorkspace(Map<String, dynamic> ws) async {
    final id = (ws['workspace_id'] ?? ws['id']) as String;
    final name = (ws['name'] ?? ws['workspace_name'] ?? 'Unknown') as String;
    await prefs.setString('workspace_id', id);
    await prefs.setString('workspace_name', name);
    state = WorkspaceState(selectedId: id, selectedName: name);
  }

  Future<void> updateWorkspaceName(String name) async {
    if (state.selectedId == null) throw Exception('No workspace selected');
    await supabase
        .from('workspaces')
        .update({'name': name}).eq('id', state.selectedId!);
    await prefs.setString('workspace_name', name);
    state = WorkspaceState(selectedId: state.selectedId, selectedName: name);
  }

  Future<void> joinWorkspace(String inviteCode) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('workspaces')
        .select('id, name')
        .eq('invite_code', inviteCode)
        .maybeSingle();

    if (response == null) throw Exception('Invalid invite code');

    await supabase.from('workspace_members').insert({
      'workspace_id': response['id'],
      'user_id': user.id,
      'role': 'member',
    });
  }
}

final workspaceStateProvider =
    StateNotifierProvider<WorkspaceNotifier, WorkspaceState>(
        (ref) => WorkspaceNotifier());

final workspacesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(workspaceStateProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final data = await supabase
      .from('workspace_members')
      .select('workspace_id, role, workspaces(name)')
      .eq('user_id', user.id);

  return data.map<Map<String, dynamic>>((row) {
    final ws = row['workspaces'] as Map<String, dynamic>? ?? {};
    return {
      'workspace_id': row['workspace_id'],
      'name': ws['name'] ?? 'Unknown',
      'role': row['role'],
    };
  }).toList();
});
