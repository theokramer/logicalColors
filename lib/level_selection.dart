// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tone_twister/puzzle_model.dart';
import 'package:tone_twister/puzzle_screen.dart';

// Assuming PuzzleModel and other dependencies are already defined.

class LevelSelectionScreen extends StatefulWidget {
  final int worldIndex;
  final int currentLevel;
  final Function(int) onLevelSelected;

  const LevelSelectionScreen({
    super.key,
    required this.worldIndex,
    required this.currentLevel,
    required this.onLevelSelected,
  });

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final puzzle = Provider.of<PuzzleModel>(context);
    int worldStartLevel =
        (widget.worldIndex - 1) * worlds[widget.worldIndex - 1].anzahlLevels +
            1;
    int worldEndLevel =
        widget.worldIndex * worlds[widget.worldIndex - 1].anzahlLevels;
    int totalLevels = worldEndLevel - worldStartLevel + 1;

    // Calculate rows needed based on 4 items per row
    int rows = (totalLevels / 4).ceil();

    return Container(
      padding: const EdgeInsets.all(16.0),
      height: MediaQuery.of(context).size.height * 0.55 +
          100, // Limit height to 50% of the screen
      child: Column(
        children: [
          // A small "bar" to close the modal view
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Level Auswahl',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop(); // Closes the modal view
                },
              ),
            ],
          ),
          const Divider(), // Separator line
          Expanded(
            child: ListView(
              children: List.generate(rows, (rowIndex) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (colIndex) {
                      int levelNumber = rowIndex * 4 + colIndex + 1;

                      if (levelNumber > totalLevels) return Container();

                      bool isLevelUnlocked =
                          levelNumber <= widget.currentLevel ||
                              levelNumber == 1 ||
                              widget.currentLevel == -2;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: GestureDetector(
                          onTap: isLevelUnlocked
                              ? () {
                                  selectedLevel = levelNumber;
                                  Navigator.of(context).pop();
                                  widget.onLevelSelected(levelNumber);
                                }
                              : null,
                          child: _buildLevelButton(
                            context,
                            levelNumber: levelNumber,
                            isLevelUnlocked: isLevelUnlocked,
                            puzzle: puzzle,
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelButton(BuildContext context,
      {required int levelNumber,
      required bool isLevelUnlocked,
      required PuzzleModel puzzle}) {
    return GestureDetector(
      child: CircleAvatar(
        radius: 35,
        backgroundColor: isLevelUnlocked
            ? (levelNumber == widget.currentLevel &&
                    levelNumber != worlds[currentWorld - 1].anzahlLevels
                ? Colors.green.shade600
                : worlds[widget.worldIndex - 1].colors[1])
            : Colors.grey,
        child: Center(
          child: Text(
            '$levelNumber',
            style: TextStyle(
              color: primaryColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
