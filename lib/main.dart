import 'dart:async';
import 'dart:math';

import 'package:color_puzzle/coin_manager.dart';
import 'package:color_puzzle/hints_manager.dart';
import 'package:color_puzzle/main_menu_screen.dart';
import 'package:color_puzzle/shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'puzzle_model.dart'; // Import your PuzzleModel
import 'puzzle_screen.dart'; // Import your screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  int maxLevel = await loadWorldProgress(
      currentWorld); // Load progress for the current world
  tutorialActive = await loadTutorial();
  selectedLevel = maxLevel;
  runApp(MyApp(maxLevel: maxLevel));
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

class MyApp extends StatelessWidget {
  final int maxLevel;

  const MyApp({super.key, required this.maxLevel});

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
        ChangeNotifierProvider(create: (_) => HintsProvider()),
        ChangeNotifierProvider(create: (_) => RemsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Color Change Puzzle',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: tutorialActive ? '/' : '/menu',
        routes: {
          '/': (context) => const PuzzleScreen(),
          '/roadmap': (context) => const MainMenuScreen(),
          '/shop': (context) => const ShopScreen(),
          '/menu': (context) => const MainMenuScreen(),
        },
      ),
    );
  }
}
