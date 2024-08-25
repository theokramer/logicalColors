import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'puzzle_model.dart';
import 'puzzle_screen.dart';

class CongratulationsScreen extends StatefulWidget {
  @override
  _CongratulationsScreenState createState() => _CongratulationsScreenState();
}

class _CongratulationsScreenState extends State<CongratulationsScreen> {
  int _selectedGridSize = 4; // Default grid size

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Congratulations!'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'You Did It!',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Congratulations on completing the puzzle!',
              style: TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            Text(
              'Select the next grid size:',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            DropdownButton<int>(
              value: _selectedGridSize,
              items: [3, 4, 5, 6].map((size) {
                return DropdownMenuItem<int>(
                  value: size,
                  child: Text('$size x $size'),
                );
              }).toList(),
              onChanged: (newSize) {
                setState(() {
                  _selectedGridSize = newSize!;
                });
              },
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Start a new game with the selected grid size
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider(
                      create: (_) => PuzzleModel(size: _selectedGridSize),
                      child: PuzzleScreen(),
                    ),
                  ),
                );
              },
              child: Text('Start Next Game'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Go back to the home screen (or exit)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
