import 'package:color_puzzle/congratulations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'puzzle_model.dart';

class PuzzleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final puzzle = Provider.of<PuzzleModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Color Change Puzzle'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Moves: ${puzzle.moves} / ${puzzle.maxMoves}',
                    style: TextStyle(fontSize: 20)),
                GestureDetector(
                  child: Text("Reset"),
                  onTap: () {
                    puzzle.grid = puzzle.savedGrid.map((row) => List<int>.from(row)).toList(); // Deep copy grid
                    puzzle.resetMoves();
                    puzzle.moveWhereError = -1;
                    puzzle.clicks = puzzle.savedClicks.map((click) => List<int>.from(click)).toList(); // Deep copy clicks

                    print(puzzle.clicks);
                    print(puzzle.savedClicks);
                  },
                ),
                Container(
                  width: 50,
                  height: 50,
                  color: puzzle.targetColor,
                  child: Center(
                    child: Text(
                      'Target',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    bool resetOccurred = puzzle.getHint();
                    if (resetOccurred) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("You made a mistake and have been reset to the last correct state."),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      // Add a short delay to allow visual feedback
                      Future.delayed(Duration(milliseconds: 500), () {
                        puzzle.clearHint();
                      });
                    }
                  },
                  child: Text('Hint'),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: puzzle.size,
              ),
              itemCount: puzzle.size * puzzle.size,
              itemBuilder: (context, index) {
                int x = index ~/ puzzle.size;
                int y = index % puzzle.size;
                int colorNumber = puzzle.grid[x][y];
                Color tileColor = puzzle.getColor(colorNumber);
                bool isHintTile = (x == puzzle.hintX && y == puzzle.hintY);

                return GestureDetector(
                  onTap: () {
                    puzzle.clickTile(x, y, false);
                    // Check if the puzzle is completed after a move
                    if (puzzle.isGridFilledWithTargetColor()) {
                      // Navigate to the Congratulations screen
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => CongratulationsScreen(),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: tileColor,
                      border: isHintTile
                          ? Border.all(color: Colors.yellow, width: 3)
                          : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        colorNumber.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
