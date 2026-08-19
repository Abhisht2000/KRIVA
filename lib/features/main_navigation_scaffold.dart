import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../services/service_providers.dart';
import '../models/user_model.dart';
import 'dashboard/dashboard_screen.dart';
import 'roadmap/roadmap_list_screen.dart';
import 'profile/profile_screen.dart';
import 'admin/admin_dashboard_screen.dart';

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

    final bool showAdminTab = user.role == UserRole.admin || user.role == UserRole.lead;

    // Define tabs
    final List<Widget> screens = [
      const DashboardScreen(),
      const RoadmapListScreen(),
      const ProfileScreen(),
      if (showAdminTab) const AdminDashboardScreen(),
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
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
      if (showAdminTab)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_outlined),
          activeIcon: Icon(Icons.admin_panel_settings_rounded),
          label: 'Admin',
        ),
    ];

    // Handle index out of bounds when switching roles
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
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: navItems,
        ),
      ),
    );
  }
}
