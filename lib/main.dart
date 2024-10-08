import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:color_puzzle/coin_manager.dart';
import 'package:color_puzzle/hints_manager.dart';
import 'package:color_puzzle/main_menu_screen.dart';
import 'package:color_puzzle/shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'puzzle_model.dart'; // Import your PuzzleModel
import 'puzzle_screen.dart'; // Import your screen
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();

  int maxLevel = await loadWorldProgress(
      currentWorld); // Load progress for the current world
  tutorialActive = await loadTutorial();
  selectedLanguage = await loadSelectedLanguage();
  vibration = await loadVibration();
  animations = await loadAnimations();
  sounds = await loadSounds();
  selectedLevel = maxLevel;
  int savedLanguage = await loadSelectedLanguage();
  runApp(MyApp(
    maxLevel: maxLevel,
    savedLanguage: savedLanguage,
  ));
}

int maxWorld() {
  for (int i = worlds.length; i > 0; i--) {}
  return 0;
}

Future<bool> loadTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('tutorialActive') ??
      true; // 0 ist der Standardwert, wenn nichts gespeichert wurde
}

// Load the progress of the specific world
Future<int> loadWorldProgress(int worldId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('world_$worldId') ?? 1;
}

// Save the progress of the specific world
Future<void> saveWorldProgress(int worldId, int maxLevel) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('world_$worldId', maxLevel);
}

Future<int> loadSelectedLanguage() async {
  final String defaultLocale = Platform.localeName;
  final prefs = await SharedPreferences.getInstance();

  var intLanguage = prefs.getInt('selectedLanguage') ?? -1;
  if (intLanguage == -1) {
    switch (defaultLocale) {
      case "en_DE":
        return 0;
      case "de_DE":
        return 1;
      case "es_DE":
        return 2;
      default:
        return 0;
    }
  }

  return intLanguage;
}

Future<bool> loadVibration() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('vibration') ?? true;
}

Future<bool> loadAnimations() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('animations') ?? true;
}

Future<bool> loadSounds() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('sounds') ?? true;
}

class MyApp extends StatelessWidget {
  final int maxLevel;

  final int savedLanguage; // The saved language passed from main()

  const MyApp({super.key, required this.maxLevel, required this.savedLanguage});

  Map<String, int> getSizeAndMaxMoves(int level) {
    int s = currentWorld == 1 ? 1 : 2;
    int m = 1;
    int startLevel = 1;

    if (currentWorld == 1 && level < 13) {
      switch (level) {
        case 1:
          s = 1;
          m = 1;
          break;
        case 2:
        case 3:
          s = 2;
          m = 1;
          break;
        case 4:
        case 5:
        case 6:
          s = 2;
          m = 2;
          break;
        case 7:
        case 8:
          s = 2;
          m = 3;
          break;
        case 9:
          s = 3;
          m = 1;
          break;
        case 10:
          s = 3;
          m = 2;
          break;
        case 11:
          s = 3;
          m = 3;
          break;
        case 12:
          s = 3;
          m = 4;
          break;
        default:
          s = 2;
          m = 3;
          break;
      }
      return {"size": s, "maxMoves": m};
    }

    while (level < 50) {
      if (currentWorld == 1) {
        int levelsForCurrentSize = ((s) * (s)).floor();
        int endLevel = startLevel + levelsForCurrentSize - 1;

        if (level <= endLevel) {
          m = (1 + (log(level - startLevel + 1) / log(1.9))).ceil();
          int maxMovesForCurrentSize = (s * 1.8).floor();
          m = m > maxMovesForCurrentSize ? maxMovesForCurrentSize : m;
          break;
        }

        s++;
        startLevel = endLevel + 1;
      } else {
        int levelsForCurrentSize = ((s + 0.6) * (s + 0.6)).floor();
        int endLevel = startLevel + levelsForCurrentSize - 1;

        if (level <= endLevel) {
          m = (1 + (log(level - startLevel + 1) / log(2.07))).floor();
          int maxMovesForCurrentSize = (s * 5).floor();
          m = m > maxMovesForCurrentSize ? maxMovesForCurrentSize : m;
          break;
        }

        s++;
        startLevel = endLevel + 1;
      }
    }

    if (level >= 50) {
      s = 5;
      m = currentWorld == 1 ? 7 : 6;
      int tempLvl = level - 1;
      int set = 0;
      while (tempLvl > 50) {
        if (set == 2 || tempLvl >= 65) {
          set = 0;
          if (s > m - 5 && s > 4) {
            s = s - 1;
          } else {
            s = 5;
            m += 1;
          }
        } else {
          set += 1;
        }
        tempLvl -= 1;
      }
    }

    return {"size": s, "maxMoves": m};
  }

  Locale currentLocale() {
    final String defaultLocale = Platform.localeName;
    if (selectedLanguage == -1) {
      return Locale(defaultLocale);
    } else {
      return Locale(locales[selectedLanguage]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PuzzleModel(
            size: getSizeAndMaxMoves(maxLevel)["size"] ?? 2,
            level: getSizeAndMaxMoves(selectedLevel)["maxMoves"] ?? 2,
            colorMapping: {
              1: worlds[currentWorld - 1].colors[0],
              2: worlds[currentWorld - 1].colors[1],
              3: worlds[currentWorld - 1].colors[2],
            },
          ),
        ),
        ChangeNotifierProvider(create: (_) => CoinProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider(savedLanguage)),
        ChangeNotifierProvider(create: (_) => HintsProvider()),
        ChangeNotifierProvider(create: (_) => RemsProvider()),
      ],
      child: Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          supportedLocales: const [
            Locale('en', ''), // Englisch
            Locale('de', ''), // Deutsch
            Locale('es', ''), // Spanisch
          ],
          locale: languageProvider.locale,
          // Lokalisierungsdelegaten konfigurieren
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          title: "Logical Colors",
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          initialRoute: tutorialActive ? '/' : '/menu',
          routes: {
            '/': (context) => const PuzzleScreen(),
            '/roadmap': (context) => const MainMenuScreen(),
            '/shop': (context) {
              // Access PuzzleModel using Provider
              final puzzle = Provider.of<PuzzleModel>(context, listen: false);

              // Pass PuzzleModel to ShopScreen
              return ShopScreen(puzzle: puzzle);
            },
            '/menu': (context) => const MainMenuScreen(),
          },
        );
      }),
    );
  }
}

class LanguageProvider with ChangeNotifier {
  Locale _locale;

  // Constructor that sets the initial locale from the saved language
  LanguageProvider(int savedLanguage)
      : _locale = Locale(locales[savedLanguage]);

  Locale get locale => _locale;

  // Update the locale and notify listeners
  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void clearLocale() {
    _locale = const Locale('en');
    notifyListeners();
  }
}
