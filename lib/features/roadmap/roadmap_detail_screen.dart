import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/domain_model.dart';
import '../../services/service_providers.dart';

// Providers scoped to a domain for modules and topics
final modulesProvider = StreamProvider.family<List<ModuleModel>, String>((ref, domainId) {
  final db = ref.watch(databaseRepositoryProvider);
  return db.getModules(domainId);
});

final topicsProvider =
    StreamProvider.family<List<TopicModel>, ({String domainId, String moduleId})>((ref, args) {
  final db = ref.watch(databaseRepositoryProvider);
  return db.getTopics(args.domainId, args.moduleId);
});


class RoadmapDetailScreen extends ConsumerWidget {
  final String domainId;
  const RoadmapDetailScreen({super.key, required this.domainId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domainsAsync = ref.watch(domainsProvider);
    final modulesAsync = ref.watch(modulesProvider(domainId));
    final user = ref.watch(currentUserProvider);
    final progressAsync = ref.watch(userProgressProvider(domainId));

    final domain = domainsAsync.valueOrNull?.firstWhere(
      (d) => d.id == domainId,
      orElse: () => DomainModel(
          id: domainId, name: domainId, description: '', leadUserId: '', modules: []),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(domain?.name ?? 'Roadmap'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: modulesAsync.when(
        data: (modules) {
          if (modules.isEmpty) {
            return const Center(
              child: Text(
                'No modules configured for this domain yet.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: modules.length,
            itemBuilder: (context, moduleIndex) {
              final module = modules[moduleIndex];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Module header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${moduleIndex + 1}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          module.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Topics in module
                  Consumer(
                    builder: (context, ref, _) {
                      final topicsAsync = ref.watch(topicsProvider(
                        (domainId: domainId, moduleId: module.id),
                      ));

                      return topicsAsync.when(
                        data: (topics) {
                          return Column(
                            children: topics.map((topic) {
                              final progress = progressAsync.valueOrNull;
                              final isCompleted =
                                  progress?.topicsCompleted.containsKey(topic.id) ?? false;

                              // Count total topics across all modules (approximate)
                              final totalTopics =
                                  modules.fold(0, (sum, m) => sum + (m.topics.length));
                              final approxTotal = totalTopics > 0 ? totalTopics : topics.length;

                              return Card(
                                margin: const EdgeInsets.only(left: 16, bottom: 8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _showTopicSheet(
                                      context, ref, topic, isCompleted, domainId, approxTotal,
                                      user?.uid ?? ''),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Completion checkbox
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 250),
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isCompleted
                                                ? AppColors.success
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: isCompleted
                                                  ? AppColors.success
                                                  : AppColors.border,
                                              width: 2,
                                            ),
                                          ),
                                          child: isCompleted
                                              ? const Icon(Icons.check,
                                                  size: 14, color: Colors.white)
                                              : null,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                topic.title,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: isCompleted
                                                      ? AppColors.textMuted
                                                      : AppColors.textPrimary,
                                                  decoration: isCompleted
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                  decorationColor: AppColors.textMuted,
                                                ),
                                              ),
                                              if (topic.resources.isNotEmpty)
                                                Text(
                                                  '${topic.resources.length} resource${topic.resources.length > 1 ? "s" : ""}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textMuted,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppColors.textMuted,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: LinearProgressIndicator(),
                          ),
                        ),
                        error: (e, s) => Text('Error: $e'),
                      );
                    },
                  ),

                  if (moduleIndex < modules.length - 1)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Divider(),
                    ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showTopicSheet(
    BuildContext context,
    WidgetRef ref,
    dynamic topic,
    bool isCompleted,
    String domainId,
    int totalTopics,
    String uid,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                topic.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: isCompleted ? AppColors.success : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCompleted ? 'Completed' : 'Not started',
                    style: TextStyle(
                      color: isCompleted ? AppColors.success : AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),

              // Resources
              if (topic.resources.isNotEmpty) ...[
                Text(
                  'Resources',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...topic.resources.map<Widget>((resource) {
                  final icon = resource.type == 'video'
                      ? Icons.play_circle_outline_rounded
                      : resource.type == 'practice'
                          ? Icons.sports_esports_outlined
                          : resource.type == 'doc'
                              ? Icons.article_outlined
                              : Icons.link_rounded;
                  final color = resource.type == 'video'
                      ? Colors.redAccent
                      : resource.type == 'practice'
                          ? AppColors.accent
                          : resource.type == 'doc'
                              ? AppColors.secondary
                              : AppColors.primary;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resource.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                resource.url,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.open_in_new_rounded,
                            size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 20),
              ],

              // Mark Complete / Undo button
              if (uid.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    final db = ref.read(databaseRepositoryProvider);
                    await db.toggleTopicCompletion(
                      uid,
                      domainId,
                      topic.id,
                      !isCompleted,
                      totalTopics,
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: Icon(
                    isCompleted ? Icons.undo_rounded : Icons.check_circle_outline,
                    size: 20,
                  ),
                  label: Text(isCompleted ? 'Mark Incomplete' : 'Mark as Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted ? AppColors.error : AppColors.success,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
