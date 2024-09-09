import 'package:color_puzzle/puzzle_model.dart';
import 'package:color_puzzle/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Assuming PuzzleModel and other dependencies are already defined.

class LevelSelectionScreen extends StatelessWidget {
  final int worldIndex;
  final int currentLevel;

  const LevelSelectionScreen({
    super.key,
    required this.worldIndex,
    required this.currentLevel,
  });

  @override
  Widget build(BuildContext context) {
    final puzzle = Provider.of<PuzzleModel>(context);
    int worldStartLevel = (worldIndex - 1) * 75 + 1;
    int worldEndLevel = worldIndex * 75;
    int totalLevels = worldEndLevel - worldStartLevel + 1;

    // Calculate rows needed based on 3 items per row
    int rows = (totalLevels / 3).ceil();

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text(
          'World $worldIndex',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: worlds[worldIndex - 1].colors[1],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CustomPaint(
              // Wrap the Column with CustomPaint to draw lines.
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(rows, (rowIndex) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (colIndex) {
                        int levelNumber = rowIndex * 3 + colIndex + 1;

                        if (levelNumber > totalLevels) return Container();

                        bool isLevelUnlocked =
                            levelNumber <= currentLevel || levelNumber == 1;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _buildLevelButton(
                            context,
                            levelNumber: levelNumber,
                            isLevelUnlocked: isLevelUnlocked,
                            puzzle: puzzle,
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelButton(BuildContext context,
      {required int levelNumber,
      required bool isLevelUnlocked,
      required PuzzleModel puzzle}) {
    return GestureDetector(
      onTap: isLevelUnlocked
          ? () {
              selectedLevel = levelNumber;
              Navigator.of(context).pushReplacement(
                FadePageRoute(
                  page: ChangeNotifierProvider(
                    create: (_) => PuzzleModel(
                      size: puzzle.getSizeAndMaxMoves(levelNumber)["size"] ?? 2,
                      level:
                          puzzle.getSizeAndMaxMoves(levelNumber)["maxMoves"] ??
                              2,
                      colorMapping: {
                        1: worlds[currentWorld - 1].colors[0],
                        2: worlds[currentWorld - 1].colors[1],
                        3: worlds[currentWorld - 1].colors[2],
                      },
                    ),
                    child: const PuzzleScreen(),
                  ),
                ),
              );
            }
          : null,
      child: CircleAvatar(
        radius: 40,
        backgroundColor: isLevelUnlocked
            ? (levelNumber == currentLevel
                ? Colors.green
                : worlds[worldIndex - 1].colors[1])
            : Colors.grey,
        child: Center(
          child: Text(
            '$levelNumber',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
