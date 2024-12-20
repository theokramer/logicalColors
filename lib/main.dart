import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:tone_twister/hints_manager.dart';
import 'package:tone_twister/main_menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'puzzle_model.dart'; // Import your PuzzleModel
import 'puzzle_screen.dart'; // Import your screen
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

FirebaseDatabase database = FirebaseDatabase.instance;

Future<String> loadJsonFromAssets(String filePath) async {
  //print("Trying to load file from path: $filePath"); // Debugging
  String jsonString = await rootBundle.loadString(filePath);
  return jsonString;
}

Future<Level> readLevel(int index) async {
  String fileContent = await loadJsonFromAssets("assets/levels.json");

  // Decoding JSON file content into a Map
  var jsonData = jsonDecode(fileContent);

  // Deserializing into a Level object
  Level level = Level.fromJson(jsonData[index]);
  //Level level = Level();
  // Return the first click from the clicks list, if available
  return level;
}

Future<int> readMoves(int index) async {
  Level level = await readLevel(index - 1);
  return level.clicks?.length ?? 0;
}

Future<int> readSize(int index) async {
  Level level = await readLevel(index - 1);
  return level.size ?? 0;
}

Future<int> returnCorrectSize() async {
  return (await readSize(selectedLevel > 0 ? selectedLevel : 1));
}

Future<int> returnCorrectMoves() async {
  return (await readMoves(selectedLevel > 0 ? selectedLevel : 1));
}

Future<int> countSpecificLevels(int targetWorldNr) async {
  String fileContent = await loadJsonFromAssets("assets/levels.json");

  // Decoding JSON file content into a Map
  var jsonData = jsonDecode(fileContent);

  int count = 0;

  // Looping through the JSON array
  for (var item in jsonData) {
    Level level = Level.fromJson(item);
    if (level.worldNr == targetWorldNr) {
      count++;
    }
  }

  return count;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();

  currentWorld = await maxWorld();

  worlds[0].anzahlLevels = await countSpecificLevels(1);

  int maxLevel = await loadWorldProgress(
      currentWorld); // Load progress for the current world

  (maxLevel > worlds[currentWorld - 1].anzahlLevels
      ? maxLevel = worlds[currentWorld - 1].anzahlLevels
      : null);
  //maxLevel == -2 ? maxLevel = worlds[currentWorld - 1].anzahlLevels : null;
  tutorialActive = await loadTutorial();
  selectedLanguage = await loadSelectedLanguage();
  vibration = await loadVibration();
  animations = await loadAnimations();
  sounds = await loadSounds();
  selectedLevel = maxLevel;
  int savedLanguage = await loadSelectedLanguage();
  runApp(MyApp(
    moves: await returnCorrectMoves(),
    size: await returnCorrectSize(),
    maxLevel: maxLevel,
    savedLanguage: savedLanguage,
  ));
}

Future<int> maxWorld() async {
  int worldMax;
  for (int i = worlds.length; i > 0; i--) {
    worldMax = await loadWorldProgress(i);

    if (worldMax != 0 && worldMax != 1) {
      return i;
    }
  }
  return 1;
}

Future<bool> loadTutorial() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('tutorialActive') ??
      true; // 0 ist der Standardwert, wenn nichts gespeichert wurde
}

Future<String> loadUserID() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userID') ?? "";
}

Future<void> saveUserID(String userID) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('userID', userID);
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

  final int moves;
  final int size;

  final int savedLanguage; // The saved language passed from main()

  const MyApp(
      {super.key,
      required this.maxLevel,
      required this.savedLanguage,
      required this.moves,
      required this.size});

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
            size: size,
            level: moves,
            colorMapping: {
              1: worlds[currentWorld - 1].colors[0],
              2: worlds[currentWorld - 1].colors[1],
              3: worlds[currentWorld - 1].colors[2],
            },
          ),
        ),
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
          initialRoute: tutorialActive ? '/tutorial' : '/',
          routes: {
            '/': (context) => const MainMenuScreen(),
            '/tutorial': (context) => const PuzzleScreen(),
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
