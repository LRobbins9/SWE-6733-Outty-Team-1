import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
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
      // Start listening to messages for all matches
      final matches = context.read<MatchProvider>().matches;
      final chatProvider = context.read<ChatProvider>();
      for (final match in matches) {
        chatProvider.listenToMessages(match.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final matches = context.watch<MatchProvider>().matches;
    final chatProvider = context.watch<ChatProvider>();
    final navNotifier = context.watch<NavigationNotifier>();
    final currentIndex = navNotifier.currentIndex;

    // Check for unread messages: messages from other users that current user hasn't read
    final hasUnreadMessages = matches.any((match) {
      final messages = chatProvider.getMessages(match.id);
      // If there's not even a seeded message for this match, then noone has viewed it yet
      // In this case, we consider it as having unread messages.
      if (messages.isEmpty) return true;
      return messages.any((msg) => 
          msg.senderId != currentUser?.id && 
          msg.isRead == false);
    });
    

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

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
            icon: Icon(Icons.terrain_outlined),
            activeIcon: Icon(Icons.terrain),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: hasUnreadMessages,
              child: const Icon(Icons.favorite_border),
            ),
            activeIcon: Badge(
              isLabelVisible: hasUnreadMessages,
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
