import 'dart:math';

import 'package:color_puzzle/coin_manager.dart';
import 'package:color_puzzle/hints_manager.dart';
import 'package:color_puzzle/roadmap_screen.dart';
import 'package:color_puzzle/shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'puzzle_model.dart'; // Import your PuzzleModel
import 'puzzle_screen.dart'; // Import your screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Initialisierung sicherstellen
  int maxLevel = await loadWorldProgress(currentWorld);
  runApp(MyApp(maxLevel: maxLevel,));
}

// Diese Funktion lädt den Fortschritt der Welten vor dem Start der App.
  Future<int> loadWorldProgress(int worldId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('world_$worldId') ?? 1; // 0 ist der Standardwert, wenn nichts gespeichert wurde
}

class MyApp extends StatelessWidget {
int maxLevel = 1;
MyApp({super.key, 
required this.maxLevel

});

  Map<String, int> getSizeAndMaxMoves(int level) {
    int s = currentWorld == 1 ? 1 : 2; // Grid-Size
    int m = 1; // MaxMoves
    int startLevel = 1; // Startlevel für die aktuelle Grid-Size

    if (currentWorld == 1 && level < 13) {
      switch (level) {
        case 1:
          s = 1; m = 1;
          break;
        case 2:
        case 3:
          s = 2; m = 1;
          break;
        case 4:
        case 5:
        case 6:
          s = 2; m = 2;
          break;
        case 7:
        case 8:
          s = 2; m = 3;
          break;
        case 9:
          s = 3; m = 1;
          break;
        case 10:
          s = 3; m = 2;
          break;
        case 11:
          s = 3; m = 3;
          break;
        case 12:
          s = 3; m = 4;
          break;
        default:
          s = 2; m = 3;
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
            level: maxLevel,
            colorMapping: {
              1: worlds[currentWorld - 1].colors[0],
              2: worlds[currentWorld - 1].colors[1],
              3: worlds[currentWorld - 1].colors[2],
            },
          ), // Initial Coins setzen
        ),
        ChangeNotifierProvider(create: (_) => CoinProvider()),
        ChangeNotifierProvider(create: (_) => HintsProvider()),
        ChangeNotifierProvider(create: (_) => RemsProvider()),
      ],
      child: MaterialApp(
        title: 'Color Change Puzzle',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => PuzzleScreen(),
          '/roadmap': (context) => RoadMapScreen(),
          '/shop': (context) => ShopScreen(),
        },
      ),
    );
  }
}

