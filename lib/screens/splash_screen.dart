import 'package:flutter/material.dart';
import '../services/locale_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  final Function(Locale)? onLocaleChanged;
  
  const SplashScreen({super.key, this.onLocaleChanged});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _loadSavedLocale(); // Load locale but don't navigate yet
  }

  Future<void> _loadSavedLocale() async {
    final savedLocale = await LocaleService.getSavedLocale();
    if (savedLocale != null && widget.onLocaleChanged != null) {
      widget.onLocaleChanged!(savedLocale);
    }
  }

  Future<void> _initializeVideo() async {
    try {
      // Make sure the video path is correct
      _videoController = VideoPlayerController.asset('assets/videos/spash_video.mp4');
      
      await _videoController.initialize();
      
      // Set video to fill the entire screen
      _videoController.setLooping(false);
      
      // Listen for video completion
      _videoController.addListener(_videoListener);
      
      // Start playing
      await _videoController.play();
      
      setState(() {
        _isVideoInitialized = true;
      });
      
    } catch (e) {
      print('Error initializing video: $e');
      // If video fails, navigate after short delay
      _navigateToHome();
    }
  }

  void _videoListener() {
    // Check if video has reached the end
    if (_videoController.value.position >= _videoController.value.duration && 
        _videoController.value.duration != Duration.zero) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    
    // Remove listener and dispose controller
    _videoController.removeListener(_videoListener);
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainNavigationScreen(onLocaleChanged: widget.onLocaleChanged),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show video if initialized, otherwise show fallback UI
    if (_isVideoInitialized) {
      return Scaffold(
        backgroundColor: Colors.black, // Black background for video
        body: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController.value.size.width,
              height: _videoController.value.size.height,
              child: VideoPlayer(_videoController),
            ),
          ),
        ),
      );
    } else {
      // Fallback UI while video is loading or if it failed
      return _buildFallbackUI();
    }
  }

  Widget _buildFallbackUI() {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accentCyan.withOpacity(0.1),
              AppTheme.primaryIndigo.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              // Image.asset(
              //   'assets/images/ektifi-logo copy.png',
              //   width: 120,
              //   height: 120,
              //   fit: BoxFit.contain,
              // ),
              // const SizedBox(height: 24),
              // Text(
              //   localizations?.appName ?? 'EKTIFI',
              //   style: const TextStyle(
              //     fontSize: 32,
              //     fontWeight: FontWeight.w600,
              //     letterSpacing: 2,
              //     color: AppTheme.primaryIndigo,
              //   ),
              // ),
              // const SizedBox(height: 8),
              // Text(
              //   localizations?.appTagline ?? 'Education Technology Platform',
              //   style: TextStyle(
              //     fontSize: 14,
              //     color: Colors.grey[600],
              //   ),
              // ),
              // const SizedBox(height: 48),
              // CircularProgressIndicator(
              //   valueColor: AlwaysStoppedAnimation<Color>(
              //     AppTheme.primaryIndigo,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}