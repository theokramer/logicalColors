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
                    puzzle.grid = puzzle.savedGrid;
                    puzzle.resetMoves();
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
                    final hint = puzzle.getHint();
                    if (hint != null) {
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
