import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../providers/navigation_notifier.dart';
import '../utils/constants.dart';
import 'discover_screen.dart';
import 'matches_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  static const _pages = [
    DiscoverScreen(),
    MatchesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      await context.read<MatchProvider>().load(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchCount = context.watch<MatchProvider>().matches.length;
    final navNotifier = context.watch<NavigationNotifier>();
    final currentIndex = navNotifier.currentIndex;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => context.read<NavigationNotifier>().switchToIndex(i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Colors.white,
        elevation: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: matchCount > 0,
              label: Text('$matchCount'),
              child: const Icon(Icons.favorite_border),
            ),
            activeIcon: Badge(
              isLabelVisible: matchCount > 0,
              label: Text('$matchCount'),
              child: const Icon(Icons.favorite),
            ),
            label: 'Matches',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
