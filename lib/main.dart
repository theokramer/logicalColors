import 'package:color_puzzle/roadmap_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'puzzle_model.dart'; // Make sure to import your model
import 'puzzle_screen.dart'; // Make sure to import your screen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PuzzleModel(size: 1, level: 68)),
      ],
      child: MaterialApp(
        title: 'Color Change Puzzle',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/puzzle',
        routes: {
        '/puzzle': (context) => PuzzleScreen(),
        '/roadmap': (context) => RoadMapScreen(),
      },
      ),
    );
  }
}
