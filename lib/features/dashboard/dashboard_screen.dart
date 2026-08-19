import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../services/service_providers.dart';
import '../../services/auth/mock_auth_repository.dart';
import '../main_navigation_scaffold.dart';
import '../../models/user_model.dart';
import '../../models/broadcast_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showStreakInfo(BuildContext context, WidgetRef ref, UserModel user) {
    final useMock = ref.read(useMockModeProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.local_fire_department_rounded, color: AppColors.accent, size: 28),
            const SizedBox(width: 8),
            Text(
              'Streak Board',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your current streak is ${user.streak.count} days!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Keep logging activity (completing topics, sending broadcasts, reading announcements) daily to build up your streak. Missing a day resets the counter!',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            if (useMock) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  final authRepo = ref.read(authRepositoryProvider);
                  if (authRepo is MockAuthRepository) {
                    authRepo.updateStreak(1);
                  }
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Streak checked in successfully (+1 Day)!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Simulate Daily Activity'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBroadcastDetails(BuildContext context, WidgetRef ref, BroadcastModel bc, String uid) {
    // Mark as read immediately
    ref.read(databaseRepositoryProvider).markBroadcastAsRead(uid, bc.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bc.audienceType.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, hh:mm a').format(bc.sentAt),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              bc.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 6),
            Text(
              'Sent by: ${bc.sentBy}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
            ),
            const Divider(height: 24),
            Text(
              bc.body,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Acknowledge'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final broadcastsAsync = ref.watch(broadcastsProvider);
    final domainsAsync = ref.watch(domainsProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Hot reload provider streams
            ref.invalidate(broadcastsProvider);
            ref.invalidate(domainsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Header Profile & Streak Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.surfaceLight,
                        backgroundImage: user.photoUrl.isNotEmpty
                            ? NetworkImage(user.photoUrl)
                            : null,
                        child: user.photoUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      // Welcome info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${user.name}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              user.batch,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Streak Flame button
                      GestureDetector(
                        onTap: () => _showStreakInfo(context, ref, user),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: user.streak.count > 0 
                                ? AppColors.accent.withOpacity(0.12)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: user.streak.count > 0 
                                  ? AppColors.accent.withOpacity(0.3)
                                  : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                color: user.streak.count > 0 ? AppColors.accent : AppColors.textMuted,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${user.streak.count}d',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: user.streak.count > 0 ? AppColors.accent : AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Announcements Headline
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign_outlined, color: AppColors.primary, size: 22),
                      const SizedBox(width: 6),
                      Text(
                        'Recent Broadcasts',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Broadcasts List / Card Carousel
              SliverToBoxAdapter(
                child: broadcastsAsync.when(
                  data: (broadcasts) {
                    if (broadcasts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Center(
                            child: Text(
                              'No recent broadcasts for your feed.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      );
                    }

                    // Render top 3 broadcasts
                    final topBroadcasts = broadcasts.take(3).toList();
                    return SizedBox(
                      height: 125,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: topBroadcasts.length,
                        itemBuilder: (context, idx) {
                          final bc = topBroadcasts[idx];
                          final isUnread = !bc.readBy.contains(user.uid);
                          
                          return GestureDetector(
                            onTap: () => _showBroadcastDetails(context, ref, bc, user.uid),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.8,
                              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isUnread 
                                      ? AppColors.primary.withOpacity(0.5) 
                                      : AppColors.border,
                                  width: isUnread ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          bc.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (isUnread) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Text(
                                      bc.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'By ${bc.sentBy}',
                                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                      ),
                                      Text(
                                        DateFormat('dd MMM').format(bc.sentAt),
                                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 110,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, s) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Error: $e'),
                  ),
                ),
              ),

              // 4. Learning Roadmaps progress header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.school_outlined, color: AppColors.secondary, size: 22),
                      const SizedBox(width: 6),
                      Text(
                        'Your Domain Progress',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Followed Domains List
              domainsAsync.when(
                data: (domains) {
                  final followed = domains
                      .where((d) => user.domainsFollowing.contains(d.id))
                      .toList();

                  if (followed.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Icon(Icons.explore_outlined, color: AppColors.textSecondary, size: 40),
                              const SizedBox(height: 12),
                              Text(
                                'You are not following any technical domains.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  ref.read(navigationTabProvider.notifier).state = 1;
                                },
                                child: const Text('Explore Roadmap Paths'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final domain = followed[index];
                        
                        return Consumer(
                          builder: (context, ref, child) {
                            final progressAsync = ref.watch(userProgressProvider(domain.id));
                            
                            return progressAsync.when(
                              data: (progress) {
                                final percent = progress?.percentComplete ?? 0.0;
                                final completedCount = progress?.topicsCompleted.length ?? 0;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                  child: Card(
                                    margin: EdgeInsets.zero,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        context.push('/roadmap/${domain.id}');
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    domain.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '${(percent * 100).toInt()}%',
                                                  style: const TextStyle(
                                                    color: AppColors.secondary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$completedCount tasks completed',
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: percent,
                                                minHeight: 8,
                                                color: AppColors.secondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                child: Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Center(child: LinearProgressIndicator()),
                                  ),
                                ),
                              ),
                              error: (e, s) => Text('Error loading progress: $e'),
                            );
                          },
                        );
                      },
                      childCount: followed.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, s) => SliverToBoxAdapter(child: Text('Error: $e')),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
