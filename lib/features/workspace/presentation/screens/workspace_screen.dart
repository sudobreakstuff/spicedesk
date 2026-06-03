import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/glass_widgets.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/workspace_state.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final workspaces = ref.watch(workspacesProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your Workspaces',
                  style: Theme.of(context).textTheme.headlineLarge,
                ).animate().fadeIn(),

                const SizedBox(height: 8),
                Text(
                  'Create or join a workspace to get started',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 32),

                // Existing workspaces
                workspaces.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return GlassCard(
                        borderRadius: BorderRadius.circular(16),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.business_outlined,
                                size: 48, color: SpiceColors.textSecondary),
                            const SizedBox(height: 12),
                            Text('No workspaces yet',
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text('Create your first workspace below',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms);
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ws = list[index];
                        return GlassCard(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => ref
                              .read(workspaceStateProvider.notifier)
                              .selectWorkspace(ws),
                          child: ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    SpiceColors.primary,
                                    Color(0xFF818CF8)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.store,
                                  color: Colors.white, size: 22),
                            ),
                            title: Text(ws['name'] ?? '',
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                            subtitle: Text(
                              ws['role'] ?? 'member',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 16),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Text('Error: $e'),
                ),

                const SizedBox(height: 32),

                // Create workspace
                GlassCard(
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Create a Workspace',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Business Name',
                          prefixIcon: Icon(Icons.business),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!,
                            style: const TextStyle(color: SpiceColors.danger)),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _creating
                              ? null
                              : () async {
                                  final name = _nameCtrl.text.trim();
                                  if (name.isEmpty) {
                                    setState(
                                        () => _error = 'Enter a business name');
                                    return;
                                  }
                                  setState(() {
                                    _creating = true;
                                    _error = null;
                                  });
                                  try {
                                    await ref
                                        .read(workspaceStateProvider.notifier)
                                        .createWorkspace(name);
                                    _nameCtrl.clear();
                                  } catch (e) {
                                    setState(() => _error = e.toString());
                                  }
                                  if (mounted) {
                                    setState(() => _creating = false);
                                  }
                                },
                          icon: _creating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.add, size: 20),
                          label: Text(_creating ? 'Creating...' : 'Create'),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),

                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Skip for now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
