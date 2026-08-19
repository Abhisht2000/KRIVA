import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../services/service_providers.dart';
import 'dashboard/dashboard_screen.dart';
import 'roadmap/roadmap_list_screen.dart';
import 'collaboration/collaboration_screen.dart';
import 'community/community_screen.dart';
import 'profile/profile_screen.dart';

// Provider to manage active navigation tab globally
final navigationTabProvider = StateProvider<int>((ref) => 0);

class MainNavigationScaffold extends ConsumerWidget {
  const MainNavigationScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final currentIndex = ref.watch(navigationTabProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Modern 5-tab Bottom Navigation (Dashboard, Roadmaps, Collab, Community, Profile)
    final List<Widget> screens = [
      const DashboardScreen(),
      const RoadmapListScreen(),
      const CollaborationScreen(),
      const CommunityScreen(),
      const ProfileScreen(),
    ];

    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard_rounded),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.map_outlined),
        activeIcon: Icon(Icons.map_rounded),
        label: 'Roadmaps',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.hub_outlined),
        activeIcon: Icon(Icons.hub_rounded),
        label: 'Collab',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.people_outline_rounded),
        activeIcon: Icon(Icons.people_alt_rounded),
        label: 'Community',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];

    // Handle index out of bounds safely
    int activeIndex = currentIndex;
    if (activeIndex >= screens.length) {
      activeIndex = screens.length - 1;
    }

    return Scaffold(
      body: IndexedStack(
        index: activeIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: activeIndex,
          onTap: (index) {
            ref.read(navigationTabProvider.notifier).state = index;
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.background.withValues(alpha: 0.95),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: navItems,
        ),
      ),
    );
  }
}
