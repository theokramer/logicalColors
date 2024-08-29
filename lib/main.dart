import 'package:color_puzzle/coin_manager.dart';
import 'package:color_puzzle/roadmap_screen.dart';
import 'package:color_puzzle/shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'puzzle_model.dart'; // Import your PuzzleModel
import 'puzzle_screen.dart'; // Import your screen

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Initialisierung sicherstellen
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PuzzleModel(
            size: 1,
            level: 1,
            colorMapping: {
              1: worlds[currentWorld - 1].colors[0],
              2: worlds[currentWorld - 1].colors[1],
              3: worlds[currentWorld - 1].colors[2],
            },
          ), // Initial Coins setzen
        ),
        ChangeNotifierProvider(create: (_) => CoinProvider()),
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
