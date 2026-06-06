import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../customers/data/customers_provider.dart';
import '../../../inventory/data/inventory_provider.dart';
import '../../../products/data/products_provider.dart';
import '../../../sales/data/sales_provider.dart';
import '../../domain/workspace_state.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  final _nameCtrl = TextEditingController();
  bool _creating = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreateWorkspace() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a business name');
      return;
    }
    if (name.length < 2) {
      setState(() => _error = 'Name must be at least 2 characters');
      return;
    }

    setState(() {
      _creating = true;
      _error = null;
    });

    try {
      await ref.read(workspaceStateProvider.notifier).createWorkspace(name);
      _invalidateWorkspaceProviders();
      if (!mounted) return;
      _nameCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Workspace "$name" created successfully'),
          backgroundColor: SpiceColors.accent,
        ),
      );
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _handleSelectWorkspace(Map<String, dynamic> ws) async {
    await ref.read(workspaceStateProvider.notifier).selectWorkspace(ws);
    _invalidateWorkspaceProviders();
    if (mounted) context.go('/dashboard');
  }

  void _invalidateWorkspaceProviders() {
    ref.invalidate(workspacesProvider);
    ref.invalidate(productsProvider);
    ref.invalidate(inventoryProvider);
    ref.invalidate(productsNeedingInventoryProvider);
    ref.invalidate(customersProvider);
    ref.invalidate(customerCountProvider);
    ref.invalidate(salesProvider);
    ref.invalidate(todaySalesProvider);
  }

  Future<void> _showRenameDialog(String wsId, String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpiceColors.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: SpiceColors.border)),
        title: Text('Rename Workspace', style: TextStyle(color: SpiceColors.textPrimary)),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != currentName) {
      await ref.read(workspaceStateProvider.notifier).renameWorkspace(wsId, result);
      _invalidateWorkspaceProviders();
    }
  }

  Future<void> _showDeleteDialog(String wsId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpiceColors.surfaceAlt,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: SpiceColors.border)),
        title: Text('Delete "$name"?', style: TextStyle(color: SpiceColors.textPrimary)),
        content: Text('This will permanently delete the workspace and all its data. This cannot be undone.', style: TextStyle(color: SpiceColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete'), style: ElevatedButton.styleFrom(backgroundColor: SpiceColors.danger)),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(workspaceStateProvider.notifier).deleteWorkspace(wsId);
      _invalidateWorkspaceProviders();
      ref.invalidate(workspacesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspaces = ref.watch(workspacesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Workspaces'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
          tooltip: 'Back to Dashboard',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your Workspaces',
                  style: Theme.of(context).textTheme.headlineLarge,
                ).animate().fadeIn(),

                SizedBox(height: 8),
                Text(
                  'Create or join a workspace to get started',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                SizedBox(height: 32),

                workspaces.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return Container(
                        decoration: BoxDecoration(
                          color: SpiceColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: SpiceColors.border),
                        ),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.business_outlined,
                                size: 48, color: SpiceColors.textSecondary),
                            SizedBox(height: 12),
                            Text('No workspaces yet',
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                            SizedBox(height: 4),
                            Text('Create your first workspace below',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms);
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ws = list[index];
                        return Material(
                          color: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                              color: SpiceColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: SpiceColors.border),
                            ),
                            child: ListTile(
                              onTap: () => _handleSelectWorkspace(ws),
                              leading: Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [SpiceColors.primary, Color(0xFF818CF8)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.store, color: Colors.white, size: 22),
                              ),
                              title: Text(ws['name'] ?? '', style: Theme.of(context).textTheme.titleMedium),
                              subtitle: Text(ws['role'] ?? 'member', style: Theme.of(context).textTheme.labelMedium),
                              trailing: PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert, color: SpiceColors.textSecondary),
                                color: SpiceColors.surfaceAlt,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: SpiceColors.border)),
                                onSelected: (action) async {
                                  final wsId = ws['workspace_id'] as String;
                                  if (action == 'edit') {
                                    _showRenameDialog(wsId, ws['name'] ?? '');
                                  } else if (action == 'delete') {
                                    _showDeleteDialog(wsId, ws['name'] ?? '');
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16, color: SpiceColors.primary), SizedBox(width: 8), Text('Rename', style: TextStyle(color: SpiceColors.primary))])),
                                  PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: SpiceColors.danger), SizedBox(width: 8), Text('Delete', style: TextStyle(color: SpiceColors.danger))])),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Container(
                    decoration: BoxDecoration(
                      color: SpiceColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SpiceColors.danger),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: SpiceColors.danger),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Failed to load workspaces: $e',
                              style: TextStyle(
                                  color: SpiceColors.danger)),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 32),

                Container(
                  decoration: BoxDecoration(
                    color: SpiceColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: SpiceColors.border),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Create a Workspace',
                          style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: 16),
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Business Name',
                          hintText: 'e.g. My Coffee Shop',
                          prefixIcon: Icon(Icons.business),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleCreateWorkspace(),
                      ),
                      if (_error != null) ...[
                        SizedBox(height: 8),
                        Text(_error!,
                            style:
                                TextStyle(color: SpiceColors.danger)),
                      ],
                      SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _creating
                              ? null
                              : _handleCreateWorkspace,
                          icon: _creating
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : Icon(Icons.add, size: 20),
                          label:
                              Text(_creating ? 'Creating...' : 'Create'),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),

                SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/dashboard'),
                  child: Text('Skip for now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
