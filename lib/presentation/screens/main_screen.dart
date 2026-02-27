import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scanner_provider.dart';
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
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Request permissions after launch to ensure functionality is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestInitialPermissions();
    });
  }

  Future<void> _requestInitialPermissions() async {
    final scannerService = ref.read(libraryScannerServiceProvider);
    await scannerService.requestPermissions();
  }

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
      bottomNavigationBar: Material(
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayer(),
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
        ),
      ),
    );
  }
}
