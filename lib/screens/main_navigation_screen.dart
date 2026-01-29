import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'home/home_screen.dart';
import 'chats_screen.dart';
import 'applied_colleges_screen.dart';
import 'wishlist_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final Function(Locale)? onLocaleChanged;
  
  const MainNavigationScreen({super.key, this.onLocaleChanged});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  final List<Widget> _screens = [];
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _chatsKey = GlobalKey();
  final GlobalKey _appliedKey = GlobalKey();
  final GlobalKey _wishlistKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    _screens.addAll([
      HomeScreen(
        key: _homeKey,
        onLocaleChanged: widget.onLocaleChanged,
      ),
      ChatsScreen(key: _chatsKey),
      AppliedCollegesScreen(key: _appliedKey),
      WishlistScreen(key: _wishlistKey),
      ProfileScreen(
        key: _profileKey,
        onLocaleChanged: widget.onLocaleChanged,
      ),
    ]);
  }

  void _onTabChanged(int index) {
    // Always update the index when tab is tapped
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
    
    // Reload data when switching to a different tab
    if (index != _previousIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reloadScreenData(index);
      });
    }
  }

  void _reloadScreenData(int index) {
    switch (index) {
      case 0: // Home
        final homeState = _homeKey.currentState;
        if (homeState != null) {
          (homeState as dynamic).reloadData?.call();
        }
        break;
      case 1: // Chats
        // Chats screen uses StreamBuilder, so it auto-updates
        break;
      case 2: // Applied
        final appliedState = _appliedKey.currentState;
        if (appliedState != null) {
          (appliedState as dynamic).refreshApplications?.call();
        }
        break;
      case 3: // Wishlist
        final wishlistState = _wishlistKey.currentState;
        if (wishlistState != null) {
          (wishlistState as dynamic).refreshWishlist?.call();
        }
        break;
      case 4: // Profile
        final profileState = _profileKey.currentState;
        if (profileState != null) {
          (profileState as dynamic).reloadData?.call();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 89, // Adjust this value to change the height (default is ~56)
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabChanged,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.accentCyan,
          unselectedItemColor: Colors.grey[600],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: localizations?.translate('home') ?? 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            activeIcon: const Icon(Icons.chat_bubble),
            label: localizations?.translate('chats') ?? 'Chats',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.school_outlined),
            activeIcon: const Icon(Icons.school),
            label: localizations?.translate('applied_colleges') ?? 'Applied',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_border),
            activeIcon: const Icon(Icons.favorite),
            label: localizations?.translate('wishlist') ?? 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: localizations?.translate('profile') ?? 'Profile',
          ),
        ],
        ),
      ),
    );
  }
}

