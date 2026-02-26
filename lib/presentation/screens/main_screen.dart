import 'package:flutter/material.dart';
import 'library/library_screen.dart';
import 'streaming/streaming_screen.dart';
import 'playlists/playlists_screen.dart';
import 'settings/settings_screen.dart';
import '../widgets/mini_player.dart';

/// Main screen with bottom navigation bar and mini player.
/// 
/// This is the primary entry point of the app UI. It provides:
/// - Bottom navigation with 4 tabs: Library, Streaming, Playlists, Settings
/// - Tab selection and screen switching
/// - Mini player positioned above the bottom navigation bar
/// 
/// Requirements: 1.1, 1.2, 1.3
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // List of screens corresponding to each tab
  static const List<Widget> _screens = [
    LibraryScreen(),
    StreamingScreen(),
    PlaylistsScreen(),
    SettingsScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini player positioned above bottom navigation
          const MiniPlayer(),
          // Bottom navigation bar
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onTabSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.library_music),
                label: 'Bibliothèque',
              ),
              NavigationDestination(
                icon: Icon(Icons.radio),
                label: 'Streaming',
              ),
              NavigationDestination(
                icon: Icon(Icons.playlist_play),
                label: 'Playlists',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings),
                label: 'Paramètres',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
