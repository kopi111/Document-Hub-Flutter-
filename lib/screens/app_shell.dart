import 'package:flutter/material.dart';

import '../services/news/in_memory_news_repository.dart';
import '../services/news/news_repository.dart';
import 'home_screen.dart';
import 'more_screen.dart';
import 'news/news_feed_screen.dart';
import 'westops/missing_list_screen.dart';
import 'westops/wanted_list_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final NewsRepository _newsRepository = InMemoryNewsRepository();
  int _selectedIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const HomeScreen(),
      NewsFeedScreen(repository: _newsRepository),
      const WantedListScreen(),
      const MissingListScreen(),
      const MoreScreen(),
    ];
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Documents',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'News',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_search_outlined),
            selectedIcon: Icon(Icons.person_search),
            label: 'Wanted',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help),
            label: 'Missing',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
