import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'services/locale_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _loadLocale();
    // Set the locale change callback so HomeScreen can use it
    LocaleService.setLocaleChangeCallback(_changeLocale);
  }

  Future<void> _loadLocale() async {
    final savedLocale = await LocaleService.getSavedLocale();
    if (savedLocale != null) {
      setState(() {
        _locale = savedLocale;
      });
    }
  }

  void _changeLocale(Locale locale) {
    if (_locale.languageCode != locale.languageCode) {
      setState(() {
        _locale = locale;
      });
      // Save locale without triggering callback (to avoid infinite loop)
      LocaleService.saveLocaleWithoutCallback(locale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: ValueKey(_locale.languageCode), // Force rebuild when locale changes
      title: 'EKTIFI',
      theme: AppTheme.getLightTheme(locale: _locale.languageCode),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: _locale.languageCode == 'ar' 
              ? TextDirection.rtl 
              : TextDirection.ltr,
          child: child!,
        );
      },
      home: SplashScreen(
        onLocaleChanged: _changeLocale,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
